import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const MaterialApp(home: TestYOLO()));

class TestYOLO extends StatefulWidget {
  const TestYOLO({super.key});

  @override
  State<TestYOLO> createState() => _TestYOLOState();
}

class _TestYOLOState extends State<TestYOLO> {
  String? _message;

  // Use mlpackage on iOS, tflite on Android
  String get modelPath {
    if (Platform.isIOS) {
      return 'yolo11x'; // CoreML model name (without extension) - must be in bundle
    } else {
      return 'assets/models/yolo11x.tflite'; // TFLite for Android
    }
  }

  // In your initState or build method:
  Future<void> checkAsset() async {
    try {
      if (Platform.isIOS) {
        // For iOS, use CoreML model directly from bundle
        // WORKAROUND: Use multi-instance to avoid the default channel bug in 0.1.39
        final yolo = YOLO(
          modelPath: modelPath,
          task: YOLOTask.detect,
          useGpu: false,
          useMultiInstance: true,
        );
        await yolo.loadModel();
        setState(() => _message = '✅ YOLO CoreML model loaded successfully!');
      } else {
        // For Android, load tflite from assets
        final data = await rootBundle.load(modelPath);
        final f = File(
          '${(await getTemporaryDirectory()).path}/yolo11x.tflite',
        );
        await f.writeAsBytes(data.buffer.asUint8List());

        final yolo = YOLO(
          modelPath: f.path,
          task: YOLOTask.detect,
          useGpu: false,
        );
        await yolo.loadModel();
        setState(() => _message = '✅ YOLO TFLite model loaded successfully!');
      }
    } catch (e) {
      setState(() => _message = '❌ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YOLO Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_message != null) Text(_message!),
            ElevatedButton(
              child: const Text('Test YOLO'),
              onPressed: () async {
                checkAsset();
                // try {
                //   final yolo = YOLO(
                //     modelPath: modelPath,
                //     task: YOLOTask.detect,
                //     useMultiInstance: true,
                //     useGpu: false
                //   );

                //   await yolo.loadModel();
                //   setState(() => _message = '✅ YOLO loaded successfully!');

                //   if (mounted) {
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(content: Text('YOLO plugin working!')),
                //     );
                //   }

                //   var imageData = (await rootBundle.load('assets/images/dog.jpg')).buffer.asUint8List();
                //   var testResult = await yolo.predict(imageData);

                //   setState(() => _message = testResult.toString());
                // } catch (e) {
                //   setState(() => _message = '❌ Error: $e');
                //   if (mounted) {
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       SnackBar(content: Text('Error: $e')),
                //     );
                //   }
                // }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              child: const Text('Go to YOLO Demo'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const YOLODemo()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class YOLODemo extends StatefulWidget {
  const YOLODemo({super.key});

  @override
  State<YOLODemo> createState() => _YOLODemoState();
}

class _YOLODemoState extends State<YOLODemo> {
  // Use mlpackage on iOS, tflite on Android
  String get modelPath {
    if (Platform.isIOS) {
      return 'yolo11x'; // CoreML model name for iOS
    } else {
      return 'yolo11n'; // Default model for Android
    }
  }

  File? selectedImage;
  List<dynamic> results = [];
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YOLO Quick Demo')),
      body: YOLOView(
        modelPath: modelPath,
        useGpu: false,
        task: YOLOTask.detect,
        onResult: (results) {
          // Results are available here for processing
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          if (image == null) return;

          setState(() {
            selectedImage = File(image.path);
            isLoading = true;
          });

          final yolo = YOLO(
            modelPath: modelPath,
            task: YOLOTask.detect,
            useGpu: false,
            useMultiInstance: true,
          );
          await yolo.loadModel();

          final imageBytes = await selectedImage!.readAsBytes();
          final detectionResults = await yolo.predict(imageBytes);

          setState(() {
            results = detectionResults['boxes'] ?? [];
            isLoading = false;
          });
        },
        child: const Icon(Icons.photo),
      ),
    );
  }
}

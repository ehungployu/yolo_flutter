import 'package:flutter/material.dart';
import 'package:ultralytics_yolo/yolo.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:ultralytics_yolo/yolo_view.dart';
import 'dart:typed_data';
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
  // String modelPath = 'yolo11n';
  // String modelPath = 'assets/models/yolo11x';
  // String modelPath = 'assets/models/yolo11x.mlpackage';
  String modelPath = '../assets/models/yolo11x.tflite';


  // In your initState or build method:
  Future<void> checkAsset() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      print('Asset Manifest: $manifestContent');
      
      // Try to load the model file directly
      final data = await rootBundle.load(modelPath);
      print('Model file size: ${data.buffer.lengthInBytes} bytes');

      final f = File('${(await getTemporaryDirectory()).path}/yolo11x.tflite');
      print('run f');
      await f.writeAsBytes(data.buffer.asUint8List());
      print('run writeAsBytes');
      final yolo = YOLO(modelPath: f.path, task: YOLOTask.detect, useGpu: false);
      print('add yolo');
      await yolo.loadModel();
      print('yolo.loadModel');
    } catch (e) {
      print('Error loading asset: $e');
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
  final String modelPath = 'yolo11n';
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
          print('Found ${results.length} objects!');
          for (final result in results) {
            print('${result.className}: ${result.confidence}');
          }
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
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerScreen extends StatefulWidget {
  final Function(List<String>) onScanComplete;

  const ScannerScreen({super.key, required this.onScanComplete});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isScanning = false;
  final Set<String> _scannedCodes = {};
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _controller!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
          _startScanning();
        }
      }
    }
  }

  void _startScanning() {
    if (_controller == null || !_controller!.value.isInitialized || _isScanning) return;

    _isScanning = true;
    _controller!.startImageStream((CameraImage image) {
      _processImage(image);
    });
  }
  
  // Helper to convert CameraImage to InputImage
  InputImage? _inputImageFromCameraImage(CameraImage image) {
    // This part requires platform native code or careful handling of image planes/rotation. 
    // For simplicity in this implementation step, we'll assume a basic conversion or use a library helper if available.
    // However, google_mlkit_commons provided logic is quite verbose. 
    // To keep it simple for now, we will add a TODO or a simplified placeholder 
    // because implementing full rotation logic is complex without a helper class.
    // A common pattern is to just take photos at intervals or use a camera package that supports analysis.
    // But `camera` package streams raw bytes.
    
    // Let's implement a simplified version or rely on a helper utility usually added to projects.
    // For this prototype, I will skip the complex byte conversion and just mark where it goes.
    // Real implementation needs specific rotation/format handling.
    return null; 
  }

  Future<void> _processImage(CameraImage image) async {
    // TODO: Implement InputImage creation from CameraImage
    // For now, we will use a "Snapshot" approach for simplicity in a robust MVP 
    // or implement the full conversion if needed.
    // Actually, taking a picture is often more reliable for OCR than stream on some devices due to focus.
    // But let's try to stick to stream if possible, or fallback to "Take Picture" button.
    
    // Let's switch to a "Take Picture" approach for V1 as it is much more stable than stream processing without complex boilerplate.
  }
  
  Future<void> _scanImage(InputImage inputImage) async {
    try {
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final text = line.text.trim();
          // Filter for 15-char alphanumeric which fits the pattern
          if (RegExp(r'^[A-Z0-9]{15}$').hasMatch(text)) {
            setState(() {
              _scannedCodes.add(text);
            });
          }
        }
      }
    } catch (e) {
      print("Error scanning image: $e");
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final inputImage = InputImage.fromFilePath(image.path);
        await _scanImage(inputImage);
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Codes')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: CameraPreview(_controller!),
          ),
          Expanded(
            flex: 1,
            child: ListView(
              children: _scannedCodes.map((code) => ListTile(
                title: Text(code),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      _scannedCodes.remove(code);
                    });
                  },
                ),
              )).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    // Manual capture trigger
                    try {
                        final image = await _controller!.takePicture();
                        final inputImage = InputImage.fromFilePath(image.path);
                        await _scanImage(inputImage);
                    } catch (e) {
                        print("Error taking picture: $e");
                    }
                  },
                  child: const Text('Scan/Capture'),
                ),
                ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  child: const Text('Gallery'),
                ),
                 ElevatedButton(
                  onPressed: _scannedCodes.isEmpty ? null : () {
                    widget.onScanComplete(_scannedCodes.toList());
                  },
                  child: const Text('Register Batch'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

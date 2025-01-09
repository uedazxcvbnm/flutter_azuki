import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:async';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:image/image.dart' as img; // 画像処理用のパッケージ

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ImagePredictionScreen(),
    );
  }
}

class ImagePredictionScreen extends StatefulWidget {
  @override
  _ImagePredictionScreenState createState() => _ImagePredictionScreenState();
}

class _ImagePredictionScreenState extends State<ImagePredictionScreen> {
  late Interpreter _interpreter;
  File? _selectedImage;
  String _predictionResult = "";

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
    } catch (e) {
      print("Error loading TFLite model: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      // 圧縮が必要なら行う
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        '${file.absolute.path}_compressed.jpg',
        quality: 85,
      );

      setState(() {
        _selectedImage = compressedFile as File? ?? file;
      });

      _runModel();
    }

  }

  Future<void> _runModel() async {
    if (_selectedImage == null || _interpreter == null) {
      return;
    }

    // 画像をロードしてTensorに変換
    Uint8List input = await _selectedImage!.readAsBytes();
    img.Image image = img.decodeImage(input)!;

    // 画像をリサイズしてTensorImageに変換
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224); // モデルの入力サイズに合わせてリサイズ
    TensorImage tensorImage = TensorImage.fromImage(resizedImage);

    // 結果を格納するためのリストを用意
    var output = List.filled(_interpreter.getOutputTensor(0).shape[1], 0).reshape([1]);

    // 推論実行
    _interpreter.run(tensorImage.buffer, output);

    setState(() {
      _predictionResult = output.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Prediction'),
      ),
      body: Column(
        children: [
          if (_selectedImage != null)
            Image.file(_selectedImage!),
          if (_predictionResult.isNotEmpty)
            Text(
              "Prediction Result: $_predictionResult",
              style: TextStyle(fontSize: 20),
            ),
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Select Image'),
          ),
        ],
      ),
    );
  }
}

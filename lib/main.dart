import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
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
        // 出力詳細を取得
        var outputDetails = _interpreter.getOutputTensor(0);
        
        // 出力形状を取得
        var outputShape = outputDetails.shape;
        print('Output shape: $outputShape');
      } catch (e) {
        print("Error loading TFLite model: $e");
      }
        
    }

    Future<void> _pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        File file = File(pickedFile.path);

        setState(() {
          _selectedImage = file;
        });

        _printInputShape();

        _runModel();
      }
    }

    // Future<void> _runModel() async {
    //   if (_selectedImage == null || _interpreter == null) {
    //     return;
    //   }

    //   // 画像をロードしてリサイズ
    //   Uint8List input = await _selectedImage!.readAsBytes();
    //   img.Image image = img.decodeImage(input)!;
    //   img.Image resizedImage = img.copyResize(image, width: 224, height: 224); // モデルの入力サイズに合わせてリサイズ

    //   // 画像を1次元Float32Listに変換
    //   Float32List inputBuffer = _imageToFloat32List(resizedImage);

    //   // 結果を格納するためのリストを用意
    //   var outputBuffer = List.filled(_interpreter.getOutputTensor(0).shape[1], 0.0).reshape([1]);

    //   // 推論実行
    //   _interpreter.run(inputBuffer, outputBuffer);

    //   setState(() {
    //     _predictionResult = outputBuffer.toString();
    //   });
    // }
  Future<void> _runModel() async {
    if (_selectedImage == null || _interpreter == null) {
      return;
    }

    Uint8List input = await _selectedImage!.readAsBytes();
    img.Image image = img.decodeImage(input)!;

    // モデルの入力サイズに画像をリサイズ
    img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

    // 入力データを Float32List に変換
    Float32List inputBuffer = _imageToFloat32List(resizedImage);

    // 入力データを [1, 3, 224, 224] の形状にリシェイプ
    var inputTensor = inputBuffer.reshape([1, 3, 224, 224]);

    // 出力形状を取得して出力バッファを作成
    var outputShape = _interpreter.getOutputTensor(0).shape;
    var outputBuffer = List.filled(outputShape.reduce((a, b) => a * b), 0.0).reshape(outputShape);
    // var outputBuffer = List.generate(outputShape[0], (_) => List.filled(outputSize, 0.0));

    print("Running model...");
    // print(outputBuffer);

    // 推論実行
    _interpreter.run(inputTensor, outputBuffer);

    // 最大値を持つインデックスを取得
    // 出力バッファをフラットなリストに変換
  // outputBuffer[0]の型に基づいて適切に展開
  print('autoputtobaffa');
  // print(outputBuffer[0]); 
  print(outputBuffer[0].runtimeType); 
  List<double> outputScores = (outputBuffer[0] as List)  // List<dynamic>からListにキャスト
    .map((x) {
      if (x is Iterable) {
        return x.expand((y) => (y is Iterable) ? y : [y]).toList();  // 2次元目も展開
      } else {
        return [x]; // xがIterableでない場合はリストにラップ
      }
    })
    .expand((x) => x is Iterable ? x : [x]) // xがIterableでない場合でもリストとして処理
    .map((item) => item is double ? item : 0.0)  // itemをdouble型に変換
    .toList();


  print('outputscores:');

  print(outputBuffer);
  print(outputShape);
  print(outputScores);



  // 最大値を持つインデックスを取得（クラス予測）
  int predictedIndex = outputScores.indexOf(outputScores.reduce((a, b) => a > b ? a : b));

  setState(() {
    _predictionResult = "Predicted Class: $predictedIndex";
  });



    print("Prediction complete: Class $predictedIndex");
}




void _printInputShape() {
  var inputShape = _interpreter.getInputTensor(0).shape;
  print("Model expects input shape: $inputShape");
}

  

  Float32List _imageToFloat32List(img.Image image) {
      int width = image.width;
      int height = image.height;


      Float32List floatList = Float32List(3 * width * height);
      int indexR = 0;
      int indexG = width * height;
      int indexB = 2 * width * height;

      print("Before getting pixel type");

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          // Pixel型を取得
          var pixel = image.getPixel(x, y);

          // 赤、緑、青のチャンネルを取得
          int r = pixel.r.toInt();  // 赤チャンネル
          int g = pixel.g.toInt();  // 緑チャンネル
          int b = pixel.b.toInt();  // 青チャンネル

          // 正規化
          floatList[indexR++] = r / 255.0;
          floatList[indexG++] = g / 255.0;
          floatList[indexB++] = b / 255.0;
        }
      }
  return floatList;
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

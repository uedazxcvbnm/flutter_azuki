import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img; // 画像処理用のパッケージ

void main() {
  runApp(MyApp());
}

// Flutterアプリのメインクラスを作成
class MyApp extends StatelessWidget {
  @override
  // buildメソッド：UIを作るための関数
  // context はアプリのUIツリー情報
  Widget build(BuildContext context) {
    // MaterialApp：Flutterのアプリの基本構造
    return MaterialApp(
      // アプリ起動時に表示する画面
      home: ImagePredictionScreen(),
    );
  }
}

class ImagePredictionScreen extends StatefulWidget {
  @override
  // _ImagePredictionScreenState()を作成　インスタンスを返す
  _ImagePredictionScreenState createState() => _ImagePredictionScreenState();
}
  // ImagePredictionScreenを継承
  class _ImagePredictionScreenState extends State<ImagePredictionScreen> {
    // 推論エンジン
    late Interpreter _interpreter;
    // 選択された画像ファイル
    File? _selectedImage;
    // 推論結果　初期値は空
    String _predictionResult = "";

    @override
    // ウィジェットが作成されたとき最初に１かいだけ実行される
    void initState() {
      // 親クラスの初期化処理
      super.initState();
      // モデルをロード
      _loadModel();
    }

    Future<void> _loadModel() async {
      try {
        // モデルをアプリに読み込む
        // １個目がファインチューニング　２個目が転移学習
        _interpreter = await Interpreter.fromAsset('assets/model.tflite');
        // _interpreter = await Interpreter.fromAsset('assets/model_transfer.tflite');
        // 出力詳細を取得
        var outputDetails = _interpreter.getOutputTensor(0);
        
        // 出力形状を取得
        var outputShape = outputDetails.shape;
        print('Output shape: $outputShape');
      } catch (e) {
        // 例外時
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

    
    Future<void> _runModel() async {
      // 画像が選択されていない　モデルがロードされていない
      // そういう時は何もしない
      if (_selectedImage == null || _interpreter == null) {
        return;
      }
      // 画像をバイナリデータとして読み込む
      // readAsBytes
      Uint8List input = await _selectedImage!.readAsBytes();
      // 画像データをデコード
      img.Image image = img.decodeImage(input)!;

      // モデルの入力サイズに画像をリサイズ
      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);

      // 入力データを Float32List に変換
      Float32List inputBuffer = _imageToFloat32List(resizedImage);

      // 入力データを [1, 3, 224, 224] の形状にリシェイプ
      //　バッチサイズ、チャンネル（RGB）、画像サイズ＊画像サイズ
      // _printInputShape()での表示結果をもとに配列の変更
      var inputTensor = inputBuffer.reshape([1, 3, 224, 224]);

      // 出力形状を取得して出力バッファを作成
      // 出力形状を取得
      var outputShape = _interpreter.getOutputTensor(0).shape;
      // 
      var outputBuffer = List.filled(outputShape.reduce((a, b) => a * b), 0.0).reshape(outputShape);
      // var outputBuffer = List.generate(outputShape[0], (_) => List.filled(outputSize, 0.0));

      print("Running model...");
      // print(outputBuffer);

      // 推論実行
      // (入力する変数、結果を格納する変数)
      _interpreter.run(inputTensor, outputBuffer);

      print('autoputtobaffa');
      // outputbufferのデータ型を確認
      print(outputBuffer[0].runtimeType); 


      // 最大値を持つインデックスを取得
      // 出力バッファをフラットなリストに変換
      // outputBuffer[0]の型に基づいて適切に展開
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
          // int pixel = って事前に指定しても、どうしても変数pixelは型がピクセル型に自動的になってしまう
          // Pixel型を取得
          // ここの段階で整数型にする必要はなかった。正規化をする際に変数r, g, bが整数型になっていたらいい
          var pixel = image.getPixel(x, y);

          // 赤、緑、青のチャンネルを取得
          // Pixel 型のメソッドを使用
          // pixel型から赤、緑、青それぞれのチャンネルを取得
          // いくら変数の先頭にintをつけていようが意味がない、pixel.rを実行したら返す値はnum型固定だった
          // なので末尾に.toInt()をつける
          int r = pixel.r.toInt();  // 赤チャンネル
          int g = pixel.g.toInt();  // 緑チャンネル
          int b = pixel.b.toInt();  // 青チャンネル

          // 正規化
          // 正規化をする際に変数r, g, bが整数型になっていたらいい
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
            if(_predictionResult == 'Predicted Class: 0')
              Text(
                "Prediction Result: class_low",
                style: TextStyle(fontSize: 20),
              )
            else if(_predictionResult == 'Predicted Class: 1')
              Text(
                "Prediction Result: class_middle",
                style: TextStyle(fontSize: 20),
              )
            else
              Text(
                "Prediction Result: class_high",
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

import 'package:flutter/material.dart';
// デバイス上のカメラを操作するためのツール

// アプリケーションの実行を開始するために必要な最小限のセットアップ

// 非同期処理　
// 非同期操作が完了したことのみを通知 Futureが特定の値を返さない
Future<void> main() async {
  // Flutter Engineの機能を利用したい場合に呼び出す
  WidgetsFlutterBinding.ensureInitialized();

  // デバイスで使用可能なカメラのリストを取得
  final cameras = await availableCameras();

  // 利用可能なカメラのリストから特定のカメラを取得
  final firstCamera = cameras.first;

  // 取得できているか確認
  print(firstCamera);

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.camera}) : super(key: key);
  final CameraDescription camera;
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Camera Example',
      theme: ThemeData(),
      home: TakePictureScreen(camera: camera),
    );
  }
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

// StatefulWidget自体はシンプルな構造で複雑な処理等はStateクラス
// Stateクラスで機能的なメソッドを実装
// Stateクラスはbuildメソッドをもつ
class TakePictureScreenState extends State<TakePictureScreen> {
  // late 宣言後に初期化されるnon-nullable変数
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    _controller = CameraController(
      // カメラを指定
      widget.camera,
      // 解像度を定義
      ResolutionPreset.medium,
    );

    // コントローラーを初期化
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // ウィジェットが破棄されたら、コントローラーを破棄
    _controller.dispose();
    super.dispose();
  }

  @override
  // Widget build(BuildContext context) {
  //   // NEXT：プレビュー画面を表示
  //   return SizedBox();
  // }

  Widget build(BuildContext context) {
    // FutureBuilder で初期化を待ってからプレビューを表示（それまではインジケータを表示）
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // カメラコントローラー　カメラと解像度を指定している
          return CameraPreview(_controller);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}


// カメラで取得後
// 取得した画像ファイル
File? _storedImage;
// ImagePickerのインスタンス
final picker = ImagePicker();
// 推論結果のテキスト
String resultText = '';
// ホットドッグかどうか
bool isHotdog = false;
// 推論済みかどうか
bool isPredicted = false;
// Classifierのインストラクタ
late Classifier _classifier;

/* カメラから画像を取得 */
Future<void> _takePicture() async {
  final imageFile = await picker.pickImage(
    source: ImageSource.camera,
  );
  if (imageFile == null) {
    return;
  }
  setState(() {
    _storedImage = File(imageFile.path);
  });
  predict();
}

/* ギャラリーから画像を取得 */
Future<void> _getImageFromGallery() async {
  final imageFile = await picker.pickImage(
    source: ImageSource.gallery,
  );
  if (imageFile == null) {
    return;
  }
  setState(() {
    _storedImage = File(imageFile.path);
  });
  predict();
}

/* initState */
@override
void initState() {
  super.initState();
  _classifier = Classifier('hotdog.tflite', 'assets/labels.txt');
}


/* 推論処理 */
void predict() async {
  // classifierへの入力はImage型なので、Image型にデコード
  img.Image inputImage = img.decodeImage(_storedImage!.readAsBytesSync())!;
  // 推論を行う
  double confidence = _classifier.predict(inputImage);

  // confidenceをカメラの画面に表示
  setState(() {
    isPredicted = true;
    resultText = confidence;
  });
}
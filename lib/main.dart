import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:multi_image_picker/multi_image_picker.dart';

import 'package:firebase_storage/firebase_storage.dart';


void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Asset> images = List<Asset>();
  String _error = 'No Error Dectected';

  @override
  void initState() {
    super.initState();
  }

  Widget buildGridView() {
    return GridView.count(
      crossAxisCount: 3,
      children: List.generate(images.length, (index) {
        Asset asset = images[index];
        return AssetThumb(
          asset: asset,
          width: 300,
          height: 300,
        );
      }),
    );
  }


  Future<void> loadAssets() async {
    setState(() {
      images = List<Asset>();
    });

    List<Asset> resultList = List<Asset>();
    String error = 'No Error Dectected';

    try {
      resultList = await MultiImagePicker.pickImages(
          maxImages: 300,
          enableCamera: true,
          cupertinoOptions: CupertinoOptions(takePhotoIcon: "chat"),
          materialOptions: MaterialOptions(
            actionBarColor: "#abcdef",
            actionBarTitle: "Example App",
            allViewTitle: "All Photos",
            selectCircleStrokeColor: "#000000",
          ));
    } on PlatformException catch (e) {
      error = e.message;
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      images = resultList;
      _error = error;
    });
  }

  void uploadImages(List<Asset> assets){
    print('Uploading Images');
    assets.forEach((asset) async{
      try{
        ByteData byteData = await asset.requestOriginal();
        List<int> imageData = byteData.buffer.asUint8List();
        StorageReference ref = FirebaseStorage.instance.ref().child(asset.name);
        StorageUploadTask uploadTask = ref.putData(imageData);

        await (await uploadTask.onComplete).ref.getDownloadURL();

        print('Done Uploading Images');
      }catch(e){
        print('--------------Error while uploading------ ($e)');
      }
    });
    setState(() {
      images = List<Asset>();
    });
  }


  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Column(
          children: <Widget>[
            Center(child: Text('Error: $_error')),
            RaisedButton(
              child: Text("Pick images"),
              onPressed: loadAssets,
            ),
            RaisedButton(
              child: Text("Upload images"),
              onPressed: (){
                uploadImages(images);
              },
            ),
            Expanded(
              child: buildGridView(),
            )
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:ripto/constants/app_constants.dart';
import 'package:ripto/constants/color_constants.dart';
import 'package:photo_view/photo_view.dart';

class FullPhotoPage extends StatelessWidget {
  final String url;

  const FullPhotoPage({Key? key, required this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.fullPhotoTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
      ),
      body: PhotoView(
        imageProvider: NetworkImage(url),
      ),
    );
  }
}

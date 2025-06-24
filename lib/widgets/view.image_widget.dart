import 'package:flutter/material.dart';

import 'package:kaffi_cafe_pos/utils/colors.dart';

class ViewImageWidget extends StatelessWidget {
  String image;

  ViewImageWidget({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cloudWhite,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: cloudWhite,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.arrow_left_outlined,
            color: bayanihanBlue,
          ),
        ),
      ),
      body: Center(
        child: Image.network(
          image,
        ),
      ),
    );
  }
}

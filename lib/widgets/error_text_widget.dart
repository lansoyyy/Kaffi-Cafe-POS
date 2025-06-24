import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';

class ErrorTextWidget extends StatelessWidget {
  const ErrorTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextWidget(
        text: 'Something went wrong.',
        fontSize: 12,
        fontFamily: 'Medium',
        color: Colors.grey,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';

class EmptyTextWidget extends StatelessWidget {
  const EmptyTextWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextWidget(
        text: 'No available data',
        fontSize: 12,
        fontFamily: 'Regular',
        color: Colors.grey,
      ),
    );
  }
}

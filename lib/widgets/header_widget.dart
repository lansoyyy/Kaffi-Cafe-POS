import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:kaffi_cafe_pos/widgets/text_widget.dart';
import 'package:kaffi_cafe_pos/widgets/touchable_widget.dart';

class HeaderWidget extends StatelessWidget {
  String title;
  bool withGreetings;

  HeaderWidget({
    super.key,
    this.withGreetings = false,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: title,
              fontSize: 32,
              fontFamily: 'Bold',
            ),
            Visibility(
              visible: withGreetings,
              child: TextWidget(
                text: 'Good Afternoon Lance',
                fontSize: 14,
                fontFamily: 'Medium',
                color: Colors.black,
              ),
            ),
          ],
        ),
        TouchableWidget(
          onTap: () {},
          child: CircleAvatar(
            minRadius: 25,
            maxRadius: 25,
            backgroundColor: Colors.grey,
          ),
        ),
      ],
    );
  }
}

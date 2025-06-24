import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/utils/colors.dart';
import 'package:kaffi_cafe_pos/widgets/touchable_widget.dart';

class ExpandableTextWidget extends StatefulWidget {
  final String text;
  final double fontSize;
  final String fontFamily;
  final Color color;
  final Color readmoreColor;
  final int maxLines;

  const ExpandableTextWidget({
    Key? key,
    required this.text,
    this.fontSize = 12,
    this.fontFamily = 'Regular',
    this.color = Colors.black,
    this.readmoreColor = bayanihanBlue,
    this.maxLines = 2,
  }) : super(key: key);

  @override
  _ExpandableTextWidgetState createState() => _ExpandableTextWidgetState();
}

class _ExpandableTextWidgetState extends State<ExpandableTextWidget> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final displayText = widget.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          maxLines: isExpanded ? null : widget.maxLines,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontFamily: widget.fontFamily,
            color: widget.color,
          ),
        ),
        if (displayText.length > 100) // You can tweak this threshold
          TouchableWidget(
            onTap: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Text(
              isExpanded ? 'Read less' : 'Read more',
              style: TextStyle(
                color: widget.readmoreColor,
                fontSize: widget.fontSize,
                fontFamily: 'Bold',
              ),
            ),
          ),
      ],
    );
  }
}

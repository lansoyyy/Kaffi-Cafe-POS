import 'package:flutter/material.dart';
import 'package:kaffi_cafe_pos/widgets/text_widget.dart';

class TextFieldWidget extends StatefulWidget {
  final String label;
  final String? hint;
  bool? isObscure;
  final TextEditingController controller;
  final double? width;
  final double? height;
  final int? maxLine;
  final TextInputType? inputType;
  late bool? showEye;
  late bool? enabled;
  late bool? isInterest;
  late Color? color;
  late Color? borderColor;
  late Color? hintColor;
  late double? radius;
  final String? Function(String?)? validator; // Add validator parameter

  final TextCapitalization? textCapitalization;
  Function(String)? onChanged;

  TextFieldWidget({
    super.key,
    required this.label,
    this.hint = '',
    required this.controller,
    this.isObscure = false,
    this.isInterest = false,
    this.onChanged,
    this.enabled = true,
    this.width = 300,
    this.height = 40,
    this.maxLine = 1,
    this.hintColor = Colors.black,
    this.borderColor = Colors.transparent,
    this.showEye = false,
    this.color = Colors.black,
    this.radius = 5,
    this.textCapitalization = TextCapitalization.sentences,
    this.inputType = TextInputType.text,
    this.validator, // Add validator parameter
  });

  @override
  State<TextFieldWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(text: widget.label, fontSize: 14, color: widget.hintColor!),
        const SizedBox(
          height: 5,
        ),
        TextFormField(
          style: const TextStyle(
              fontFamily: 'QRegular', fontSize: 14, color: Colors.black),
          textCapitalization: widget.textCapitalization!,
          keyboardType: widget.inputType,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            suffixIcon: widget.isInterest!
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextWidget(
                      text: '%',
                      fontSize: 18,
                      fontFamily: 'Medium',
                    ),
                  )
                : widget.showEye! == true
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            widget.isObscure = !widget.isObscure!;
                          });
                        },
                        icon: widget.isObscure!
                            ? const Icon(Icons.visibility)
                            : const Icon(Icons.visibility_off))
                    : const SizedBox(),
            filled: true,
            fillColor: Colors.white,
            hintText: widget.hint,
            border: InputBorder.none,
            enabled: widget.enabled!,
            disabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: widget.borderColor!,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: widget.borderColor!,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: widget.borderColor!,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Colors.red,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            errorStyle: const TextStyle(fontFamily: 'QBold', fontSize: 12),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Colors.red,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),

          maxLines: widget.maxLine,
          obscureText: widget.isObscure!,
          controller: widget.controller,
          validator:
              widget.validator, // Pass the validator to the TextFormField
        ),
      ],
    );
  }
}

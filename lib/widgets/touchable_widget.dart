import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TouchableWidget extends StatefulWidget {
  final Widget child;
  final Function()? onTap;
  final bool? disabled;

  const TouchableWidget(
      {super.key, required this.child, this.onTap, this.disabled = false});

  @override
  _TouchableWidgetState createState() => _TouchableWidgetState();
}

class _TouchableWidgetState extends State<TouchableWidget> {
  bool isDown = false;

  @override
  void initState() {
    super.initState();
    setState(() => isDown = false);
  }

  @override
  Widget build(BuildContext context) {
    bool disabled = widget.disabled!;

    return GestureDetector(
      onTapDown: (_) {
        if (disabled) {
          return;
        }
        setState(() => isDown = true);
      },
      onTapUp: (_) {
        if (disabled) {
          return;
        }
        Future.delayed(const Duration(milliseconds: 50), () {
          if (context.mounted) {
            setState(() => isDown = false);
          }
        });
      },
      onTapCancel: disabled ? () {} : () => setState(() => isDown = false),
      onTap: disabled ? () {} : widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: isDown ? 0.25 : 1,
        child: widget.child,
      ),
    );
  }
}

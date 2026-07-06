import 'package:flutter/material.dart';

class DefaultPadding extends StatelessWidget {
  final Widget child;
  final double paddingHorizontal;
  final double paddingBottom;
  final double paddingTop;
  const DefaultPadding({
    super.key,
    required this.child,
    this.paddingBottom = 0,
    this.paddingTop = 0,
    this.paddingHorizontal = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: paddingHorizontal,
        right: paddingHorizontal,
        bottom: paddingBottom,
        top: paddingTop,
      ),
      child: child,
    );
  }
}

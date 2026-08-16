// lib/core/widgets/app_logo.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width = 40,
    this.height = 40,
    this.showText = false,
  });

  final double width;
  final double height;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    if (showText) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/logo.svg',
            width: width,
            height: height,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'E-learning',
                style: TextStyle(
                  fontSize: width * 0.6,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                'AI',
                style: TextStyle(
                  fontSize: width * 0.6,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return SvgPicture.asset(
      'assets/images/logo.svg',
      width: width,
      height: height,
    );
  }
}
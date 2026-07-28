// frontend/lib/features/home/widgets/home_avatar.dart

import 'package:flutter/material.dart';

class HomeAvatar extends StatelessWidget {
  const HomeAvatar({super.key, this.size = 60});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.amber.shade100,
      child: Text(
        '🧑‍🏫',
        style: TextStyle(fontSize: size * 0.6),
      ),
    );
  }
}
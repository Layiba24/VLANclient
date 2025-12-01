import 'package:flutter/material.dart';

class MobileVideoPlayer extends StatelessWidget {
  const MobileVideoPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text('Mobile player not available on web',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

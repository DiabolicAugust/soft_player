import 'package:flutter/material.dart';

class NeuBox extends StatelessWidget {
  Widget child;
   NeuBox({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.shade500,
                blurRadius: 15,
                offset:  const Offset(5, 5)
            ),
            const BoxShadow(
                color: Colors.white,
                blurRadius: 15,
                offset: Offset(-5, -5)
            ),
          ]
      ),
      child: Center(
        child: child,
      ),
    );
  }
}

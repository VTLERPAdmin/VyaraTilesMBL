import 'package:flutter/material.dart';

class EVSuccessScreen extends StatefulWidget {
  final String title;
  final String subtitle;

  const EVSuccessScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<EVSuccessScreen> createState() => _EVSuccessScreenState();
}

class _EVSuccessScreenState extends State<EVSuccessScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.popUntil(context, (route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Icon(
              Icons.electric_bolt,
              size: 90,
              color: Color(0xFF06224D),
            ),

            const SizedBox(height: 20),

            Text(
              widget.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF06224D),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              widget.subtitle,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
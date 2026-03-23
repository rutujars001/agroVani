import 'package:flutter/material.dart';

/// 🌾 Response Card Widget
class ResponseCard extends StatelessWidget {
  final String text;

  const ResponseCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

/// 🎤 Mic Button Widget
class MicButton extends StatelessWidget {
  final VoidCallback onTap;

  const MicButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: const CircleAvatar(
        radius: 45,
        backgroundColor: Colors.white,
        child: Icon(
          Icons.mic,
          size: 40,
          color: Colors.green,
        ),
      ),
    );
  }
}

/// ⚡ Quick Action Button Widget
class QuickButton extends StatelessWidget {
  final String title;
  final IconData icon;

  const QuickButton({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white,
          child: Icon(icon, color: Colors.green),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(color: Colors.white),
        )
      ],
    );
  }
}
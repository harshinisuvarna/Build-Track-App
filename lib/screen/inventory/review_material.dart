// review_material.dart — Redirects to the unified AI Voice Entry screen.
// The old separate review screen is replaced by AiVoiceEntryScreen.
export 'package:buildtrack_mobile/screen/inventory/ai_voice_entry_screen.dart'
    show AiVoiceEntryScreen;

// Legacy class alias so any existing Navigator.pushNamed('/review-material')
// calls or direct references still compile.
// ignore: unused_import
import 'package:buildtrack_mobile/screen/inventory/ai_voice_entry_screen.dart';
import 'package:flutter/material.dart';

class ReviewVoiceEntryScreen extends StatelessWidget {
  const ReviewVoiceEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pass type = material to the unified screen
    return const AiVoiceEntryScreen();
  }
}
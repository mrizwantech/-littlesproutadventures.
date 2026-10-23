import 'package:flutter/material.dart';
import '../../../core/widgets/press_feedback.dart';

import 'reading_pathway_screen.dart';

class ReadingExploreScreen extends StatelessWidget {
  const ReadingExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF102354);
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2FAFF),
        foregroundColor: ink,
        title: const Text('Reading'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Choose a lesson',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                child: PressableInkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReadingPathwayScreen(),
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Icon(Icons.abc_rounded, size: 40, color: ink),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Letters & Sounds',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: ink,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text('Explore the alphabet A-Z',
                                  style: TextStyle(color: ink)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: ink),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

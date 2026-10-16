import 'package:flutter/material.dart';

import '../domain/reading_pathway.dart';

class ReadingPathwayScreen extends StatelessWidget {
  const ReadingPathwayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFF),
      appBar: AppBar(title: const Text('Ready to Read')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Little steps toward reading',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Designed for ages 3-5, with a grown-up nearby. Explore at your '
                "child's pace: there are no timers, penalties, or locked stages.",
              ),
              const SizedBox(height: 12),
              const Text(
                'Enjoy a book, rhyme, or playful letter activity together. '
                'A full routine can be about 5-10 minutes, but stopping earlier '
                'or repeating a favorite is always okay.',
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < readingStages.length; index++)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('${index + 1}. ${readingStages[index].title}',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(readingStages[index].goal),
                        const SizedBox(height: 8),
                        Text(readingStages[index].examples),
                        const SizedBox(height: 12),
                        const Text('In-app activities coming soon'),
                        const SizedBox(height: 4),
                        Text(index == 0
                            ? 'Enjoy any picture book together today. Stories will never need to be unlocked.'
                            : 'Explore this idea together away from the screen.'),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('For grown-ups: learning focus'),
                          children: [
                            Text(readingStages[index].framework),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const Text(
                'Our app stages are not official school levels or a readiness '
                'test. U.S. preschool guidance: Head Start Early Learning '
                'Outcomes Framework (ELOF). State expectations vary. Kindergarten '
                'standards are a later destination, not a requirement to start.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Future skill summaries will use Exploring, Practicing, and '
                'Comfortable across different examples and sessions. Reading '
                'activities and saved learning progress are not available yet.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

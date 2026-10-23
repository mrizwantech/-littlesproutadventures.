import 'package:flutter/material.dart';
import '../../../core/widgets/press_feedback.dart';

import '../domain/child_profile.dart';
import 'dashboard_mascot.dart';
import '../../reading/presentation/reading_pathway_screen.dart';
import '../../reading/presentation/reading_explore_screen.dart';
import '../../listening/presentation/vocabulary_game_screen.dart';
import '../../counting/presentation/counting_pathway_screen.dart';

class LearningDashboard extends StatelessWidget {
  const LearningDashboard({
    super.key,
    required this.profile,
    required this.onSettings,
    this.isOffline = false,
    required this.onRefresh,
  });

  final ChildProfile profile;
  final VoidCallback onSettings;
  final bool isOffline;
  final VoidCallback onRefresh;

  void _comingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$title is coming soon.')));
  }

  void _openReading(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ReadingExploreScreen()));
  }

  void _openLettersAndSounds(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ReadingPathwayScreen()));
  }

  void _openCounting(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const CountingPathwayScreen()));
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF102354);
    const categories = [
      ('Reading', Icons.star_rounded, Color(0xFFFFC94D)),
      ('Math', Icons.numbers_rounded, Color(0xFF20AEF5)),
      ('Art', Icons.palette_rounded, Color(0xFFFF728D)),
      ('Music', Icons.music_note_rounded, Color(0xFFAA69EE)),
    ];
    const activities = [
      ('Letters & Sounds', 'Explore the alphabet A-Z', '🍎', Color(0xFFFFE8A1)),
      ('Counting', 'Explore numbers 1-100', '123', Color(0xFFDAF4AF)),
      ('Shapes', 'Match the shapes', '🔷', Color(0xFFE9D9FF)),
      (
        'Listening & Vocabulary',
        'Listen and find a picture',
        '🐻',
        Color(0xFFFFDEC2)
      ),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFF),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFFFE6C7),
                        child: Text(profile.avatar?.emoji ?? '🌱',
                            style: const TextStyle(fontSize: 36)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Hello, ${profile.nickname}!',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: ink)),
                            const SizedBox(height: 4),
                            const Text("Let's learn something new!",
                                style: TextStyle(color: ink)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit child profile',
                        onPressed: onSettings,
                        icon: const Icon(Icons.settings_rounded, color: ink),
                      ),
                    ],
                  ),
                  if (isOffline)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                                'Offline: showing the profile saved on this phone.'),
                            TextButton(
                                onPressed: onRefresh,
                                child: const Text('Refresh')),
                          ],
                        ),
                      ),
                    ),
                  const DashboardMascot(),
                  const SizedBox(height: 24),
                  LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth < 300
                        ? (constraints.maxWidth - 12) / 2
                        : (constraints.maxWidth - 36) / 4;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        for (final (label, icon, color) in categories)
                          SizedBox(
                            width: width,
                            child: Column(
                              children: [
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: color,
                                    foregroundColor: ink,
                                    padding: const EdgeInsets.all(14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(22)),
                                  ),
                                  onPressed: () => label == 'Reading'
                                      ? _openReading(context)
                                      : label == 'Math'
                                          ? _openCounting(context)
                                          : _comingSoon(context, label),
                                  child: Icon(icon,
                                      size: 34, semanticLabel: label),
                                ),
                                const SizedBox(height: 6),
                                Text(label, style: const TextStyle(color: ink)),
                                Text(
                                    label == 'Reading' || label == 'Math'
                                        ? 'Explore'
                                        : 'Coming soon',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 11, color: ink)),
                              ],
                            ),
                          ),
                      ],
                    );
                  }),
                  const SizedBox(height: 28),
                  const Text("Today's Activities",
                      style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: ink)),
                  const SizedBox(height: 12),
                  for (final (title, subtitle, emoji, color) in activities)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Color(0xFFD5EBFC)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: PressableInkWell(
                          onTap: () {
                            if (title == 'Letters & Sounds') {
                              _openLettersAndSounds(context);
                            } else if (title == 'Counting') {
                              _openCounting(context);
                            } else if (title == 'Listening & Vocabulary') {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const VocabularyGameScreen(),
                                ),
                              );
                            } else {
                              _comingSoon(context, title);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 60,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Text(emoji,
                                      style: const TextStyle(fontSize: 28)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: ink)),
                                      Text(subtitle,
                                          style: const TextStyle(color: ink)),
                                      const SizedBox(height: 4),
                                      Text(
                                          title == 'Listening & Vocabulary' ||
                                                  title == 'Counting' ||
                                                  title == 'Letters & Sounds'
                                              ? 'Play now'
                                              : 'Coming soon',
                                          style: TextStyle(
                                              fontSize: 12, color: ink)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: ink),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 3) {
            onSettings();
          } else if (index != 0) {
            _comingSoon(context, index == 1 ? 'Library' : 'Progress');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_rounded), label: 'Library'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_rounded), label: 'Progress'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

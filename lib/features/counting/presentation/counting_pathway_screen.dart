import 'package:flutter/material.dart';

import '../../../core/widgets/press_feedback.dart';
import '../../listening/data/prompt_speaker.dart';
import '../domain/counting_curriculum.dart';
import 'counting_lesson_screen.dart';

class CountingPathwayScreen extends StatefulWidget {
  const CountingPathwayScreen({super.key, this.speaker});

  final PromptSpeaker? speaker;

  @override
  State<CountingPathwayScreen> createState() => _CountingPathwayScreenState();
}

class _CountingPathwayScreenState extends State<CountingPathwayScreen> {
  final List<CountingEvidence> _evidence = [];
  final Set<int> _explored = {};
  int _rangeStart = 1;

  void _open(CountingLesson lesson) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => CountingLessonScreen(
        lesson: lesson,
        speaker: widget.speaker,
        onCompleted: (lesson, evidence) {
          if (!mounted) return;
          setState(() {
            _explored.add(lesson.number);
            _evidence.addAll(evidence);
          });
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFEFF8FF),
        appBar: AppBar(title: const Text('Counting')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Your number journey',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text(
                    'Explore 1-100. Count single stars to 10, then build larger numbers with tens and ones.'),
                const SizedBox(height: 16),
                Text(
                    '${_explored.length} of ${countingLessons.length} numbers explored'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                    value: _explored.length / countingLessons.length),
                const SizedBox(height: 24),
                DropdownButtonFormField<int>(
                  initialValue: _rangeStart,
                  decoration: const InputDecoration(
                    labelText: 'Choose a number range',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (var start = 1; start <= 100; start += 10)
                      DropdownMenuItem(
                        value: start,
                        child: Text('$start-${start + 9}'),
                      ),
                  ],
                  onChanged: (start) {
                    if (start != null) setState(() => _rangeStart = start);
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final lesson
                        in countingLessons.skip(_rangeStart - 1).take(10))
                      Semantics(
                        button: true,
                        label: 'Open number ${lesson.number}',
                        onTap: () => _open(lesson),
                        excludeSemantics: true,
                        child: Material(
                          color: _explored.contains(lesson.number)
                              ? const Color(0xFFDAF4AF)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(color: Color(0xFFC9E7CC)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: PressableInkWell(
                            onTap: () => _open(lesson),
                            child: SizedBox(
                              width: 136,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('${lesson.number}',
                                        style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF102354))),
                                    Text(lesson.name),
                                    if (_explored.contains(lesson.number))
                                      const Icon(Icons.check_circle_rounded,
                                          color: Color(0xFF2F8F4E)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('1-10: count objects and make groups. '
                    '11-20: a ten and extra ones. '
                    '21-100: count and build with tens and ones. '
                    'Number-neighbor and counting-pattern games are coming later.'),
                const SizedBox(height: 24),
                ExpansionTile(
                  title: const Text('For grown-ups: session practice'),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                          'Practice is not a mastery score. A spoken count is modeled, '
                          'not a test of your child saying the sequence. Viewing a '
                          'number is guided exposure, not proof of recognition. '
                          'Progress is only kept while this counting journey is open.'),
                    ),
                    for (final skill in CountingSkill.values)
                      ListTile(
                        title: Text(_skillLabel(skill)),
                        subtitle: Text(_summary(skill)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  String _summary(CountingSkill skill) {
    final attempts = _evidence.where((item) => item.skill == skill);
    if (attempts.isEmpty) return 'Not assessed';
    if (skill == CountingSkill.numeralRecognition) {
      return '${attempts.length} guided introductions; not assessed';
    }
    final correct = attempts.where((item) => item.correct).length;
    return '$correct successful practice attempts out of ${attempts.length}; '
        '${attempts.where((item) => item.assisted).length} with replay or retry';
  }

  String _skillLabel(CountingSkill skill) => switch (skill) {
        CountingSkill.countingSequence => 'Saying the counting sequence',
        CountingSkill.numeralRecognition => 'Recognizing written numbers',
        CountingSkill.countingObjects => 'Counting objects accurately',
        CountingSkill.understandingTotal => 'Understanding the total',
        CountingSkill.makingQuantity => 'Making a requested quantity',
        CountingSkill.tensAndOnes => 'Understanding tens and ones',
      };
}

import 'package:flutter/material.dart';

import '../../listening/data/prompt_speaker.dart';
import '../domain/shapes_curriculum.dart';
import 'shape_picture.dart';
import 'shapes_lesson_screen.dart';

class ShapesPathwayScreen extends StatefulWidget {
  const ShapesPathwayScreen({super.key, this.speaker});
  final PromptSpeaker? speaker;

  @override
  State<ShapesPathwayScreen> createState() => _ShapesPathwayScreenState();
}

class _ShapesPathwayScreenState extends State<ShapesPathwayScreen> {
  final _completed = <ShapeKind>{};
  final _evidence = <ShapeEvidence>[];
  int _visits = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFEFF8FF),
        appBar: AppBar(title: const Text('Shapes')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Your shape garden',
                    style: Theme.of(context).textTheme.headlineSmall),
                const Text('Meet a shape, find it, then find both matches.'),
                const SizedBox(height: 16),
                Text('${_completed.length} of 3 shapes explored'),
                for (final shape in ShapeKind.values)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: OutlinedButton(
                      onPressed: () {
                        final variation = _visits++;
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => ShapesLessonScreen(
                            shape: shape,
                            variation: variation,
                            speaker: widget.speaker,
                            onCompleted: (evidence) {
                              if (!mounted) return;
                              setState(() {
                                _completed.add(shape);
                                _evidence.addAll(evidence);
                              });
                            },
                          ),
                        ));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(children: [
                          ShapePicture(
                              shape: shape,
                              color: const Color(0xFF237F46),
                              size: 56),
                          const SizedBox(width: 16),
                          Expanded(child: Text('Meet the ${shape.label}')),
                          Icon(_completed.contains(shape)
                              ? Icons.check_circle
                              : Icons.chevron_right),
                        ]),
                      ),
                    ),
                  ),
                const Text('Rectangle and more shape games are coming later.'),
                ExpansionTile(
                  title: const Text('For grown-ups: session practice'),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                          'Practice is not a mastery score. Introductions '
                          'and outline demonstrations are not recognition tests. '
                          'Progress lasts only while this shape garden is open.'),
                    ),
                    for (final skill in ShapeSkill.values)
                      ListTile(
                        title: Text(switch (skill) {
                          ShapeSkill.recognizing => 'Recognizing shapes',
                          ShapeSkill.matching => 'Matching shapes',
                          ShapeSkill.describing => 'Describing shapes',
                        }),
                        subtitle: Text(_summary(skill)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

  String _summary(ShapeSkill skill) {
    final attempts = _evidence.where((item) => item.skill == skill);
    if (attempts.isEmpty) return 'Not assessed';
    return '${attempts.where((item) => item.correct).length} successful practice '
        'attempts out of ${attempts.length}; '
        '${attempts.where((item) => item.assisted).length} with replay or retry';
  }
}

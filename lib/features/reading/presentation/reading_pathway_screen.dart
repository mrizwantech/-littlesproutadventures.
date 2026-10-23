import 'package:flutter/material.dart';
import '../../../core/widgets/press_feedback.dart';

import '../../listening/data/prompt_speaker.dart';
import '../domain/phonics_curriculum.dart';
import 'reading_lesson_screen.dart';

class ReadingPathwayScreen extends StatefulWidget {
  const ReadingPathwayScreen({super.key, this.speaker});

  final PromptSpeaker? speaker;

  @override
  State<ReadingPathwayScreen> createState() => _ReadingPathwayScreenState();
}

class _ReadingPathwayScreenState extends State<ReadingPathwayScreen> {
  static const _ink = Color(0xFF102354);
  static const _border = Color(0xFFD5EBFC);

  int _currentLetterIndex = 0;
  bool _alphabetComplete = false;
  int? _pressedLetterIndex;
  final Set<int> _completedLetters = {};

  Future<void> _openLetter(int index) async {
    await Navigator.of(context).push<ReadingLessonResult>(
      MaterialPageRoute(
        builder: (_) => ReadingLessonScreen(
          lesson: phonicsLessons[index],
          speaker: widget.speaker,
          onLessonCompleted: (completedLesson, _) {
            setState(() {
              _completedLetters.add(completedLesson.number);
              if (completedLesson.number < alphabet.length) {
                _currentLetterIndex = completedLesson.number;
              } else {
                _alphabetComplete = true;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2FAFF),
        foregroundColor: _ink,
        title: const Text(
          'Ready to Read',
          style: TextStyle(fontWeight: FontWeight.w800, color: _ink),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _currentLetterCard(),
              const SizedBox(height: 16),
              _progressCard(),
              const SizedBox(height: 24),
              const Text(
                'All letters',
                style: TextStyle(
                    fontSize: 23, fontWeight: FontWeight.w800, color: _ink),
              ),
              const SizedBox(height: 12),
              _alphabetGrid(),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      );

  Widget _currentLetterCard() {
    final lesson = phonicsLessons[_currentLetterIndex];
    final letter = phonicsLetters[lesson.letter]!;
    final buttonLabel = _alphabetComplete
        ? 'All letters explored'
        : _currentLetterIndex == 0
            ? 'Start with A'
            : 'Continue with ${letter.uppercase}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE8A1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '${letter.uppercase}${letter.lowercase}',
                  style: const TextStyle(
                      fontSize: 40, fontWeight: FontWeight.w800, color: _ink),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _alphabetComplete
                          ? 'Alphabet explored!'
                          : _currentLetterIndex == 0
                              ? 'Start with A'
                              : 'Next letter: ${letter.uppercase}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Name: ${letter.name}  •  Sound: ${letter.targetSound}',
                      style: const TextStyle(color: _ink),
                    ),
                    Text('As in ${letter.exampleWord}',
                        style: const TextStyle(color: _ink)),
                    if (lesson.words.isNotEmpty)
                      Text(
                        'Words to try: ${lesson.words.join(', ')}',
                        style: const TextStyle(color: _ink),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _alphabetComplete
                ? null
                : () => _openLetter(_currentLetterIndex),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final explored = _completedLetters.toList()..sort();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_completedLetters.length} of ${alphabet.length} letters explored',
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: _ink),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _completedLetters.length / alphabet.length,
              minHeight: 10,
              backgroundColor: const Color(0xFFE9F5FF),
              color: const Color(0xFF7BCB5B),
            ),
          ),
          if (explored.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final number in explored)
                  Chip(
                    backgroundColor: const Color(0xFFDAF4AF),
                    side: BorderSide.none,
                    label: Text(
                      alphabet[number - 1].toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: _ink),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _alphabetGrid() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (var index = 0; index < alphabet.length; index++)
          _letterTile(index),
      ],
    );
  }

  Widget _letterTile(int index) {
    final explored = _completedLetters.contains(index + 1);
    final current = !_alphabetComplete && index == _currentLetterIndex;
    final pressed = _pressedLetterIndex == index;
    final upper = alphabet[index].toUpperCase();
    return Semantics(
      button: true,
      label: 'Open letter $upper${explored ? ', explored' : ''}',
      excludeSemantics: true,
      onTap: () => _openLetter(index),
      child: PressFeedback(
        child: Material(
          color: pressed
              ? const Color(0xFFB6DFFF)
              : current
                  ? const Color(0xFFFFC94D)
                  : explored
                      ? const Color(0xFFDAF4AF)
                      : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: pressed || current ? _ink : _border,
              width: pressed ? 3 : 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTapDown: (_) => setState(() => _pressedLetterIndex = index),
            onTapUp: (_) => setState(() => _pressedLetterIndex = null),
            onTapCancel: () => setState(() => _pressedLetterIndex = null),
            splashColor: const Color(0x661684E6),
            highlightColor: const Color(0x331684E6),
            onTap: () => _openLetter(index),
            child: SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    upper,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800, color: _ink),
                  ),
                  if (explored)
                    const Positioned(
                      right: 4,
                      top: 4,
                      child: Icon(Icons.check_circle_rounded,
                          size: 16, color: Color(0xFF3E9B3A)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

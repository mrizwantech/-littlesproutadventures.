import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../../core/widgets/press_feedback.dart';

import '../../listening/data/prompt_speaker.dart';
import '../data/bundled_reading_prompt_speaker.dart';
import '../domain/phonics_curriculum.dart';
import '../domain/reading_narration.dart';

class _ReadingMascot extends StatefulWidget {
  const _ReadingMascot({required this.speaking, required this.celebrating});

  final bool speaking;
  final bool celebrating;

  @override
  State<_ReadingMascot> createState() => _ReadingMascotState();
}

class _ReadingMascotState extends State<_ReadingMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMotion();
  }

  @override
  void didUpdateWidget(_ReadingMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMotion();
  }

  void _updateMotion() {
    final active = (widget.speaking || widget.celebrating) &&
        !MediaQuery.disableAnimationsOf(context);
    if (active) {
      if (!_motion.isAnimating) _motion.repeat();
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      child: Image.asset(
        'assets/characters/wave.png',
        fit: BoxFit.contain,
        semanticLabel: widget.celebrating
            ? 'Excited sprout celebrating your practice'
            : 'Friendly sprout cheering you on',
      ),
      builder: (_, child) {
        final wave = sin(_motion.value * 2 * pi);
        final bounce = (1 - cos(_motion.value * 2 * pi)) / 2;
        return Transform.translate(
          key: ValueKey(widget.celebrating
              ? 'mascot-celebrating'
              : widget.speaking
                  ? 'mascot-speaking'
                  : 'mascot-idle'),
          offset: Offset(0, -bounce * (widget.celebrating ? 18 : 3)),
          child: Transform.rotate(
            angle: wave * (widget.celebrating ? 0.08 : 0.015),
            child: child,
          ),
        );
      },
    );
  }
}

class ReadingLessonResult {
  const ReadingLessonResult({
    required this.attempts,
    required this.completed,
  });

  final List<ReadingEvidence> attempts;
  final bool completed;
}

class ReadingLessonScreen extends StatefulWidget {
  const ReadingLessonScreen({
    required this.lesson,
    this.speaker,
    this.onLessonCompleted,
    super.key,
  });

  final PhonicsLesson lesson;
  final PromptSpeaker? speaker;
  final void Function(PhonicsLesson lesson, ReadingLessonResult result)?
      onLessonCompleted;

  @override
  State<ReadingLessonScreen> createState() => _ReadingLessonScreenState();
}

class _ReadingLessonScreenState extends State<ReadingLessonScreen>
    with WidgetsBindingObserver {
  late final PromptSpeaker _speaker;
  late PhonicsLesson _lesson = widget.lesson;
  late List<_ReadingTask> _tasks = _buildTasks(_lesson);
  final List<ReadingEvidence> _attempts = [];
  final Set<int> _answeredTasks = {};
  final Map<int, List<String>> _choiceOrder = {};
  int _taskIndex = 0;
  bool _active = true;
  bool _showSoundHint = false;
  bool _showBlendGuide = false;
  int _speechRequest = 0;
  bool _replayed = false;
  double _slideProgress = 0;
  String? _audioError;
  String? _choiceFeedback;
  final Set<String> _wrongChoices = {};
  bool _advancing = false;

  _ReadingTask get _task => _tasks[_taskIndex];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speaker = widget.speaker ?? BundledReadingPromptSpeaker();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _narrate();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) unawaited(_stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stop());
    super.dispose();
  }

  void _reportAudio(Object error, StackTrace stack) {
    debugPrint('Reading voice failed: $error\n$stack');
    if (mounted) {
      setState(() => _audioError =
          'The reading voice could not play. Please try again or ask a grown-up for help.');
    }
  }

  Future<void> _speak(String text) => _speakAll([text]);

  /// Plays clips in order; any newer speech or stop cancels the rest.
  Future<void> _speakAll(List<String> texts) async {
    final request = ++_speechRequest;
    if (!mounted || !_active) return;
    setState(() => _audioError = null);
    for (final text in texts) {
      if (request != _speechRequest || !mounted || !_active) return;
      try {
        await _speaker.speak(text);
      } catch (error, stack) {
        _reportAudio(error, stack);
        return;
      }
    }
  }

  void _narrate() => _speakAll(_narrationForTask());

  Future<void> _stop() async {
    _speechRequest++;
    try {
      await _speaker.stop();
    } catch (error, stack) {
      _reportAudio(error, stack);
    }
  }

  List<String> _choicesFor(int index) {
    return _choiceOrder.putIfAbsent(index, () {
      final target = _tasks[index].item;
      final letters = phonicsLetters.values
          .where((letter) => letter.lesson <= _lesson.number)
          .map((letter) => letter.lowercase)
          .toList();
      final distractors = letters.where((letter) => letter != target).toList();
      distractors.shuffle(Random(_lesson.number * 37 + index));
      final choices = <String>[target, ...distractors.take(3)];
      choices.shuffle(Random(_lesson.number * 101 + index));
      return choices;
    });
  }

  void _answerLetter(String answer) {
    if (_answeredTasks.contains(_taskIndex)) return;
    final correct = answer == _task.item;
    setState(() {
      if (correct) {
        _answeredTasks.add(_taskIndex);
      } else {
        _wrongChoices.add(answer);
      }
      _choiceFeedback =
          correct ? ReadingNarration.correctChoice : ReadingNarration.tryAgain;
      _attempts.add(ReadingEvidence(
        skill: _task.type == PhonicsActivityType.hearSoundChooseLetter
            ? PhonicsSkill.letterSound
            : PhonicsSkill.letterRecognition,
        item: _task.item,
        assistance: correct
            ? _replayed
                ? ReadingAssistance.replay
                : ReadingAssistance.none
            : ReadingAssistance.fullModel,
        method: ReadingEvidenceMethod.choice,
        correct: correct,
      ));
    });
    _speak(_choiceFeedback!);
  }

  void _recordPractice() {
    setState(() {
      _attempts.add(ReadingEvidence(
        skill: switch (_task.type) {
          PhonicsActivityType.oralBlend => PhonicsSkill.oralBlending,
          PhonicsActivityType.tryWord => PhonicsSkill.printedWordDecoding,
          _ => PhonicsSkill.printedWordBlending,
        },
        item: _task.item,
        assistance: _showSoundHint
            ? ReadingAssistance.soundHint
            : _replayed
                ? ReadingAssistance.replay
                : ReadingAssistance.none,
        method: ReadingEvidenceMethod.gesture,
        correct: false,
      ));
    });
    _speak(ReadingNarration.practiceThanks);
  }

  void _recordCaregiverObservation(bool independent) {
    setState(() {
      _attempts.add(ReadingEvidence(
        skill: PhonicsSkill.printedWordDecoding,
        item: _task.item,
        assistance: independent
            ? ReadingAssistance.none
            : _showSoundHint
                ? ReadingAssistance.soundHint
                : _replayed
                    ? ReadingAssistance.replay
                    : ReadingAssistance.fullModel,
        method: ReadingEvidenceMethod.caregiverObserved,
        correct: true,
      ));
    });
  }

  Future<void> _nextTask() async {
    if (_advancing) return;
    setState(() => _advancing = true);
    await _stop();
    if (!mounted) return;
    if (_taskIndex == _tasks.length - 1) {
      final result = ReadingLessonResult(
        attempts: List.unmodifiable(_attempts),
        completed: true,
      );
      widget.onLessonCompleted?.call(_lesson, result);
      setState(() {
        if (widget.onLessonCompleted != null) _attempts.clear();
      });
      final mediaQuery = MediaQuery.of(context);
      final celebration = ReadingNarration
          .celebrations[Random().nextInt(ReadingNarration.celebrations.length)];
      var started = false;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> playCelebration() async {
              await _speak(celebration);
              if (context.mounted) setDialogState(() {});
            }

            if (!started) {
              started = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) unawaited(playCelebration());
              });
            }
            return MediaQuery(
              data: mediaQuery,
              child: PopScope(
                canPop: false,
                child: AlertDialog(
                  title: Text(
                    'You practiced ${_lesson.letter.toUpperCase()}!',
                    textAlign: TextAlign.center,
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                            height: 180, child: _mascot(celebrating: true)),
                        const SizedBox(height: 12),
                        Text(
                          _lesson.number == alphabet.length
                              ? 'Wonderful exploring! You practiced all the letters!'
                              : 'Great exploring! Let\'s keep learning.',
                          textAlign: TextAlign.center,
                        ),
                        if (_audioError != null)
                          Text(_audioError!, textAlign: TextAlign.center),
                        TextButton.icon(
                          onPressed: playCelebration,
                          icon: const Icon(Icons.volume_up_rounded),
                          label: Text(_audioError == null
                              ? 'Hear celebration again'
                              : 'Retry celebration voice'),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    FilledButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text(_lesson.number == alphabet.length
                          ? 'Finish alphabet'
                          : 'Next letter: ${alphabet[_lesson.number].toUpperCase()}'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await _stop();
      if (!mounted) return;
      if (_lesson.number == alphabet.length) {
        Navigator.of(context).pop(ReadingLessonResult(
          attempts: List.unmodifiable(_attempts),
          completed: true,
        ));
        return;
      }
      _showLesson(phonicsLessons[_lesson.number]);
      return;
    }
    setState(() {
      _taskIndex++;
      _resetTask();
      _advancing = false;
    });
    _narrate();
  }

  void _showLesson(PhonicsLesson lesson) {
    setState(() {
      _lesson = lesson;
      _tasks = _buildTasks(lesson);
      _taskIndex = 0;
      _answeredTasks.clear();
      _choiceOrder.clear();
      _resetTask();
      _advancing = false;
    });
    _narrate();
  }

  /// Jumps to an earlier or later letter without marking this one finished.
  Future<void> _jumpToLetter(int lessonNumber) async {
    if (_advancing) return;
    await _stop();
    if (!mounted) return;
    _showLesson(phonicsLessons[lessonNumber - 1]);
  }

  void _resetTask() {
    _showSoundHint = false;
    _showBlendGuide = false;
    _replayed = false;
    _slideProgress = 0;
    _choiceFeedback = null;
    _wrongChoices.clear();
    _audioError = null;
  }

  String get _nextLabel => _taskIndex < _tasks.length - 1
      ? 'Continue'
      : _lesson.number == alphabet.length
          ? 'Finish alphabet'
          : 'Let’s learn ${alphabet[_lesson.number].toUpperCase()}!';

  String _letterNamePrompt(String letter) =>
      'This is lowercase $letter. Notice its uppercase partner '
      '${phonicsLetters[letter]!.uppercase}.';

  String _soundOf(String letter) =>
      ReadingNarration.letterSound(phonicsLetters[letter]!);

  List<String> _narrationForTask() {
    return switch (_task.type) {
      PhonicsActivityType.wordMeaning => [ReadingNarration.amMeaning],
      PhonicsActivityType.letterIntroduction => [
          ReadingNarration.introduction(phonicsLetters[_task.item]!),
          if (!ReadingNarration.introductionIncludesSound(
              phonicsLetters[_task.item]!))
            _soundOf(_task.item),
        ],
      PhonicsActivityType.hearSoundChooseLetter => [
          _task.prompt,
          _soundOf(_task.item),
        ],
      _ => [_task.prompt],
    };
  }

  @override
  Widget build(BuildContext context) {
    final letter = phonicsLetters[_task.item];
    final word = phonicsWords[_task.item];
    final isLetterIntroduction =
        _task.type == PhonicsActivityType.letterIntroduction;
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: isLetterIntroduction ? 'Finish for now' : 'Back',
          color: _ink,
          onPressed: () => Navigator.of(context).pop(ReadingLessonResult(
            attempts: List.unmodifiable(_attempts),
            completed: false,
          )),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        centerTitle: true,
        title: Text(
          'Letter ${_lesson.letter.toUpperCase()}',
          style: const TextStyle(
            color: _ink,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Center(
              child: Text(
                '${_taskIndex + 1} of ${_tasks.length}',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _MeadowFooterArt(),
          ),
          SafeArea(
            top: false,
            child: Column(
              children: [
                _progressSegments(),
                Expanded(
                  child: isLetterIntroduction && letter != null
                      ? _letterIntroductionScreen(letter)
                      : _activityBody(letter, word),
                ),
                _footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static const _background = Color(0xFFEFF8FF);
  static const _ink = Color(0xFF102354);
  static const _green = Color(0xFF2F8F4E);

  bool get _needsAnswer =>
      _task.type == PhonicsActivityType.findLetter ||
      _task.type == PhonicsActivityType.hearSoundChooseLetter;

  bool get _canContinue => !_needsAnswer || _answeredTasks.contains(_taskIndex);

  Widget _progressSegments() {
    return Semantics(
      label: 'Activity ${_taskIndex + 1} of ${_tasks.length}',
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Row(
              children: [
                for (var index = 0; index < _tasks.length; index++) ...[
                  if (index > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: index <= _taskIndex
                            ? _green
                            : const Color(0xFFD5E9D9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    final canContinue = _canContinue && !_advancing;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              _FooterArrow(
                tooltip: 'Previous letter',
                icon: Icons.chevron_left_rounded,
                onPressed: _lesson.number > 1
                    ? () => _jumpToLetter(_lesson.number - 1)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: canContinue ? _nextTask : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFAFC4B3),
                    disabledForegroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(60),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: Text(_nextLabel)),
                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right_rounded, size: 28),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FooterArrow(
                tooltip: 'Next letter',
                icon: Icons.chevron_right_rounded,
                onPressed: _lesson.number < alphabet.length
                    ? () => _jumpToLetter(_lesson.number + 1)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  (String, String) get _heading => switch (_task.type) {
        PhonicsActivityType.findLetter => (
            'Find lowercase ${_task.item}',
            'Tap the matching letter.',
          ),
        PhonicsActivityType.hearSoundChooseLetter => (
            'Which letter makes this sound?',
            _task.prompt,
          ),
        PhonicsActivityType.oralBlend => ('Listen and blend', _task.prompt),
        PhonicsActivityType.modelBlend => ('Slide the sounds', _task.prompt),
        PhonicsActivityType.guidedBlend => ('Your turn to slide', _task.prompt),
        PhonicsActivityType.wordMeaning => ('What does it mean?', _task.prompt),
        _ => ('Read the word', _task.prompt),
      };

  String get _bubbleText => _answeredTasks.contains(_taskIndex)
      ? 'Great job!'
      : _choiceFeedback == ReadingNarration.tryAgain
          ? 'Try again!'
          : 'Your turn!';

  Widget _activityBody(PhonicsLetter? letter, PhonicsWord? word) {
    final (title, subtitle) = _heading;
    final mascotHeight =
        (MediaQuery.sizeOf(context).height * 0.3).clamp(150.0, 320.0);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          key: ValueKey('reading-task-${_lesson.number}-$_taskIndex'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          children: [
            SizedBox(
              height: mascotHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Center(child: _mascot()),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _SpeechBubble(
                      text: _bubbleText,
                      semanticsLabel: _choiceFeedback,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontSize: 32,
                height: 1.1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF59627A),
                fontSize: 19,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            if (letter != null) _letterContent(letter),
            if (word != null) _wordContent(word),
            if (_task.type == PhonicsActivityType.oralBlend)
              _oralBlendContent(),
            if (_audioError != null) _voiceStatus(),
            const SizedBox(height: 16),
            Center(
              child: _HearAgainButton(
                onPressed: () {
                  _replayed = true;
                  _narrate();
                },
              ),
            ),
            if (_task.type == PhonicsActivityType.tryWord) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() => _showSoundHint = !_showSoundHint);
                  if (_showSoundHint) {
                    _speak(ReadingNarration.soundHint);
                  }
                },
                child: Text(
                    _showSoundHint ? 'Hide sound hint' : 'Hear a sound hint'),
              ),
              if (_showSoundHint) _SoundHint(hints: word!.hints),
              const SizedBox(height: 8),
              const Text(
                'Grown-up: if you heard your child read it, record what you observed.',
                textAlign: TextAlign.center,
              ),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _recordCaregiverObservation(true),
                    child: const Text('Read independently'),
                  ),
                  OutlinedButton(
                    onPressed: () => _recordCaregiverObservation(false),
                    child: const Text('Read with help'),
                  ),
                  OutlinedButton(
                    onPressed: _recordPractice,
                    child: const Text('Just practiced'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mascot({bool celebrating = false}) {
    final speaker = _speaker;
    if (speaker is BundledReadingPromptSpeaker) {
      return ValueListenableBuilder<bool>(
        valueListenable: speaker.isSpeaking,
        builder: (_, speaking, __) => _ReadingMascot(
          speaking: speaking,
          celebrating: celebrating,
        ),
      );
    }
    return _ReadingMascot(speaking: false, celebrating: celebrating);
  }

  Widget _voiceStatus() {
    return Column(
      children: [
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            _audioError!,
            key: const ValueKey('reading-voice-status'),
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          onPressed: () => _narrate(),
          child: const Text('Try voice again'),
        ),
      ],
    );
  }

  Widget _letterIntroductionScreen(PhonicsLetter letter) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final mascotHeight = (screenHeight * 0.27).clamp(180.0, 340.0);
    final letterColor = const Color(0xFF14295F);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          key: ValueKey('reading-introduction-${_lesson.number}'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          children: [
            Text(
              'Meet the letter',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: letterColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            if (_audioError != null) ...[
              _voiceStatus(),
            ],
            SizedBox(
              height: mascotHeight,
              child: Center(
                child: _mascot(),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                border: Border.all(
                  color: const Color(0xFFB9E6FF),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(44),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    letter.uppercase,
                    style: TextStyle(
                      color: letterColor,
                      fontSize: 108,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Text(
                    letter.lowercase,
                    style: TextStyle(
                      color: letterColor,
                      fontSize: 108,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LetterAudioButton(
                  label: 'Name',
                  onPressed: () {
                    _replayed = true;
                    _speak(ReadingNarration.letterName(letter));
                  },
                ),
                const SizedBox(width: 32),
                _LetterAudioButton(
                  label: 'Sound',
                  onPressed: () {
                    _replayed = true;
                    _speak(ReadingNarration.letterSound(letter));
                  },
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Text(
                'Name: ${letter.name}     Sound: ${letter.soundDescription} '
                '${letter.targetSound}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: letterColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              'As in ${letter.exampleWord}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: letterColor,
                  ),
            ),
            if (letter.educatorNote != null) ...[
              const SizedBox(height: 8),
              Text(letter.educatorNote!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  Widget _letterContent(PhonicsLetter letter) {
    final isChoice = _task.type == PhonicsActivityType.findLetter ||
        _task.type == PhonicsActivityType.hearSoundChooseLetter;
    final choices = isChoice ? _choicesFor(_taskIndex) : const <String>[];
    if (isChoice) {
      final answered = _answeredTasks.contains(_taskIndex);
      return LayoutBuilder(
        builder: (context, constraints) {
          final size = ((constraints.maxWidth - 20) / 2).clamp(96.0, 240.0);
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final choice in choices)
                _LetterChoiceCard(
                  letter: choice,
                  size: size,
                  state: answered && choice == _task.item
                      ? _ChoiceState.correct
                      : _wrongChoices.contains(choice)
                          ? _ChoiceState.wrong
                          : _ChoiceState.idle,
                  onPressed: answered ? null : () => _answerLetter(choice),
                ),
            ],
          );
        },
      );
    }
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Semantics(
              label: 'Lowercase ${letter.lowercase}',
              child: Text(
                letter.lowercase,
                style: const TextStyle(
                  fontSize: 112,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                letter.uppercase,
                style: const TextStyle(fontSize: 52, color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(_letterNamePrompt(letter.lowercase), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _speak(ReadingNarration.letterName(letter)),
          icon: const Icon(Icons.volume_up),
          label: const Text('Hear letter name'),
        ),
        OutlinedButton.icon(
          onPressed: () => _speak(ReadingNarration.letterSound(letter)),
          icon: const Icon(Icons.hearing),
          label: const Text('Hear letter sound'),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Letter name: '),
              TextSpan(
                text: letter.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: '\nSound: '),
              TextSpan(
                text: '${letter.soundDescription} ${letter.targetSound}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' as in ${letter.exampleWord}.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (letter.educatorNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              letter.educatorNote!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Widget _wordContent(PhonicsWord word) {
    final isModel = _task.type == PhonicsActivityType.modelBlend;
    final isGuided = _task.type == PhonicsActivityType.guidedBlend;
    final activeGrapheme =
        (_slideProgress * word.graphemes.length).floor().clamp(
              0,
              word.graphemes.length - 1,
            );
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < word.graphemes.length; index++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 4,
                            color: isGuided &&
                                    _showBlendGuide &&
                                    index == activeGrapheme
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Text(
                        word.graphemes[index],
                        style: const TextStyle(
                            fontSize: 76, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (isModel || _showSoundHint)
                      _SoundChip(
                        sound: _soundOf(word.graphemes[index]),
                        onPressed: () =>
                            _speak(_soundOf(word.graphemes[index])),
                      ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Pattern: ${word.pattern}'),
        if (isModel || _showSoundHint) ...[
          const SizedBox(height: 8),
          const _RecordingNotice(),
        ],
        if (isGuided) ...[
          const SizedBox(height: 12),
          const Text('Move the slider from left to right under the letters.'),
          Slider(
            value: _slideProgress,
            onChanged: (value) => setState(() => _slideProgress = value),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() => _showBlendGuide = !_showBlendGuide);
              if (_showBlendGuide) {
                _speak(ReadingNarration.slideGuide);
              }
            },
            child:
                Text(_showBlendGuide ? 'Hide slide guide' : 'Show slide guide'),
          ),
        ],
        if (_task.type == PhonicsActivityType.wordMeaning &&
            word.meaningNote != null) ...[
          const SizedBox(height: 12),
          Text(word.meaningNote!, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text(
            'Example spoken aloud: “I am happy.” The example is for meaning, not a reading test.',
            textAlign: TextAlign.center,
          ),
        ],
        if (_task.type == PhonicsActivityType.modelBlend) ...[
          const SizedBox(height: 12),
          const Text(
            'Grown-up: slide /æ/ into /m/ without a pause or extra vowel, then say “am” naturally.',
            textAlign: TextAlign.center,
          ),
        ],
        if (_task.type == PhonicsActivityType.guidedBlend) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _recordPractice,
            child: const Text('I tried the slide'),
          ),
          const Text(
            'Sliding is practice; it does not show whether the word was read.',
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _oralBlendContent() {
    final letters = _lesson.oralBlend!.split('');
    return Column(
      children: [
        const Text(
          'Grown-up: say each sound, then join them. The printed word stays hidden.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          children: [
            for (final letter in letters)
              _SoundChip(
                sound: _soundOf(letter),
                onPressed: () => _speak(_soundOf(letter)),
                large: true,
              ),
          ],
        ),
        const SizedBox(height: 8),
        const _RecordingNotice(),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _recordPractice,
          child: const Text('I listened or tried'),
        ),
      ],
    );
  }
}

class _RecordingNotice extends StatelessWidget {
  const _RecordingNotice();

  @override
  Widget build(BuildContext context) => const Text(
        'Tap a sound to hear it. A grown-up can model joining the sounds.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
      );
}

class _SoundChip extends StatelessWidget {
  const _SoundChip({
    required this.sound,
    required this.onPressed,
    this.large = false,
  });

  final String sound;
  final VoidCallback onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Hear sound $sound',
        child: TextButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.volume_up, size: 18),
          label: Text(
            sound,
            style: large ? Theme.of(context).textTheme.headlineLarge : null,
          ),
        ),
      );
}

class _LetterAudioButton extends StatelessWidget {
  const _LetterAudioButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF168BFA);
    return Semantics(
      button: true,
      label: 'Hear letter $label',
      child: Column(
        children: [
          Material(
            color: blue,
            shape: const CircleBorder(),
            elevation: 3,
            child: PressableInkWell(
              key: ValueKey('letter-audio-$label'),
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 96,
                height: 96,
                child: Icon(
                  Icons.volume_up_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF14295F),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundHint extends StatelessWidget {
  const _SoundHint({required this.hints});

  final List<String> hints;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          hints.join(' '),
          textAlign: TextAlign.center,
        ),
      );
}

const _readingInk = Color(0xFF102354);
const _readingGreen = Color(0xFF2F8F4E);

enum _ChoiceState { idle, correct, wrong }

class _LetterChoiceCard extends StatelessWidget {
  const _LetterChoiceCard({
    required this.letter,
    required this.size,
    required this.state,
    required this.onPressed,
  });

  final String letter;
  final double size;
  final _ChoiceState state;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final (fill, border) = switch (state) {
      _ChoiceState.correct => (const Color(0xFFE6F7DF), _readingGreen),
      _ChoiceState.wrong => (const Color(0xFFFFF3E6), const Color(0xFFF2A65A)),
      _ChoiceState.idle => (Colors.white, const Color(0xFFC9E7CC)),
    };
    return Semantics(
      button: true,
      label: 'Letter $letter',
      excludeSemantics: true,
      child: Material(
        color: fill,
        elevation: 2,
        shadowColor: const Color(0x2216578A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
          side: BorderSide(
            color: border,
            width: state == _ChoiceState.idle ? 2.5 : 4,
          ),
        ),
        child: PressableInkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: SizedBox(
            width: size,
            height: size * 0.92,
            child: Center(
              child: Text(
                letter,
                style: TextStyle(
                  color: _readingInk,
                  fontSize: size * 0.5,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text, this.semanticsLabel});

  final String text;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        label: semanticsLabel ?? text,
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A16578A),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: _readingInk,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 26),
              child: CustomPaint(
                size: const Size(18, 12),
                painter: _BubbleTailPainter(),
              ),
            ),
          ],
        ),
      );
}

class _BubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HearAgainButton extends StatelessWidget {
  const _HearAgainButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: PressableInkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 16, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Ink(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F5E4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A16578A),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.volume_up_rounded,
                    color: _readingGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Hear again',
                  style: TextStyle(
                    color: _readingInk,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _FooterArrow extends StatelessWidget {
  const _FooterArrow({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        iconSize: 34,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: _readingInk,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
          disabledForegroundColor: const Color(0xFFB7C2D3),
          fixedSize: const Size(60, 60),
          side: const BorderSide(color: Color(0xFFC9E7CC), width: 2),
        ),
        icon: Icon(icon),
      );
}

/// The grass and flowers from the meadow art, faded in behind the footer.
class _MeadowFooterArt extends StatelessWidget {
  const _MeadowFooterArt();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        // Only the bottom fifth of the art (grass and flowers) is shown.
        child: AspectRatio(
          aspectRatio: 768 / (1152 * 0.2),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black],
              stops: [0, 0.45],
            ).createShader(bounds),
            child: Image.asset(
              'assets/images/little_learners_meadow.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              excludeFromSemantics: true,
            ),
          ),
        ),
      );
}

class _ReadingTask {
  const _ReadingTask(this.type, this.item, this.prompt);

  final PhonicsActivityType type;
  final String item;
  final String prompt;
}

List<_ReadingTask> _buildTasks(PhonicsLesson lesson) {
  final tasks = <_ReadingTask>[];
  final letter = lesson.letter;
  tasks.add(_ReadingTask(
    PhonicsActivityType.letterIntroduction,
    letter,
    'Let’s meet the next letter.',
  ));
  if (lesson.reviewLetters.isNotEmpty) {
    tasks.add(_ReadingTask(
      PhonicsActivityType.findLetter,
      letter,
      ReadingNarration.findLetter,
    ));
    tasks.add(_ReadingTask(
      PhonicsActivityType.hearSoundChooseLetter,
      letter,
      ReadingNarration.hearSoundChooseLetter,
    ));
  }

  if (lesson.oralBlend case final blend?) {
    tasks.add(_ReadingTask(
      PhonicsActivityType.oralBlend,
      blend,
      ReadingNarration.oralBlend,
    ));
    tasks.add(const _ReadingTask(
      PhonicsActivityType.modelBlend,
      'am',
      ReadingNarration.modelBlend,
    ));
    tasks.add(const _ReadingTask(
      PhonicsActivityType.guidedBlend,
      'am',
      ReadingNarration.guidedBlend,
    ));
    tasks.add(const _ReadingTask(
      PhonicsActivityType.tryWord,
      'am',
      ReadingNarration.tryWord,
    ));
    tasks.add(const _ReadingTask(
      PhonicsActivityType.wordMeaning,
      'am',
      'Let’s talk about what am means.',
    ));
  }
  for (final text in lesson.words) {
    if (text == 'am') continue;
    final word = phonicsWords[text]!;
    tasks.add(_ReadingTask(
      PhonicsActivityType.tryWord,
      text,
      word.tryPrompt,
    ));
  }
  return tasks;
}

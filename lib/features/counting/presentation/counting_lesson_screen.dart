import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/widgets/press_feedback.dart';
import '../../listening/data/prompt_speaker.dart';
import '../../profile/presentation/dashboard_mascot.dart';
import '../../reading/data/bundled_reading_prompt_speaker.dart';
import '../../reading/domain/reading_narration.dart';
import '../domain/counting_curriculum.dart';
import '../domain/counting_narration.dart';

class CountingLessonScreen extends StatefulWidget {
  const CountingLessonScreen({
    super.key,
    required this.lesson,
    this.speaker,
    required this.onCompleted,
  });

  final CountingLesson lesson;
  final PromptSpeaker? speaker;
  final void Function(CountingLesson lesson, List<CountingEvidence> evidence)
      onCompleted;

  @override
  State<CountingLessonScreen> createState() => _CountingLessonScreenState();
}

class _CountingLessonScreenState extends State<CountingLessonScreen>
    with WidgetsBindingObserver {
  static const _ink = Color(0xFF102354);
  static const _green = Color(0xFF237F46);
  late CountingLesson _lesson = widget.lesson;
  late final PromptSpeaker _speaker =
      widget.speaker ?? BundledReadingPromptSpeaker();
  final _audioError = ValueNotifier<String?>(null);
  final _counted = <int, int>{};
  final _selected = <int>{};
  final _evidence = <CountingEvidence>[];
  int _step = 0;
  int _speechRequest = 0;
  int _builtTens = 0;
  int _builtOnes = 0;
  bool _active = true;
  bool _playing = false;
  bool _transitioning = false;
  bool _totalCorrect = false;
  bool _groupCorrect = false;
  bool _assisted = false;
  bool _rearranged = false;
  String? _feedback;

  bool get _allCounted => _counted.length == _lesson.countingUnits;
  int get _countedValue => _lesson.usesTens
      ? min(_counted.length, _lesson.tens) * 10 +
          max(0, _counted.length - _lesson.tens)
      : _counted.length;
  bool get _canContinue =>
      _step == 0 || (_step == 1 ? _totalCorrect : _groupCorrect);

  String get _prompt => switch (_step) {
        0 => _lesson.usesTens
            ? CountingNarration.meetNumber
            : CountingNarration.meet(_lesson),
        1 => _lesson.usesTens
            ? CountingNarration.countTens
            : CountingNarration.countTogether,
        _ => _lesson.usesTens
            ? CountingNarration.buildNumber
            : CountingNarration.give(_lesson),
      };

  List<String> get _promptSpeech => [
        _prompt,
        if (_lesson.usesTens && _step != 1)
          CountingNarration.number(_lesson.number),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_speak(_promptSpeech));
    });
  }

  void _reportAudio(Object error, StackTrace stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      context: ErrorDescription('while playing counting narration'),
    ));
    if (mounted) {
      _audioError.value =
          'The counting voice could not play. Check volume and tap Retry voice.';
    }
  }

  Future<void> _speak(List<String> texts) async {
    if (!mounted || !_active) return;
    final request = ++_speechRequest;
    _audioError.value = null;
    setState(() => _playing = true);
    try {
      for (final text in texts) {
        if (!mounted || !_active || request != _speechRequest) return;
        await _speaker.speak(text);
      }
    } catch (error, stack) {
      _reportAudio(error, stack);
    } finally {
      if (mounted && request == _speechRequest) {
        setState(() => _playing = false);
      }
    }
  }

  Future<void> _stop() async {
    _speechRequest++;
    if (mounted) setState(() => _playing = false);
    try {
      await _speaker.stop();
    } catch (error, stack) {
      _reportAudio(error, stack);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) unawaited(_stop());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _speechRequest++;
    unawaited(_speaker.stop().catchError((Object error, StackTrace stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('while stopping counting narration'),
      ));
    }));
    _audioError.dispose();
    super.dispose();
  }

  void _record(
      CountingSkill skill, CountingEvidenceMethod method, bool correct) {
    _evidence.add(CountingEvidence(
      number: _lesson.number,
      skill: skill,
      method: method,
      correct: correct,
      assisted: _assisted,
    ));
  }

  void _count(int id) {
    if (_playing || _transitioning || _counted.containsKey(id)) return;
    if (_lesson.usesTens &&
        id >= _lesson.tens &&
        _counted.length < _lesson.tens) return;
    setState(() => _counted[id] = _counted.length + 1);
    if (_allCounted) {
      _record(
          _lesson.usesTens
              ? CountingSkill.tensAndOnes
              : CountingSkill.countingObjects,
          _lesson.usesTens
              ? CountingEvidenceMethod.placeValue
              : CountingEvidenceMethod.objectTaps,
          true);
    }
    unawaited(_speak([
      CountingNarration.number(_countedValue),
      if (_allCounted) ...[
        if (!_lesson.usesTens) CountingNarration.total(_lesson),
        if (_lesson.usesTens) CountingNarration.starsAltogether,
        CountingNarration.howMany,
      ],
    ]));
  }

  void _chooseTotal(int number) {
    if (!_allCounted || _totalCorrect || _transitioning) return;
    final correct = number == _lesson.number;
    _record(CountingSkill.understandingTotal,
        CountingEvidenceMethod.totalChoice, correct);
    setState(() {
      _totalCorrect = correct;
      _feedback =
          correct ? CountingNarration.correctTotal : CountingNarration.tryTotal;
      if (!correct) {
        _assisted = true;
        _counted.clear();
      }
    });
    unawaited(_speak([_feedback!]));
  }

  void _toggleStar(int id) {
    if (_groupCorrect || _transitioning) return;
    setState(() {
      if (!_selected.remove(id)) _selected.add(id);
      _feedback = null;
    });
  }

  void _checkGroup() {
    if (_groupCorrect || _transitioning) return;
    final correct = _lesson.usesTens
        ? _builtTens == _lesson.tens && _builtOnes == _lesson.ones
        : _selected.length == _lesson.number;
    _record(
        CountingSkill.makingQuantity, CountingEvidenceMethod.group, correct);
    if (_lesson.usesTens) {
      _record(CountingSkill.tensAndOnes, CountingEvidenceMethod.placeValue,
          correct);
    }
    setState(() {
      _groupCorrect = correct;
      _feedback = _lesson.usesTens
          ? correct
              ? CountingNarration.correctBuild
              : CountingNarration.tryBuild
          : correct
              ? CountingNarration.correctGroup
              : CountingNarration.tryGroup;
      if (!correct) _assisted = true;
    });
    unawaited(_speak([_feedback!]));
  }

  Future<void> _next() async {
    if (!_canContinue || _transitioning) return;
    setState(() => _transitioning = true);
    await _stop();
    if (!mounted) return;
    if (_step < 2) {
      if (_step == 0) {
        _record(CountingSkill.numeralRecognition,
            CountingEvidenceMethod.guidedIntroduction, false);
      }
      setState(() {
        _step++;
        _assisted = false;
        _feedback = null;
        _transitioning = false;
      });
      unawaited(_speak(_promptSpeech));
      return;
    }
    widget.onCompleted(_lesson, List.unmodifiable(_evidence));
    final mediaQuery = MediaQuery.of(context);
    final cheer = ReadingNarration
        .celebrations[Random().nextInt(ReadingNarration.celebrations.length)];
    var started = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        if (!started) {
          started = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (dialogContext.mounted) unawaited(_speak([cheer]));
          });
        }
        return MediaQuery(
          data: mediaQuery,
          child: PopScope(
            canPop: false,
            child: AlertDialog(
              scrollable: true,
              title: Text('You practiced ${_lesson.number}!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const DashboardMascot(),
                  const Text('Wonderful counting!'),
                  _voiceControls(cheer),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(_lesson.number < countingLessons.length
                      ? 'Next number: ${_lesson.number + 1}'
                      : 'Finish counting'),
                ),
              ],
            ),
          ),
        );
      },
    );
    await _stop();
    if (!mounted) return;
    if (_lesson.number == countingLessons.length) {
      Navigator.of(context).pop();
    } else {
      _showLesson(countingLessons[_lesson.number]);
    }
  }

  void _showLesson(CountingLesson lesson) {
    setState(() {
      _lesson = lesson;
      _step = 0;
      _counted.clear();
      _selected.clear();
      _builtTens = 0;
      _builtOnes = 0;
      _evidence.clear();
      _totalCorrect = false;
      _groupCorrect = false;
      _assisted = false;
      _rearranged = false;
      _feedback = null;
      _transitioning = false;
    });
    unawaited(_speak(_promptSpeech));
  }

  Future<void> _jump(int index) async {
    if (_transitioning) return;
    setState(() => _transitioning = true);
    await _stop();
    if (mounted) _showLesson(countingLessons[index]);
  }

  Widget _voiceControls(String text, {bool includeNumber = false}) =>
      ValueListenableBuilder<String?>(
        valueListenable: _audioError,
        builder: (context, error, _) => Column(
          children: [
            if (error != null) Text(error, textAlign: TextAlign.center),
            TextButton.icon(
              onPressed: () {
                _assisted = true;
                unawaited(_speak([
                  text,
                  if (includeNumber) CountingNarration.number(_lesson.number),
                ]));
              },
              icon: const Icon(Icons.volume_up_rounded),
              label: Text(error == null ? 'Hear again' : 'Retry voice'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final heading = switch (_step) {
      0 => 'Meet number ${_lesson.number}',
      1 => _lesson.usesTens ? 'Count tens and ones' : 'Count together',
      _ => _lesson.usesTens
          ? 'Build ${_lesson.number}'
          : 'Give me ${_lesson.number} ${_lesson.number == 1 ? 'star' : 'stars'}',
    };
    return Scaffold(
      backgroundColor: const Color(0xFFEFF8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEFF8FF),
        title: const Text('Count with me'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text('${_step + 1} of 3',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    label: 'Activity ${_step + 1} of 3',
                    child: Row(
                      children: [
                        for (var index = 0; index < 3; index++)
                          Expanded(
                            child: Container(
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: index <= _step
                                    ? _green
                                    : const Color(0xFFD5E9D9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const DashboardMascot(),
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _step == 1 ? 'Let\'s count!' : _prompt,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _ink),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(heading,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: _ink)),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side:
                          const BorderSide(color: Color(0xFFC9E7CC), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('${_lesson.number}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 88,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                  color: _ink)),
                          Text(_lesson.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: _ink)),
                          const SizedBox(height: 20),
                          if (_step == 0 && _lesson.usesTens)
                            _placeValueModel(_lesson.tens, _lesson.ones)
                          else if (_step == 0)
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (var i = 0; i < _lesson.number; i++)
                                  const Icon(Icons.star_rounded,
                                      color: Color(0xFFFFC427), size: 56),
                              ],
                            )
                          else if (_step == 1)
                            _countingActivity()
                          else if (_lesson.usesTens)
                            _buildActivity()
                          else
                            _groupActivity(),
                          if (_feedback != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Semantics(
                                liveRegion: true,
                                child: Text(_feedback!,
                                    textAlign: TextAlign.center),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  _voiceControls(_prompt,
                      includeNumber: _lesson.usesTens && _step != 1),
                  if (_step == 1 && _playing)
                    const Text('Listen, then tap the next star.',
                        textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 60),
                      textStyle: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    onPressed: _canContinue && !_transitioning ? _next : null,
                    child: Text(_step < 2
                        ? 'Continue'
                        : _lesson.number < countingLessons.length
                            ? 'Let\'s learn ${_lesson.number + 1}!'
                            : 'Finish counting'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      IconButton(
                        tooltip: 'Previous number',
                        onPressed: !_transitioning && _lesson.number > 1
                            ? () => _jump(_lesson.number - 2)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded, size: 36),
                      ),
                      IconButton(
                        tooltip: 'Next number',
                        onPressed: !_transitioning &&
                                _lesson.number < countingLessons.length
                            ? () => _jump(_lesson.number)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded, size: 36),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _star(int id,
      {required bool selected,
      required bool enabled,
      required VoidCallback onTap,
      int? ordinal,
      required String label}) {
    return Semantics(
      container: true,
      button: true,
      label: label,
      selected: selected,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: Material(
        color: selected ? const Color(0xFFDDF3C8) : const Color(0xFFFFF7DC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
              color: selected ? _green : const Color(0xFFFFD65B), width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: PressableInkWell(
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 72,
            height: 82,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded,
                    color: Color(0xFFE9A900), size: 46),
                if (ordinal != null)
                  ExcludeSemantics(
                    child: Text('$ordinal',
                        textScaler: TextScaler.noScaling,
                        style: const TextStyle(
                            color: _ink, fontWeight: FontWeight.w800)),
                  ),
                if (ordinal == null && selected)
                  const Icon(Icons.check_rounded, size: 18, color: _green),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _countingActivity() {
    final ids = List.generate(_lesson.countingUnits, (index) => index);
    if (_rearranged) ids.shuffle(Random(_lesson.number));
    return Column(
      children: [
        Text(
            _lesson.usesTens
                ? 'Tap each group of ten first. Then tap the single stars.'
                : 'Tap each star once to count.',
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Wrap(
          spacing: _rearranged ? 22 : 10,
          runSpacing: _rearranged ? 22 : 10,
          alignment: WrapAlignment.center,
          children: [
            for (final id in ids)
              if (_lesson.usesTens && id < _lesson.tens)
                _tenFrame(
                  label: 'Count ten group ${id + 1}',
                  selected: _counted.containsKey(id),
                  onTap:
                      !_playing && !_transitioning && !_counted.containsKey(id)
                          ? () => _count(id)
                          : null,
                  countLabel:
                      _counted[id] == null ? null : '${_counted[id]! * 10}',
                )
              else
                _star(id,
                    selected: _counted.containsKey(id),
                    enabled: !_playing &&
                        !_transitioning &&
                        (!_lesson.usesTens ||
                            _counted.length >= _lesson.tens) &&
                        !_counted.containsKey(id),
                    onTap: () => _count(id),
                    ordinal: _counted[id] == null
                        ? null
                        : _lesson.usesTens
                            ? _lesson.tens * 10 + _counted[id]! - _lesson.tens
                            : _counted[id],
                    label:
                        'Count star ${_lesson.usesTens ? id - _lesson.tens + 1 : id + 1}'),
          ],
        ),
        if (_allCounted) ...[
          const SizedBox(height: 16),
          Text(
              _lesson.usesTens
                  ? '${_lesson.number} stars altogether.'
                  : CountingNarration.total(_lesson),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(CountingNarration.howMany, textAlign: TextAlign.center),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final number in _lesson.totalChoices)
                OutlinedButton(
                  onPressed: !_totalCorrect && !_transitioning
                      ? () => _chooseTotal(number)
                      : null,
                  child: Text('$number', semanticsLabel: 'Total $number'),
                ),
            ],
          ),
        ],
        if (_totalCorrect && !_lesson.usesTens)
          TextButton(
            onPressed: _transitioning
                ? null
                : () {
                    setState(() {
                      _counted.clear();
                      _totalCorrect = false;
                      _rearranged = !_rearranged;
                      _feedback = null;
                      _assisted = true;
                    });
                    unawaited(_speak([CountingNarration.rearrange]));
                  },
            child: const Text('Move stars and count again'),
          ),
      ],
    );
  }

  Widget _tenFrame({
    required String label,
    bool selected = false,
    VoidCallback? onTap,
    String? countLabel,
  }) =>
      Semantics(
        container: true,
        label: label,
        button: onTap != null,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: selected ? const Color(0xFFDDF3C8) : const Color(0xFFE3F1FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: selected ? _green : _ink, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: PressableInkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var row = 0; row < 2; row++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var column = 0; column < 5; column++)
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFE9A900), size: 18),
                      ],
                    ),
                  Text(countLabel ?? '10',
                      textScaler: TextScaler.noScaling,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _placeValueModel(int tens, int ones) => Column(
        children: [
          Text('$tens tens + $ones ones',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (var index = 0; index < tens; index++)
                _tenFrame(label: 'Ten-frame ${index + 1}: 10 stars'),
              for (var index = 0; index < ones; index++)
                const Icon(Icons.star_rounded,
                    color: Color(0xFFE9A900),
                    size: 40,
                    semanticLabel: 'One star'),
            ],
          ),
          if (tens == 0 && ones == 0) const Text('Add tens or ones to start.'),
        ],
      );

  void _changeBuild({int tens = 0, int ones = 0}) {
    if (_groupCorrect || _transitioning) return;
    final nextTens = _builtTens + tens;
    final nextOnes = _builtOnes + ones;
    if (nextTens < 0 || nextTens > 11 || nextOnes < 0 || nextOnes > 10) return;
    setState(() {
      _builtTens = nextTens;
      _builtOnes = nextOnes;
      _feedback = null;
    });
  }

  Widget _buildActivity() {
    final enabled = !_groupCorrect && !_transitioning;
    return Column(
      children: [
        const Text('Each full frame is ten. Each single star is one.',
            textAlign: TextAlign.center),
        const SizedBox(height: 12),
        _placeValueModel(_builtTens, _builtOnes),
        const SizedBox(height: 12),
        Text('${_builtTens * 10 + _builtOnes} stars in your group',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton(
              onPressed: enabled && _builtTens < 11
                  ? () => _changeBuild(tens: 1)
                  : null,
              child: const Text('Add ten'),
            ),
            OutlinedButton(
              onPressed: enabled && _builtTens > 0
                  ? () => _changeBuild(tens: -1)
                  : null,
              child: const Text('Remove ten'),
            ),
            OutlinedButton(
              onPressed: enabled && _builtOnes < 10
                  ? () => _changeBuild(ones: 1)
                  : null,
              child: const Text('Add one'),
            ),
            OutlinedButton(
              onPressed: enabled && _builtOnes > 0
                  ? () => _changeBuild(ones: -1)
                  : null,
              child: const Text('Remove one'),
            ),
            if (_builtOnes == 10 && _builtTens < 11)
              OutlinedButton(
                onPressed:
                    enabled ? () => _changeBuild(tens: 1, ones: -10) : null,
                child: const Text('Trade 10 ones for a ten'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: enabled ? _checkGroup : null,
          child: const Text('Check my number'),
        ),
      ],
    );
  }

  Widget _groupActivity() => Column(
        children: [
          const Icon(Icons.shopping_basket_rounded, color: _green, size: 48),
          Text('${_selected.length} in the basket',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7DF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _green, width: 2),
            ),
            child: _selected.isEmpty
                ? const Text('Your basket is empty.',
                    textAlign: TextAlign.center)
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final id in _selected)
                        _star(id,
                            selected: true,
                            enabled: !_groupCorrect && !_transitioning,
                            onTap: () => _toggleStar(id),
                            label: 'Remove star ${id + 1} from basket'),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          const Text('Tap stars to add them. Tap again to take them out.',
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (var id = 0; id < _lesson.number + 2; id++)
                if (!_selected.contains(id))
                  _star(id,
                      selected: false,
                      enabled: !_groupCorrect && !_transitioning,
                      onTap: () => _toggleStar(id),
                      label: 'Add star ${id + 1} to basket'),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _groupCorrect || _transitioning ? null : _checkGroup,
            child: const Text('Check my group'),
          ),
        ],
      );
}

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/widgets/press_feedback.dart';
import '../../listening/data/prompt_speaker.dart';
import '../../profile/presentation/dashboard_mascot.dart';
import '../../reading/data/bundled_reading_prompt_speaker.dart';
import '../../reading/domain/reading_narration.dart';
import '../domain/shapes_curriculum.dart';
import 'shape_picture.dart';

class ShapesLessonScreen extends StatefulWidget {
  const ShapesLessonScreen({
    super.key,
    required this.shape,
    required this.onCompleted,
    this.speaker,
    this.variation = 0,
  });
  final ShapeKind shape;
  final PromptSpeaker? speaker;
  final int variation;
  final ValueChanged<List<ShapeEvidence>> onCompleted;

  @override
  State<ShapesLessonScreen> createState() => _ShapesLessonScreenState();
}

class _ShapesLessonScreenState extends State<ShapesLessonScreen>
    with WidgetsBindingObserver {
  late final _speaker = widget.speaker ?? BundledReadingPromptSpeaker();
  final _audioError = ValueNotifier<String?>(null);
  final _selected = <int>{};
  final _evidence = <ShapeEvidence>[];
  final _random = Random();
  final _scroll = ScrollController();
  int _step = 0;
  int _request = 0;
  int _exploration = 0;
  bool _correct = false;
  bool _assisted = false;
  bool _playing = false;
  bool _active = true;
  bool _finishing = false;
  String? _feedback;
  late final int _variant = widget.variation + widget.shape.index;
  late final ShapeKind _other =
      ShapeKind.values[(widget.shape.index + 1 + widget.variation % 2) % 3];

  String get _prompt => switch (_step) {
        0 => ShapesNarration.meet(widget.shape),
        1 => ShapesNarration.find(widget.shape),
        _ => ShapesNarration.match(widget.shape),
      };

  List<ShapeKind> get _choices {
    final result = _step == 1
        ? [widget.shape, _other]
        : [widget.shape, _other, widget.shape];
    final shift = _variant % result.length;
    return [...result.skip(shift), ...result.take(shift)];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_speak(_prompt));
    });
  }

  void _reportAudio(Object error, StackTrace stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      context: ErrorDescription('while playing shapes narration'),
    ));
    if (mounted) {
      _audioError.value = 'The shape voice could not play. Tap Retry voice.';
    }
  }

  Future<void> _stop() async {
    _request++;
    if (mounted) setState(() => _playing = false);
    try {
      await _speaker.stop();
    } catch (error, stack) {
      _reportAudio(error, stack);
    }
  }

  Future<void> _speak(String text) async {
    if (!mounted || !_active) return;
    final request = ++_request;
    _audioError.value = null;
    setState(() => _playing = true);
    try {
      await _speaker.stop();
      if (!mounted || !_active || request != _request) return;
      await _speaker.speak(text);
    } catch (error, stack) {
      if (request == _request) _reportAudio(error, stack);
    } finally {
      if (mounted && request == _request) setState(() => _playing = false);
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
    _request++;
    unawaited(_speaker.stop().catchError((Object error, StackTrace stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('while stopping shapes narration'),
      ));
    }));
    _audioError.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _answer(bool correct) {
    _evidence.add(ShapeEvidence(
      shape: widget.shape,
      skill: _step == 1 ? ShapeSkill.recognizing : ShapeSkill.matching,
      correct: correct,
      assisted: _assisted,
    ));
    setState(() {
      _correct = correct;
      _feedback = correct
          ? (_step == 1 ? ShapesNarration.correct : ShapesNarration.matched)
          : ShapesNarration.retry;
      if (!correct) {
        _assisted = true;
        _selected.clear();
      }
    });
    unawaited(_speak(_feedback!));
  }

  Future<void> _next() async {
    if (_finishing || (_step != 0 && !_correct)) return;
    setState(() => _finishing = true);
    if (_step < 2) {
      await _stop();
      if (!mounted) return;
      if (_scroll.hasClients) _scroll.jumpTo(0);
      setState(() {
        _step++;
        _finishing = false;
        _correct = false;
        _assisted = false;
        _feedback = null;
        _selected.clear();
      });
      unawaited(_speak(_prompt));
      return;
    }
    await _stop();
    if (!mounted) return;
    final cheer = ReadingNarration
        .celebrations[_random.nextInt(ReadingNarration.celebrations.length)];
    final media = MediaQuery.of(context);
    unawaited(_speak(cheer));
    final finished = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MediaQuery(
        data: media,
        child: AlertDialog(
          scrollable: true,
          title: Text('You practiced the ${widget.shape.label}!'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const DashboardMascot(),
            Text(cheer),
            TextButton.icon(
              onPressed: () => unawaited(_speak(cheer)),
              icon: const Icon(Icons.volume_up),
              label: const Text('Hear again'),
            ),
            _voiceError(cheer),
          ]),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Back to shapes'),
            ),
          ],
        ),
      ),
    );
    await _stop();
    if (!mounted) return;
    if (finished == true) {
      widget.onCompleted(List.unmodifiable(_evidence));
      Navigator.pop(context);
    } else {
      setState(() => _finishing = false);
    }
  }

  Widget _voiceError(String text) => ValueListenableBuilder<String?>(
        valueListenable: _audioError,
        builder: (context, error, _) => error == null
            ? const SizedBox.shrink()
            : Column(children: [
                Semantics(liveRegion: true, child: Text(error)),
                TextButton(
                  onPressed: () {
                    if (_step > 0) _assisted = true;
                    unawaited(_speak(text));
                  },
                  child: const Text('Retry voice'),
                ),
              ]),
      );

  Widget _choice(int index) {
    final shape = _choices[index];
    final selected = _selected.contains(index);
    const colors = [
      Color(0xFFEF676A),
      Color(0xFF288FE0),
      Color(0xFFAA7AD9),
      Color(0xFFE4AE18),
    ];
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: '${shape.label}, choice ${index + 1}',
      excludeSemantics: true,
      onTap: _correct ? null : () => _tapChoice(index),
      child: Material(
        color: selected ? const Color(0xFFD5F1E1) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(
              color:
                  selected ? const Color(0xFF237F46) : const Color(0xFFA4DFD1),
              width: selected ? 4 : 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: PressableInkWell(
          onTap: _correct ? null : () => _tapChoice(index),
          child: SizedBox(
            width: 128,
            height: 140,
            child: Center(
              child: ShapePicture(
                shape: shape,
                color: colors[(_variant + index + _step) % colors.length],
                size: 104 - index * 16,
                rotation: shape != ShapeKind.circle && _variant.isOdd
                    ? (index.isEven ? 0.22 : -0.2)
                    : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _tapChoice(int index) {
    if (_correct || _finishing) return;
    if (_step == 1) {
      _answer(_choices[index] == widget.shape);
    } else {
      setState(() {
        if (!_selected.remove(index)) _selected.add(index);
        _feedback = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFE2F7FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE2F7FF),
          title: const Text('Shape time'),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(child: Text('${_step + 1} of 3')),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(20),
              children: [
                LinearProgressIndicator(value: (_step + 1) / 3),
                const DashboardMascot(),
                Text(
                  _step == 0
                      ? 'Meet the ${widget.shape.label}'
                      : _prompt.replaceAll('.', ''),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: const Color(0xFF102354),
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                if (_step == 0) ...[
                  Center(
                    child: Semantics(
                      label: widget.shape.label,
                      child: TweenAnimationBuilder<double>(
                        key: ValueKey(_exploration),
                        tween: Tween(begin: 0, end: _exploration > 0 ? 1 : 0),
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(seconds: 3),
                        builder: (_, outline, __) => ShapePicture(
                          shape: widget.shape,
                          color: const Color(0xFFEF676A),
                          size: 180,
                          outline: outline,
                        ),
                      ),
                    ),
                  ),
                  Text(widget.shape.description, textAlign: TextAlign.center),
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _exploration++);
                      unawaited(_speak(ShapesNarration.explore));
                    },
                    child: const Text('Explore the outline'),
                  ),
                ] else ...[
                  Text(
                    _step == 1
                        ? 'Tap the matching shape'
                        : 'Tap both matches, then check',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (var i = 0; i < _choices.length; i++) _choice(i),
                    ],
                  ),
                  if (_step == 2)
                    OutlinedButton(
                      onPressed: _correct || _selected.isEmpty
                          ? null
                          : () => _answer(_selected.length == 2 &&
                              _selected
                                  .every((i) => _choices[i] == widget.shape)),
                      child: const Text('Check my matches'),
                    ),
                ],
                if (_feedback != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(_feedback!, textAlign: TextAlign.center),
                  ),
                TextButton.icon(
                  onPressed: _playing
                      ? null
                      : () {
                          if (_step > 0) _assisted = true;
                          unawaited(_speak(_prompt));
                        },
                  icon: const Icon(Icons.volume_up),
                  label: Text(_step == 0 ? 'Hear name' : 'Hear again'),
                ),
                _voiceError(_prompt),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF237F46)),
                  onPressed: _finishing || (_step > 0 && !_correct)
                      ? null
                      : () => unawaited(_next()),
                  child: Text(_step == 2 ? 'Finish shape' : 'Continue'),
                ),
                const SizedBox(height: 24),
                const ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(Icons.grass, color: Color(0xFF237F46), size: 40),
                      Icon(Icons.local_florist,
                          color: Color(0xFF237F46), size: 32),
                      Icon(Icons.grass, color: Color(0xFF237F46), size: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

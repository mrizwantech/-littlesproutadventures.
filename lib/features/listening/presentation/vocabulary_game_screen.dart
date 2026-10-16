import 'dart:async';

import 'package:flutter/material.dart';

import '../../profile/presentation/dashboard_mascot.dart';
import '../data/prompt_speaker.dart';
import '../domain/vocabulary_round.dart';

class VocabularyGameScreen extends StatefulWidget {
  const VocabularyGameScreen({super.key, this.speaker});

  final PromptSpeaker? speaker;

  @override
  State<VocabularyGameScreen> createState() => _VocabularyGameScreenState();
}

class _VocabularyGameScreenState extends State<VocabularyGameScreen>
    with WidgetsBindingObserver {
  late final PromptSpeaker _speaker;
  int _round = 0;
  bool _answered = false;
  bool _showAnswer = false;
  bool _finished = false;
  bool _active = true;
  String? _feedback;
  String? _audioError;

  VocabularyRound get _current => vocabularyRounds[_round];
  String get _instruction => 'Tap the ${_current.target}.';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _speaker = widget.speaker ??
        NativePromptSpeaker(
            onError: (message) =>
                _reportAudio(StateError(message), StackTrace.current));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _speak("Let's find some pictures! $_instruction");
    });
  }

  void _reportAudio(Object error, StackTrace stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      context: ErrorDescription('while playing a vocabulary prompt'),
    ));
    if (mounted) {
      setState(() => _audioError =
          'Audio is unavailable. A grown-up can read the prompt, or tap Hear again to retry. Check device volume and the English speech voice.');
    }
  }

  Future<void> _speak(String text) async {
    if (!mounted || !_active) return;
    setState(() => _audioError = null);
    try {
      await _speaker.speak(text);
    } catch (error, stack) {
      _reportAudio(error, stack);
    }
  }

  Future<void> _stop() async {
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
    unawaited(_stop());
    super.dispose();
  }

  void _choose(VocabularyPicture picture) {
    if (_answered) return;
    final correct = picture.word == _current.target;
    setState(() {
      _answered = correct;
      _showAnswer = !correct;
      _feedback = correct
          ? 'You found the ${_current.target}! Great exploring.'
          : "That's a ${picture.word}. Look for the highlighted ${_current.target}. Let's try together!";
    });
    _speak(_feedback!);
  }

  void _next() {
    if (!_answered) return;
    setState(() {
      if (_round == vocabularyRounds.length - 1) {
        _finished = true;
      } else {
        _round++;
        _answered = false;
        _showAnswer = false;
        _feedback = null;
      }
    });
    _speak(_finished
        ? 'Wonderful exploring! You listened and found pictures. Take a break, or play again!'
        : _instruction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FAFF),
      appBar: AppBar(
        title: const Text('Listening & Vocabulary'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Finish')),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DashboardMascot(),
                if (_finished) ...[
                  Text('Wonderful exploring!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  const Text(
                    'You listened and found pictures. Take a break, or play again!',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _round = 0;
                        _answered = false;
                        _showAnswer = false;
                        _finished = false;
                        _feedback = null;
                      });
                      _speak(_instruction);
                    },
                    child: const Text('Play again'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Back to pathway'),
                  ),
                ] else ...[
                  Text('Picture ${_round + 1} of ${vocabularyRounds.length}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(_instruction,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _speak(_feedback ?? _instruction),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: const Text('Hear again'),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth < 320
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 24) / 3;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final picture in _current.choices)
                          SizedBox(
                            width: width,
                            child: Semantics(
                              label: picture.word,
                              button: true,
                              enabled: !_answered,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: (_showAnswer || _answered) &&
                                          picture.word == _current.target
                                      ? const Color(0xFFDDF3C8)
                                      : Colors.white,
                                  padding: const EdgeInsets.all(20),
                                ),
                                onPressed:
                                    _answered ? null : () => _choose(picture),
                                child: ExcludeSemantics(
                                  child: Text(picture.emoji,
                                      style: const TextStyle(fontSize: 54)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  }),
                  if (_feedback != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(_feedback!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                  ],
                  if (_answered) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: Text(_round == vocabularyRounds.length - 1
                          ? 'Celebrate'
                          : 'Next picture'),
                    ),
                  ],
                ],
                if (_audioError != null) ...[
                  const SizedBox(height: 16),
                  Semantics(liveRegion: true, child: Text(_audioError!)),
                  if (_finished)
                    OutlinedButton(
                      onPressed: () => _speak('Wonderful exploring!'),
                      child: const Text('Retry audio'),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

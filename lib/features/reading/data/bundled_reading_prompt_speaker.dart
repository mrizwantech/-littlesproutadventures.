import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../listening/data/prompt_speaker.dart';

typedef ReadingManifestLoader = Future<String> Function(String assetPath);

abstract interface class ReadingAudioOutput {
  /// Plays a bundled asset and completes when playback ends or is stopped.
  Future<void> play(String assetPath);
  Future<void> stop();
}

/// Plays the pre-recorded Reading narration bundled with the app.
class BundledReadingPromptSpeaker implements PromptSpeaker {
  factory BundledReadingPromptSpeaker() => instance;

  BundledReadingPromptSpeaker._()
      : _output = _AudioPlayersOutput(),
        _loadManifest = rootBundle.loadString;

  @visibleForTesting
  BundledReadingPromptSpeaker.forTesting({
    required ReadingAudioOutput output,
    required ReadingManifestLoader loadManifest,
  })  : _output = output,
        _loadManifest = loadManifest;

  static final instance = BundledReadingPromptSpeaker._();

  static const audioDirectory = 'assets/audio/reading';
  static const manifestPath = '$audioDirectory/manifest.json';

  final ReadingAudioOutput _output;
  final ReadingManifestLoader _loadManifest;
  Future<Map<String, String>>? _clips;
  final ValueNotifier<bool> _isSpeaking = ValueNotifier(false);
  ValueListenable<bool> get isSpeaking => _isSpeaking;
  int _request = 0;

  /// Parses `{"clips": {"exact sentence": "file.m4a"}}`.
  @visibleForTesting
  static Map<String, String> parseManifest(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic> ||
        decoded['clips'] is! Map<String, dynamic>) {
      throw const FormatException('Reading audio manifest has no clips.');
    }
    return {
      for (final MapEntry(:key, :value)
          in (decoded['clips'] as Map<String, dynamic>).entries)
        key: value as String,
    };
  }

  Future<String> _assetFor(String text) async {
    final clips = await (_clips ??= _loadManifest(manifestPath)
        .then(parseManifest)
        .catchError((Object error) {
      _clips = null;
      throw error;
    }));
    final file = clips[text];
    if (file == null) {
      throw StateError('No bundled Reading recording for: "$text"');
    }
    return '$audioDirectory/$file';
  }

  @override
  Future<void> speak(String text) async {
    final request = ++_request;
    _isSpeaking.value = false;
    await _output.stop();
    if (request != _request) return;
    final asset = await _assetFor(text);
    if (request != _request) return;
    _isSpeaking.value = true;
    try {
      await _output.play(asset);
    } finally {
      if (request == _request) _isSpeaking.value = false;
    }
  }

  @override
  Future<void> stop() async {
    _request++;
    _isSpeaking.value = false;
    await _output.stop();
  }
}

class _AudioPlayersOutput implements ReadingAudioOutput {
  _AudioPlayersOutput()
      : _player = AudioPlayer()..audioCache = AudioCache(prefix: '');

  final AudioPlayer _player;
  Completer<void>? _completion;

  @override
  Future<void> play(String assetPath) async {
    final completion = Completer<void>();
    _completion = completion;
    final subscription = _player.onPlayerComplete.listen(
      (_) {
        if (!completion.isCompleted) completion.complete();
      },
      onError: (Object error, StackTrace stack) {
        if (!completion.isCompleted) completion.completeError(error, stack);
      },
    );
    try {
      await _player.play(AssetSource(assetPath));
      await completion.future;
    } finally {
      await subscription.cancel();
      if (identical(_completion, completion)) _completion = null;
    }
  }

  @override
  Future<void> stop() async {
    final completion = _completion;
    await _player.stop();
    if (completion != null && !completion.isCompleted) completion.complete();
  }
}

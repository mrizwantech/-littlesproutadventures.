import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract interface class PromptSpeaker {
  Future<void> speak(String text);
  Future<void> stop();
}

class NativePromptSpeaker implements PromptSpeaker {
  NativePromptSpeaker({
    required void Function(String) onError,
    FlutterTts? tts,
  }) : _tts = tts ?? FlutterTts() {
    _tts.setErrorHandler((message) => onError(message.toString()));
  }

  final FlutterTts _tts;
  Future<void>? _ready;
  int _request = 0;

  Future<void> _configure() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final result = await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        const [],
        IosTextToSpeechAudioMode.spokenAudio,
      );
      if (result != 1) {
        throw StateError(
            'The iPhone speech audio session could not be configured.');
      }
    }
    if (await _tts.isLanguageAvailable('en-US') != true) {
      throw StateError(
          'An English (United States) speech voice is unavailable.');
    }
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.42);
    await _tts.setVolume(1);
  }

  @override
  Future<void> speak(String text) async {
    final request = ++_request;
    try {
      await (_ready ??= _configure());
    } catch (_) {
      _ready = null;
      rethrow;
    }
    if (request != _request) return;
    await _tts.stop();
    if (request != _request) return;
    if (await _tts.speak(text) != 1) {
      throw StateError('The spoken prompt could not be started.');
    }
  }

  @override
  Future<void> stop() async {
    _request++;
    await _tts.stop();
  }
}

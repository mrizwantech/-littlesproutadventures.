import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:little_learners/features/listening/data/prompt_speaker.dart';

class IosAudioTts extends FlutterTts {
  int result = 1;
  IosTextToSpeechAudioCategory? category;
  IosTextToSpeechAudioMode? mode;

  @override
  Future<dynamic> setIosAudioCategory(IosTextToSpeechAudioCategory category,
      List<IosTextToSpeechAudioCategoryOptions> options,
      [IosTextToSpeechAudioMode mode =
          IosTextToSpeechAudioMode.defaultMode]) async {
    this.category = category;
    this.mode = mode;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'isLanguageAvailable' ? true : 1;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('iPhone prompts use playback audio rather than the silent-mode category',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final tts = IosAudioTts();
    final speaker = NativePromptSpeaker(onError: (_) {}, tts: tts);
    await speaker.speak('Tap the dog.');
    expect(tts.category, IosTextToSpeechAudioCategory.playback);
    expect(tts.mode, IosTextToSpeechAudioMode.spokenAudio);
    expect(calls.where((call) => call.method == 'speak'), hasLength(1));
  });

  test('iPhone audio-session failures are surfaced before speaking', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final speaker =
        NativePromptSpeaker(onError: (_) {}, tts: IosAudioTts()..result = 0);
    await expectLater(speaker.speak('Tap the dog.'), throwsStateError);
    expect(calls.where((call) => call.method == 'speak'), isEmpty);
  });

  test('Speaker configures US English once and replaces the previous prompt',
      () async {
    final speaker = NativePromptSpeaker(onError: (_) {});
    await speaker.speak('Tap the dog.');
    await speaker.speak('Tap the apple.');
    expect(calls.where((c) => c.method == 'setLanguage').single.arguments,
        'en-US');
    expect(calls.where((c) => c.method == 'stop').length, 2);
    expect(calls.where((c) => c.method == 'speak').map((c) => c.arguments),
        ['Tap the dog.', 'Tap the apple.']);
  });

  test('Stopping during voice setup prevents late speech after leaving',
      () async {
    final available = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'isLanguageAvailable') return available.future;
      return 1;
    });
    final speaker = NativePromptSpeaker(onError: (_) {});
    final speaking = speaker.speak('Tap the dog.');
    await speaker.stop();
    available.complete(true);
    await speaking;
    expect(calls.where((c) => c.method == 'speak'), isEmpty);
  });

  test('Missing voice fails explicitly and can be retried', () async {
    var available = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isLanguageAvailable') return available;
      return 1;
    });
    final speaker = NativePromptSpeaker(onError: (_) {});
    await expectLater(speaker.speak('Tap the dog.'), throwsStateError);
    available = true;
    await speaker.speak('Tap the dog.');
  });

  test('Native speech-start failures are not treated as successful audio',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isLanguageAvailable') return true;
      return call.method == 'speak' ? 0 : 1;
    });
    final speaker = NativePromptSpeaker(onError: (_) {});
    await expectLater(speaker.speak('Tap the dog.'), throwsStateError);
  });
}

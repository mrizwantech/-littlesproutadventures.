# Reading and counting narration audio

The Reading lessons play pre-recorded clips from `assets/audio/reading/`.
`manifest.json` maps each exact sentence to its clip. The clips are generated
with [Kokoro-82M](https://huggingface.co/hexgrad/Kokoro-82M) (Apache-2.0) using
the `af_heart` voice at speed 0.9.
The three `celebration_*` clips use the alternative `af_bella` voice, short
cheers ("Yay! You did it!", "Woo-hoo! Great job!", "Amazing! Way to go!"),
and speed 1.08. This aims for a brighter delivery, but Kokoro has no explicit
emotion control and the results need listening approval.
The app randomly picks one per completion pop-up;
replay uses the same phrase. These are synthesized encouragement, not sound effects.

Regenerate every clip after changing any text in
`lib/features/reading/domain/reading_narration.dart` or the letter data in
`phonics_curriculum.dart`. `flutter test` fails if a sentence has no clip.

## One-time setup (macOS)

Kokoro needs Python 3.10–3.12. Keep the virtual environment out of Git.

```sh
brew install uv
uv venv --python 3.12 ~/.kokoro-venv
uv pip install --python ~/.kokoro-venv/bin/python kokoro soundfile
```

## Regenerate

From the repository root:

```sh
dart run tool/reading_audio/export_script.dart > /tmp/reading_script.json
~/.kokoro-venv/bin/python tool/reading_audio/generate.py /tmp/reading_script.json
```

To generate only celebration clips without changing the existing lesson audio:

```sh
dart run tool/reading_audio/export_script.dart > /tmp/reading_script.json
~/.kokoro-venv/bin/python tool/reading_audio/generate.py /tmp/reading_script.json --only-prefix celebration_
```

Partial generation merges the new entries into the existing manifest. Per-clip
speed and voice overrides are recorded in `clipSpeeds` and `clipVoices`.
Regenerating a clip removes its old sentence mapping without changing other clips.

The generator prints the phonemes for every clip so pronunciation can be
checked, converts the audio to AAC `.m4a` with macOS `afconvert`, and rewrites
`manifest.json`. Letter names are written as `{a}` in the exported script and
use fixed phonemes from the `LETTER` table in `generate.py`.
Letter sounds (`sound_*` clips) use the `SOUND` table: single sounds are
misread when spoken on their own, so each is spoken at the end of a short
phrase and then cut out using Kokoro's predicted durations. Short vowels are
written as `[a]` and spoken in context ("a, a, apple.") instead of being cut.

Listen to new clips before release; they should be reviewed by an educator.

## Counting clips

The same export also includes every sentence in
`lib/features/counting/domain/counting_narration.dart`. Counting uses the same
offline player, directory, and manifest; its clips have the `counting_` prefix
and use `af_heart` at speed 0.9.

```sh
dart run tool/reading_audio/export_script.dart > /tmp/reading_script.json
~/.kokoro-venv/bin/python tool/reading_audio/generate.py /tmp/reading_script.json --only-prefix counting_
```

This preserves reading and celebration recordings. A full regeneration exports
both domains. Tests verify that every counting sentence maps to a nonempty clip.

The 1-100 expansion uses one `counting_name_*` clip per number, shared
place-value prompts, and full small-number sentences only for 1-10. To add
missing recordings without regenerating existing audio:

```sh
dart run tool/reading_audio/export_script.dart > /tmp/reading_script.json
~/.kokoro-venv/bin/python tool/reading_audio/generate.py /tmp/reading_script.json --only-prefix counting_ --missing-only
```

`--missing-only` checks exact sentence mappings and file existence; omit it to
regenerate existing clips after changing voice, speed, or pronunciation.

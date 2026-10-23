"""Generates bundled reading and counting narration with Kokoro-82M (Apache-2.0).

Run from the repository root (see tool/reading_audio/README.md):
  dart run tool/reading_audio/export_script.dart > /tmp/reading_script.json
  .venv/bin/python tool/reading_audio/generate.py /tmp/reading_script.json
"""
import json
import argparse
import pathlib
import re
import subprocess
import tempfile

import numpy as np
import soundfile as sf
from kokoro import KPipeline

VOICE = 'af_heart'
SPEED = 0.9
OUT = pathlib.Path('assets/audio/reading')

# Kokoro (misaki) phonemes for each letter *name*; plain spelling such as
# "ay" or "aych" is otherwise misread as "eye" or "eyech".
LETTER = dict(a='ˈA', b='bˈi', c='sˈi', d='dˈi', e='ˈi', f='ˈɛf', g='ʤˈi',
              h='ˈAʧ', i='ˈI', j='ʤˈA', k='kˈA', l='ˈɛl', m='ˈɛm', n='ˈɛn',
              o='ˈO', p='pˈi', q='kjˈu', r='ˈɑɹ', s='ˈɛs', t='tˈi', u='jˈu',
              v='vˈi', w='dˈʌbᵊlju', x='ˈɛks', y='wˈI', z='zˈi')

# Phonemes for each letter *sound*. Sounds that can be held are tripled
# ("mmm"); stop sounds get a short schwa ("buh"), as chosen after listening.
SOUND = dict(a='ˈæ', b='bə', c='kə', d='də', e='ˈɛ', f='fff', g='ɡə', h='hə',
             i='ˈɪ', j='ʤə', k='kə', l='lll', m='mmm', n='nnn', o='ˈɑ', p='pə',
             q='kwə', r='ɹɹɹ', s='sss', t='tə', u='ˈʌ', v='vvv', w='wə',
             x='ˈɛks', y='jə', z='zzz')
# Isolated phonemes sound wrong, so each sound is spoken at the end of this
# phrase and then cut out using Kokoro's predicted phoneme durations.
CARRIER = 'ðə sˈWnd ɪz. '


def phonemes(pipeline, speech):
    out = []
    # {x} = letter name, [x] = short-vowel sound (from SOUND).
    for i, part in enumerate(re.split(r'(\{[a-z]\}|\[[a-z]\])', speech)):
        if i % 2:
            out.append((LETTER if part[0] == '{' else SOUND)[part[1]])
            continue
        lead = part.lstrip()[:1] if part.lstrip()[:1] in '.,!?' else ''
        rest = part.lstrip()[len(lead):].strip()
        if lead:
            out.append(lead)
        if rest:
            out.append(pipeline.g2p(rest)[0])
    return re.sub(r'\s+([.,!?])', r'\1', ' '.join(out)).strip()


def letter_sound(pipeline, letter):
    sound = SOUND[letter]
    result = next(iter(pipeline.generate_from_tokens(
        CARRIER + sound + '.', voice=VOICE, speed=0.85)))
    audio, dur = result.audio.numpy(), result.pred_dur.numpy()
    samples_per_frame = len(audio) / dur.sum()
    first = 1 + len(CARRIER)  # +1 for Kokoro's start token
    start = int(dur[:first].sum() * samples_per_frame - 0.03 * 24000)
    end = int(dur[:first + len(sound)].sum() * samples_per_frame + 0.12 * 24000)
    clip = audio[max(start, 0):min(end, len(audio))].copy()
    fade = int(0.015 * 24000)
    clip[:fade] *= np.linspace(0, 1, fade)
    clip[-fade:] *= np.linspace(1, 0, fade)
    return sound, clip


def main(script_path, only_prefix=None, missing_only=False):
    entries = json.loads(pathlib.Path(script_path).read_text())
    if only_prefix:
        entries = [entry for entry in entries if entry['key'].startswith(only_prefix)]
        if not entries:
            raise ValueError(f'No clips match prefix {only_prefix!r}')
    manifest_path = OUT / 'manifest.json'
    manifest = json.loads(manifest_path.read_text()) if only_prefix else {
        'voice': f'kokoro-82m/{VOICE}', 'speed': SPEED, 'clips': {},
    }
    if missing_only:
        entries = [
            entry for entry in entries
            if manifest['clips'].get(entry['text']) != entry['key'] + '.m4a'
            or not (OUT / (entry['key'] + '.m4a')).is_file()
        ]
    if not entries:
        print('All requested clips already exist.')
        return
    pipeline = KPipeline(lang_code='a', repo_id='hexgrad/Kokoro-82M')
    OUT.mkdir(parents=True, exist_ok=True)
    if not only_prefix:
        for old in OUT.glob('*.m4a'):
            old.unlink()
    clips = manifest['clips']
    with tempfile.TemporaryDirectory() as tmp:
        for entry in entries:
            if entry['key'].startswith('sound_') and '[' not in entry['speech']:
                ps, audio = letter_sound(pipeline, entry['key'][len('sound_'):])
            else:
                ps = phonemes(pipeline, entry['speech'])
                audio = np.concatenate([
                    r.audio.numpy()
                    for r in pipeline.generate_from_tokens(
                        ps, voice=entry.get('voice', VOICE),
                        speed=entry.get('speed', SPEED))
                ])
            wav = pathlib.Path(tmp, entry['key'] + '.wav')
            sf.write(wav, audio, 24000)
            file = entry['key'] + '.m4a'
            encoded = pathlib.Path(tmp, file)
            subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '64000',
                            str(wav), str(encoded)], check=True)
            encoded.replace(OUT / file)
            for text in list(clips):
                if clips[text] == file:
                    del clips[text]
            clips[entry['text']] = file
            if 'speed' in entry:
                manifest.setdefault('clipSpeeds', {})[file] = entry['speed']
            if 'voice' in entry:
                manifest.setdefault('clipVoices', {})[file] = entry['voice']
            print(f"{entry['key']:26} {ps}")
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
    print(f'Wrote {len(clips)} clips to {OUT}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('script_path')
    parser.add_argument('--only-prefix', help='Regenerate matching clips, preserving others')
    parser.add_argument('--missing-only', action='store_true',
                        help='Generate only missing sentences/files (requires --only-prefix)')
    args = parser.parse_args()
    if args.missing_only and not args.only_prefix:
        parser.error('--missing-only requires --only-prefix')
    main(args.script_path, args.only_prefix, args.missing_only)

# Little Sprout Adventures

A clean Flutter starter app. A preparation-based splash precedes the welcome
screen.

## App identity

- Display name: **Little Sprout Adventures**
- Dart package: `little_learners`
- Android application ID and namespace: `com.rizwantech.littlelearners`
- iOS bundle ID: `com.rizwantech.littlelearners`

The iOS and Android launcher icons use the supplied sprout artwork in
`assets/branding/app_icon.png`. On macOS, regenerate all native icon sizes with
`swift tool/generate_launcher_icons.swift`. Generated icons are opaque, square
images; the operating system applies its launcher mask. The full display name
may be shortened beneath the icon by the device launcher. Stop and rebuild the
app to apply native icon changes; hot reload does not update them.

Use this identifier when registering the Android and iOS apps in Firebase.
The workspace folder name does not affect the app identity.
The internal Dart package and native identifiers are intentionally unchanged
to preserve the existing Firebase app registrations.
The welcome and Flutter splash titles use the new name as responsive Flutter
text rather than lettering baked into an image.

## Startup

The splash uses the text-free `assets/images/little_learners_meadow.png`, centered
and scaled proportionally to fill the screen edge to edge without gaps. Scenery
may be cropped, but the separate responsive AppTitle widget stays within safe
horizontal bounds. The same title widget is shared with welcome.
Flutter overlays a real animated, indeterminate progress bar and Loading text
while startup is pending. Firebase does not expose percentage progress.
The indicator disappears on failure (Retry is shown) and on successful startup.
The same artwork is included in the native iOS launch screen, with aspect-fill
layout and the same background color, so it is visible before Flutter starts.
The native launch image shows only the text-free meadow: the responsive title
and animated bar appear when Flutter starts. iOS launch screens are static.
Android's native launch screen is unchanged. Temporarily, the Flutter splash
stays visible for at least two seconds after its artwork is ready and a frame
has rendered, and longer if startup preparation is still running.
Resuming an app already in memory
does not replay the launch screen.

App composition preloads the splash image and waits for the optional
`LittleLearnersApp.prepare` async callback. Production startup initializes
Firebase and Google sign-in, then waits for Firebase's restored authentication
state. Every fresh launch shows the illustrated Mimo storytime home screen,
including when a parent session is already saved. Get Started opens Google/Apple
parent sign-in if signed out, or loads the saved child profile if signed in.
Signed-out users can also choose **Continue as guest**. A confirmation alert
explains that guest progress will not be saved; Cancel stays on sign-in and
Continue starts the guest session. Guest profile setup and activities work without
an account; the temporary profile stays only in memory, never in Firestore or the
device profile cache. No guest warning is shown on the dashboard or in profile
settings. **Leave guest mode** returns home and discards the temporary
profile; restarting the app also discards it. Signing in does not migrate a guest
profile. Reading and listening activity progress remains session-only for all
users.
Parents without a child profile complete setup. The sign-in back control returns
to home, and signing out also returns home. Resuming an app already in memory
preserves the current screen; hot restart or a new launch starts at home.

The welcome screen uses the supplied clean meadow artwork as an edge-to-edge
background. The colorful outlined title, tagline, and Get Started button
are Flutter widgets, not text baked into the image. The title approximates
the reference lettering using the system font. Controls respect safe areas and
the foreground scrolls on small screens or with large text.
Standard buttons and reading/dashboard lesson cards use a visible press-down
scale and stronger blue ink feedback. Press-down feedback starts on pointer
contact, not after a long press; release or cancellation restores the control.
Reduce Motion removes the scale animation duration. Disabled buttons do not react,
and navigation is not artificially delayed.

Parent sign-in reuses the meadow background with a readable white card.
Google uses its bundled official G artwork from
https://developers.google.com/identity/images/g-logo.png; Apple uses Flutter's
Apple icon on a black button. Neither button requires an image network request.
The two-second minimum runs concurrently with preparation, not after it.
Preparation failures are reported through
Flutter's error handler and show a Retry button.

After profile setup, the learning dashboard puts the child's avatar and
personalized greeting first instead of a large app title. Its settings button
opens profile editing and sign-out. The Reading / Explore shortcut opens a
reading lesson-selection page. Its first option,
**Letters & Sounds**, opens the existing A-Z alphabet lessons; future reading
lessons can be added alongside it. Today's Activities **Letters & Sounds**
remains a direct shortcut to those alphabet lessons,
and the separate Listening & Vocabulary card opens the picture-listening game.
That game is not part of Reading. Math and Today's Activities **Counting** open
the new counting journey. Art, Music,
the other activity cards, Library, and Progress remain clearly labeled or
announced as coming soon.
The dashboard greeting includes the supplied transparent sprout wave pose.
Flutter adds a brief gentle bob and tilt, then rests; this is whole-image motion,
not an independently rigged waving arm. The animation respects Reduce Motion.

## Ready to Read (proposed U.S. preschool pathway)

The five proposed reading stages are Story Time, Rhyme & Rhythm,
Sound Detectives, Letter Explorers, and Ready for Kindergarten. These are
organizational labels, not official school levels, a diagnostic assessment,
or a claim of government endorsement. U.S. states use different standards.
The pathway uses the preschool language/literacy domains of the
[Head Start Early Learning Outcomes Framework](https://headstart.gov/school-readiness/effective-practice-guides/language-literacy)
as its foundation. [Common Core kindergarten foundational reading standards](https://www.thecorestandards.org/ELA-Literacy/RF/K/)
are a later destination, not preschool entry requirements. This initial
The Ready to Read screen now generates a reusable letter lesson for each
letter, beginning with A and continuing in alphabetical order. The letter
name and one representative sound are shown separately. For A, the letter
name is “ay”; the first reading sound is short /æ/, as in apple. Words appear
only after all their letter-sound connections have been introduced. Current
word examples include *am*, *man*, *in*, *map*, and *sat*.

The Ready to Read screen shows the current letter (name, sound, and words to
try), how many letters have been explored, and an A–Z grid for opening any
letter. Alphabet tiles show a blue pressed background and stronger border while
touched, with visible ink feedback before opening a lesson. Cancelling a tap
restores the tile without opening it.
Each lesson screen has previous/next letter arrows in the footer, on
either side of **Continue**; jumping does not mark a letter as explored.
Activity screens show the sprout with a speech bubble, a large heading, big
letter cards, and a **Hear again** button. In tap-a-letter activities,
**Continue** stays locked until the child taps the matching letter. The child can finish a letter
lesson to open the next letter directly or stop early. The final action names the next letter; intermediate steps say
“Continue.” The sprout moves gently during speech playback and briefly
celebrates completed practice without sound effects. Completing a letter opens
a celebration pop-up that stays visible until the child chooses **Next letter**
(or **Finish alphabet** after Z). Skipping with the letter arrows does not
trigger completion or a celebration. Each pop-up plays one of three randomly
selected, short bundled cheers using the alternative Kokoro `af_bella` voice:
"Yay! You did it!", "Woo-hoo! Great job!", or "Amazing! Way to go!".
This voice has no explicit emotion control, so listening approval is still needed.
**Hear celebration again** replays the
same phrase; playback errors show a retry control. Continuing stops celebration
audio before the next letter's narration starts. Reduced-motion settings
keep it still. Letter and activity evidence is session-only and is not a mastery score
or formal reading level. This is a proposed curriculum, not an officially
validated phonics program. Educator review is needed.

Reading narration (directions, letter names, and feedback) is pre-recorded
with the open-source Kokoro-82M voice (Apache-2.0, voice `af_heart`) and
bundled in `assets/audio/reading/`, so it works offline with no network calls,
usage limits, or API keys. Letter names use explicit phonemes so "ay" and
"aych" are not misread. Each letter also has a recorded sound
(held for m, s, f, l, n, r, v, z; a short "uh" after stop sounds such as
"buh"). For short vowels (a, e, i, o, u) the introduction says the sound in context
("It sounds like a, a, apple.") and the vowel sound clips use the same phrase.
For other letters the sound plays after the introduction. Sounds also play from the **Sound**
button, in "Listen to the sound" activities, and from tappable sounds in word
and blend activities. Blended words are not recorded; a grown-up models
joining the sounds. All clips still need an educator listening review. The separate Listening & Vocabulary game continues
to use device text-to-speech and tracks listening activities separately;
picture identification does not count as word reading.
Reading has no device-voice fallback. If a clip cannot play, the lesson shows
a short error and a retry button. Every spoken sentence lives in
`lib/features/reading/domain/reading_narration.dart`; a test fails if any
sentence lacks a recording. After editing narration, regenerate the clips as
described in `tool/reading_audio/README.md`.

The suggested 5-8 minute routine is guidance, not a timer or enforced length.
Age bands in existing profiles are unchanged; age does not restrict access.
Parent readiness input and adaptive activity selection are not implemented.

## Counting: the 1-100 journey

Math / Explore and the Counting activity open the same number journey.
All **100 numbers** are playable using reusable activities, not 100 separate
screen implementations. The range selector shows ten numbers at a time
(1-10, 11-20, through 91-100).

For **1-10**, each number has three activities:

1. **Meet the number:** a large numeral, number name, and matching group of
   stars, guided by the green sprout and bundled narration.
2. **Count together:** tap each star once. It lights up and receives its spoken
   count; the next star waits until the voice finishes, so counts do not overlap.
   After counting, choose the total. A wrong total invites a recount. An optional
   **Move stars and count again** rearranges the same group to show that its
   quantity has not changed.
3. **Give me this many:** move stars from a larger collection into a basket by
   tapping, remove extras by tapping them in the basket, and check the group.
   Empty, undersized, and oversized groups receive gentle retry feedback.

For **11-100**, the same flow switches to place value:

1. **Meet the number:** numeral, name, full ten-frames, and remaining single
   stars. Each frame visibly contains two rows of five stars.
2. **Count tens and ones:** tap each ten-frame once to hear 10, 20, 30, etc.,
   then tap the remaining ones (for 32: 10, 20, 30, 31, 32). Ones wait until
   every ten-frame is counted. Choose the total from four nearby numbers.
3. **Build the number:** add/remove whole tens and single ones, then check
   both the total and its tens/ones representation. Ten ones can be traded
   for a ten. Incorrect and oversized builds receive retry feedback.

For example, 73 uses seven frames and three singles, not 73 separate taps.
100 is shown as ten tens with no remaining ones. The most demanding count
requires only 18 taps (99: nine tens and nine ones). Build controls allow
up to 11 tens and 10 ones so oversized answers can be corrected without an
unbounded collection; **Trade 10 ones for a ten** preserves the total.

Continue stays disabled until the required activity is complete. Finishing a
number shows a celebration with one of the existing three bundled cheers, then
opens the next number. Number 100 finishes the journey and returns to the
journey. Previous/next arrows allow exploration without recording completion.
Layout scrolls on small screens and with large text; controls have press feedback.

The journey keeps separate session practice evidence for counting distinct
objects, choosing a total, making a requested quantity, and practicing tens/ones,
including wrong
attempts and replay/retry assistance. Introductions are labeled guided exposure,
not evidence of independent numeral recognition. Saying the counting sequence
is **not assessed**. Grouped counting and building record place-value practice,
not individual-object counting evidence. These activities are practice,
not a validated developmental assessment or mastery score. Evidence is committed
when a number is completed; leaving early does not mark it explored. Closing the
counting journey or restarting discards its progress for guests and signed-in
users alike; there is no new cloud or device persistence.

Number-neighbor games, hundred-chart activities, counting-pattern games by 10s,
5s, and 2s, and feed-the-character/number-train games are still future work.

Counting narration uses the existing bundled audio player and shared manifest in
`assets/audio/reading/`, with `counting_*` clip names. It works offline and does
not replace the reading recordings. Errors are reported and show **Retry voice**;
backgrounding, leaving, or advancing stops speech. The new clips use Kokoro
`af_heart` and still need listening/educator review. There is one short number-name
clip per number (1-100); larger-number prompts combine reusable instructions and
those clips instead of recording hundreds of full sentences. Existing 1-10
introduction/total/group sentences are retained for natural small-number speech.

## Listening & Vocabulary

The separate dashboard activity has five familiar-picture rounds with varying
target positions. Its implementation lives in `lib/features/listening/`,
separate from `lib/features/reading/`.
The device's English (United States) text-to-speech voice speaks instructions
and feedback; children can replay prompts without needing to read. A wrong
choice names the selected picture and highlights/models the target, without
penalties, scores, or countdowns. Correct choices receive effort-focused
feedback and a child-controlled next step. Children can finish early or repeat.
Pictures currently use system emoji, whose appearance varies by platform.
Audio stops when leaving the game or backgrounding the app. Voice failures
are logged and displayed with retry and a grown-up read-aloud option; installed
voices and device volume affect playback. There is no microphone or speech
recognition. An installed voice may work offline; the app does not promise
offline availability for every device speech engine.

No learning attempts, mastery, or progress are persisted in this first game.
Exploring / Practicing / Comfortable are planned skill-specific summaries, not
labels inferred from a single correct response or completing this session.
The existing child-profile Firestore schema and rules are unchanged.

Listening & Vocabulary spoken prompts use `flutter_tts`. A full native rebuild
(not hot reload) is required after adding the plugin. Android includes its TTS
service query; iOS uses the system speech synthesizer without microphone
permission. On iOS, these prompts use the playback/spoken-audio session so
they can play in Silent Mode. Media volume and the current audio output
(including Bluetooth) still apply. Audio-session setup failures are surfaced
rather than ignored.

Firebase configuration files are intentionally excluded from Git. Before
building, download the iOS `GoogleService-Info.plist` and Android
`google-services.json` for the registered apps in Firebase Console, and place
them at `ios/Runner/GoogleService-Info.plist` and
`android/app/google-services.json`. Both apps use
`com.rizwantech.littlelearners`. These Firebase client configs are required to
build and run the app, but should not be committed to this repository.
Firebase Core, Auth, Firestore, Google Sign-In, and the
Android Google Services plugin are configured. Firebase manages
authentication credentials; the app does not copy tokens into preferences.

## Parent account and child profile

One child profile is stored at `users/{parentUid}` in the **default** Firestore
database. Fields are `nickname` (1-40 characters), `ageBand` (`2-3`, `4-5`, or
`6-7`), `avatar` (`girl` or `boy`), and `updatedAt` (server timestamp).
New and edited profiles require a Girl/Boy profile icon choice. Older profiles
without an avatar remain readable and show a neutral sprout until edited.
Publish the updated Firestore rules before using avatar-enabled profile saves;
the rules accept legacy documents but validate any supplied avatar.
The parent is identified by Firebase
Auth UID; no parent email, full child name, or birth date is copied to Firestore.
If Google and Apple use different Firebase accounts, they have different
profiles; account linking is not implemented.

Profile setup and editing show a nickname input above three selectable animal
cards for ages 2-3, 4-5, and 6-7. A blue border and check mark indicate selection;
both a nickname and age selection are required before saving. Cards use system
animal emoji, so their illustration style may vary by device.
The profile page reuses the meadow background with a soft light-green tint
behind the form for readable labels, white nickname input, and pastel age cards.

The app reads the server first and caches the nickname and age band in
account-scoped SharedPreferences on the phone. If the network is unavailable,
it displays the saved profile with an offline notice. Without a cached profile,
it shows Retry rather than assuming the parent has no profile. Permission errors
never fall back to cached data. Saves require server confirmation; a timeout
reports an unconfirmed save and may still finish remotely, so retry is idempotent.
An acknowledged profile is cached locally; explicit sign-out removes that cache.
Preferences are not encrypted and must not contain credentials. Firestore's
automatic disk persistence is disabled to avoid a second retained child cache.

### Required console / developer setup

1. Download the Firebase configuration files for the registered Android and
   iOS apps and place them at the paths above. Keep these files local; `.gitignore`
   excludes them from commits.
2. Publish `firestore.rules` in **Firebase Console > Firestore > Rules**, or
   deploy with `firebase deploy --only firestore:rules --project YOUR_PROJECT_ID`.
   The rules allow only each parent to read/write their own profile and validate
   fields and age bands. Rules are supplied locally, **not automatically deployed**.
   Review before replacing rules if the database has other apps or collections.
   Select the **(default)** database, paste the file contents, and click
   **Publish**, then tap **Retry** in the app. Do not use allow-all/test-mode
   rules for child profiles. Permission-denied errors now identify rules/access
   configuration instead of incorrectly claiming the phone has no internet.
3. Keep Google and Apple providers enabled in Firebase Authentication.
4. Register Android debug and production SHA fingerprints in Firebase.
5. Enable **Sign in with Apple** for `com.rizwantech.littlelearners` in Apple
   Developer and refresh provisioning. The entitlement is included for iOS.
6. For Apple sign-in on Android, configure the Apple Services ID, Firebase
   return URL, Team ID, Key ID, and private key in the Firebase Console only.
   Never put the Apple private key in this app. Revoke any exposed key and
   replace it in Firebase before testing.
7. Verify both providers on real devices. Google and Apple sign-in require their
   provider setup and network access; unit/widget tests use fake repositories.
This implementation supports Android and iOS. A privacy policy, parental
consent requirements, account/profile deletion UX, store child-safety disclosures,
and release signing must be addressed before public release.

## Architecture

Lightweight, feature-first clean architecture with constructor injection:

```text
lib/
  main.dart                 # Flutter entry point
  app/
    little_learners_app.dart # App configuration and composition root
  core/
    theme/
      app_theme.dart        # Shared visual configuration
  features/
    auth/
      domain/               # Parent-session contract
      data/                 # Firebase Auth and Google adapter
      presentation/         # Session routing and parent sign-in
    profile/
      domain/               # Child profile and repository contract
      data/                 # Firestore and local cache
      presentation/         # Profile setup, edit, and greeting
    splash/
      presentation/
        splash_screen.dart  # Artwork and preparation-error retry UI
    welcome/
      presentation/
        welcome_screen.dart # Widgets and UI state
      domain/               # Pure Dart business logic and contracts
      data/                 # Repository implementations and data sources
test/
  widget_test.dart
```

### Layer responsibilities

- **Presentation:** screens, widgets, and UI state. Calls domain logic rather
  than storage or network code directly.
- **Domain:** entities, repository interfaces, and use cases when needed.
  Must not import Flutter, presentation, or data implementations.
- **Data:** implements domain repository interfaces and owns serialization,
  local storage, and network access.
- **App:** creates concrete dependencies and injects them through constructors.
- **Core:** genuinely shared infrastructure and UI utilities; must not depend
  on features.

Dependencies point toward domain: presentation and data may import domain,
but domain imports neither. App composition may import all layers to wire them.
Keep features independent; put a contract in core only if it is genuinely shared.

The welcome screen has no business logic or persistence, so its domain and data
folders contain only placeholders. Add real entities, contracts, use cases, and
implementations when a feature needs them, not empty abstractions.
New features should follow the same presentation/domain/data layout.

### Testing

Mirror feature paths under `test/` as features grow. Test domain rules with
pure Dart unit tests, data implementations with fake data sources, and
presentation with widget tests and injected fake domain contracts. The current
widget tests cover startup, sign-in routing, child setup/edit, and account
switching. Real provider and Firestore integration must also be device-tested.

## Development

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

To test the Firestore rules locally with the Firebase CLI and a compatible Java
runtime installed (no access to production data):

```sh
firebase emulators:exec --only firestore --project demo-little-learners \
  'node test/firestore_rules_test.mjs'
```

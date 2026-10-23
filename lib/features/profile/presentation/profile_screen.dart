import 'package:flutter/material.dart';

import '../domain/child_profile.dart';
import '../domain/profile_repository.dart';
import 'learning_dashboard.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.parentId,
    required this.repository,
    required this.signOut,
    this.isGuest = false,
  });
  final String parentId;
  final ProfileRepository repository;
  final Future<void> Function() signOut;
  final bool isGuest;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _nickname = TextEditingController();
  AgeBand? _ageBand;
  ChildAvatar? _avatar;
  LoadedProfile? _loaded;
  bool _loading = true;
  bool _busy = false;
  bool _editing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  void _report(Object error, StackTrace stack, String message) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      context: ErrorDescription(message),
    ));
    if (mounted) {
      setState(() => _error =
          error is ProfileAccessDenied ? ProfileAccessDenied.message : message);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loaded = await widget.repository.load(widget.parentId);
      if (!mounted) return;
      setState(() {
        _loaded = loaded;
        _nickname.text = loaded.profile?.nickname ?? '';
        _ageBand = loaded.profile?.ageBand;
        _avatar = loaded.profile?.avatar;
        _editing = loaded.profile == null;
      });
    } catch (error, stack) {
      _report(error, stack,
          'Unable to load the profile. Please retry. If this continues, check the app configuration and error logs.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final profile = ChildProfile(
        nickname: _nickname.text, ageBand: _ageBand!, avatar: _avatar!);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.save(widget.parentId, profile);
      if (!mounted) return;
      setState(() {
        _loaded = LoadedProfile(profile);
        _editing = false;
      });
    } catch (error, stack) {
      _report(error, stack,
          'Save could not be confirmed. Check your connection and retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.signOut();
    } catch (error, stack) {
      _report(error, stack, 'Unable to sign out. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _loaded?.profile;
    if (!_loading && !_editing && profile != null && _error == null) {
      return LearningDashboard(
        profile: profile,
        isOffline: _loaded!.isOffline,
        onRefresh: _load,
        onSettings: () {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          setState(() => _editing = true);
        },
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFEAF6DC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFEAF6DC),
        title: const Text('Profile settings'),
        leading: profile == null
            ? null
            : BackButton(onPressed: _busy ? null : _cancelEditing),
        actions: [
          TextButton(
              onPressed: _busy || _loading ? null : _signOut,
              child: Text(widget.isGuest ? 'Leave guest mode' : 'Sign out')),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/little_learners_meadow.png',
            fit: BoxFit.cover,
            color: const Color(0xB3F3FAEB),
            colorBlendMode: BlendMode.srcOver,
            excludeFromSemantics: true,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_loaded == null)
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    )
                  else ...[
                    if (_loaded!.isOffline) ...[
                      const Text(
                          'Offline: showing the profile saved on this phone. Connect to refresh or save changes.'),
                      TextButton(
                          onPressed: _busy ? null : _load,
                          child: const Text('Refresh')),
                    ],
                    if (_editing)
                      Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Your child\'s profile',
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            const Text(
                                'A nickname is enough. Please do not enter a full name or birth date.',
                                textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nickname,
                              enabled: !_busy,
                              maxLength: 40,
                              decoration: const InputDecoration(
                                labelText: 'Child nickname',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(16)),
                                ),
                              ),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                return name.isEmpty || name.length > 40
                                    ? 'Enter a nickname with 1 to 40 characters.'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 16),
                            FormField<ChildAvatar>(
                              initialValue: _avatar,
                              validator: (value) => value == null
                                  ? 'Choose Girl or Boy for the profile icon.'
                                  : null,
                              builder: (field) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Choose a profile icon',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 16,
                                    children: [
                                      for (final avatar in ChildAvatar.values)
                                        ChoiceChip(
                                          avatar: Text(avatar.emoji),
                                          label: Text(avatar.label),
                                          selected: field.value == avatar,
                                          onSelected: _busy
                                              ? null
                                              : (_) {
                                                  field.didChange(avatar);
                                                  setState(
                                                      () => _avatar = avatar);
                                                },
                                        ),
                                    ],
                                  ),
                                  if (field.hasError)
                                    Text(field.errorText!,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Choose Your Child\'s Age',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: const Color(0xFF102354),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'We\'ll show the right activities for their stage.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            FormField<AgeBand>(
                              initialValue: _ageBand,
                              validator: (value) =>
                                  value == null ? 'Select an age band.' : null,
                              builder: (field) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final width = constraints.maxWidth < 260
                                          ? constraints.maxWidth
                                          : (constraints.maxWidth - 16) / 2;
                                      return Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 16,
                                        runSpacing: 16,
                                        children: [
                                          for (final band in AgeBand.values)
                                            SizedBox(
                                              width: width,
                                              child: _AgeCard(
                                                band: band,
                                                selected: field.value == band,
                                                onTap: _busy
                                                    ? null
                                                    : () {
                                                        field.didChange(band);
                                                        setState(() =>
                                                            _ageBand = band);
                                                      },
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                  if (field.hasError)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        field.errorText!,
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _busy ? null : _save,
                              child: Text(
                                  widget.isGuest ? 'Continue' : 'Save profile'),
                            ),
                            if (profile != null)
                              TextButton(
                                onPressed: _busy ? null : _cancelEditing,
                                child: const Text('Cancel'),
                              ),
                          ],
                        ),
                      )
                    else ...[
                      Text('Welcome, ${profile!.nickname}!',
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text('Age band: ${profile.ageBand.label}'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _editing = true),
                        child: const Text('Edit child profile'),
                      ),
                    ],
                  ],
                  if (_busy) const Center(child: CircularProgressIndicator()),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(_error!),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelEditing() {
    final profile = _loaded!.profile!;
    setState(() {
      _nickname.text = profile.nickname;
      _ageBand = profile.ageBand;
      _avatar = profile.avatar;
      _editing = false;
      _error = null;
    });
  }
}

class _AgeCard extends StatelessWidget {
  const _AgeCard({required this.band, required this.selected, this.onTap});

  final AgeBand band;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (animal, color) = switch (band) {
      AgeBand.twoToThree => ('🦁', const Color(0xFFFFF2BC)),
      AgeBand.fourToFive => ('🐸', const Color(0xFFD9F4C6)),
      AgeBand.sixToSeven => ('🦊', const Color(0xFFEBDDFF)),
    };
    return Semantics(
      button: true,
      selected: selected,
      label: band.label,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: selected ? const Color(0xFF167DC4) : Colors.transparent,
            width: 3,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ExcludeSemantics(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(animal, style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    band.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF102354),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected
                        ? const Color(0xFF167DC4)
                        : const Color(0xFF536579),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum AgeBand {
  twoToThree('2-3', '2-3 years'),
  fourToFive('4-5', '4-5 years'),
  sixToSeven('6-7', '6-7 years');

  const AgeBand(this.id, this.label);
  final String id;
  final String label;
}

enum ChildAvatar {
  girl('girl', 'Girl', '👧'),
  boy('boy', 'Boy', '👦');

  const ChildAvatar(this.id, this.label, this.emoji);
  final String id;
  final String label;
  final String emoji;
}

class ChildProfile {
  ChildProfile({required String nickname, required this.ageBand, this.avatar})
      : nickname = nickname.trim() {
    if (this.nickname.isEmpty || this.nickname.length > 40) {
      throw ArgumentError('Nickname must contain 1 to 40 characters.');
    }
  }

  final String nickname;
  final AgeBand ageBand;
  final ChildAvatar? avatar;
}

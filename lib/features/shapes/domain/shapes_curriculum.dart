enum ShapeKind {
  circle('circle', 'It is round, with no straight sides or corners.'),
  square('square', 'It has four equal straight sides and four corners.'),
  triangle('triangle', 'It has three straight sides and three corners.');

  const ShapeKind(this.label, this.description);
  final String label;
  final String description;
}

enum ShapeSkill { recognizing, matching, describing }

class ShapeEvidence {
  const ShapeEvidence({
    required this.shape,
    required this.skill,
    required this.correct,
    required this.assisted,
  });

  final ShapeKind shape;
  final ShapeSkill skill;
  final bool correct;
  final bool assisted;
}

abstract final class ShapesNarration {
  static String meet(ShapeKind shape) =>
      'This is a ${shape.label}. ${shape.description}';
  static String find(ShapeKind shape) => 'Find the ${shape.label}.';
  static String match(ShapeKind shape) => 'Find both ${shape.label}s.';
  static const correct = 'You found it! Great shape spotting!';
  static const matched = 'Both shapes match! Great job!';
  static const retry = 'Look at the sides and corners. Try again.';
  static const explore = 'Follow the outline. Look at the sides and corners.';
  static Map<String, String> get all => {
        for (final shape in ShapeKind.values) ...{
          'shapes_meet_${shape.name}': meet(shape),
          'shapes_find_${shape.name}': find(shape),
          'shapes_match_${shape.name}': match(shape),
        },
        'shapes_correct': correct,
        'shapes_matched': matched,
        'shapes_retry': retry,
        'shapes_explore': explore,
      };
}

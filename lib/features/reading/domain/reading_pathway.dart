class ReadingStage {
  const ReadingStage(this.title, this.goal, this.examples, this.framework);

  final String title;
  final String goal;
  final String examples;
  final String framework;
}

const readingStages = [
  ReadingStage(
    'Story Time',
    'Enjoy books and talk about characters and events.',
    'Listen together, point to pictures, and retell a familiar moment.',
    'Head Start ELOF: comprehension and text structure; print and alphabet knowledge.',
  ),
  ReadingStage(
    'Rhyme & Rhythm',
    'Notice patterns in spoken language.',
    'Explore rhyming words and clap the syllables in a name.',
    'Head Start ELOF: phonological awareness.',
  ),
  ReadingStage(
    'Sound Detectives',
    'Explore the beginning sounds in spoken words.',
    'Listen for words that start with the same sound.',
    'Head Start ELOF: phonological awareness.',
  ),
  ReadingStage(
    'Letter Explorers',
    'Connect familiar letters with their names and sounds.',
    "Start with letters in the child's name and a few meaningful words.",
    'Head Start ELOF: print and alphabet knowledge.',
  ),
  ReadingStage(
    'Ready for Kindergarten',
    'Revisit early skills through playful practice, when ready.',
    'Retell with pictures, review letters, and try oral sound blending together.',
    'Bridge toward kindergarten: Common Core RF.K.1-3 and RL.K.1-3, not preschool entry requirements.',
  ),
];

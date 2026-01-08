class Flashcard {
  final String id;
  final String description;
  final List<String> sequence; // e.g., ['d', 'a', 'p'] or ['<C-v>']

  const Flashcard({
    required this.id,
    required this.description,
    required this.sequence,
  });
}

final List<Flashcard> mockFlashcards = [
  const Flashcard(
    id: '1',
    description: 'Delete Around Paragraph',
    sequence: ['d', 'a', 'p'],
  ),
  const Flashcard(
    id: '2',
    description: 'Change Inside Quotes',
    sequence: ['c', 'i', '"'],
  ),
  const Flashcard(
    id: '3',
    description: 'Yank to End of File',
    sequence: ['y', 'G'],
  ),
  const Flashcard(
    id: '4',
    description: 'Visual Block Mode',
    sequence: ['<C-v>'],
  ),
  const Flashcard(
    id: '5',
    description: 'Save and Quit',
    sequence: [':', 'w', 'q'],
  ),
  const Flashcard(
    id: '6',
    description: 'Delete to End of Line',
    sequence: ['D'],
  ),
];

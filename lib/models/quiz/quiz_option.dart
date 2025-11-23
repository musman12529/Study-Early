import 'package:uuid/uuid.dart';

class QuizOption {
  final String id;
  final String text;
  final bool isCorrect;

  QuizOption({String? id, required this.text, required this.isCorrect})
    : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {'id': id, 'text': text, 'isCorrect': isCorrect};
  }

  static QuizOption fromMap(Map<String, dynamic> map) {
    return QuizOption(
      id: map['id'],
      text: map['text'],
      isCorrect: map['isCorrect'] ?? false,
    );
  }

  QuizOption copyWith({String? text, bool? isCorrect}) {
    return QuizOption(
      id: id,
      text: text ?? this.text,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}

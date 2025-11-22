import 'package:uuid/uuid.dart';
import 'quiz_option.dart';

class QuizQuestion {
  final String id;
  final String prompt;
  final List<QuizOption> options;
  final bool multipleCorrectAllowed;
  final String? explanation;

  QuizQuestion({
    String? id,
    required this.prompt,
    required this.options,
    this.multipleCorrectAllowed = false,
    this.explanation,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'prompt': prompt,
      'options': options.map((o) => o.toMap()).toList(),
      'multipleCorrectAllowed': multipleCorrectAllowed,
      'explanation': explanation,
    };
  }

  static QuizQuestion fromMap(Map<String, dynamic> map) {
    final rawOptions = (map['options'] as List<dynamic>? ?? []);
    return QuizQuestion(
      id: map['id'],
      prompt: map['prompt'],
      options: rawOptions
          .map((o) => QuizOption.fromMap((o as Map<String, dynamic>)))
          .toList(),
      multipleCorrectAllowed: map['multipleCorrectAllowed'] ?? false,
      explanation: map['explanation'],
    );
  }

  QuizQuestion copyWith({
    String? prompt,
    List<QuizOption>? options,
    bool? multipleCorrectAllowed,
    String? explanation,
  }) {
    return QuizQuestion(
      id: id,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      multipleCorrectAllowed:
          multipleCorrectAllowed ?? this.multipleCorrectAllowed,
      explanation: explanation ?? this.explanation,
    );
  }
}

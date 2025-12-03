import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../models/quiz/quiz.dart';
import '../models/quiz/quiz_question.dart';

Future<Uint8List> buildQuizPdf(Quiz quiz) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return [
          pw.Text(
            quiz.title,
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${quiz.numQuestions} questions - Difficulty: ${quiz.difficulty.asString}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          ..._buildQuestionList(quiz.questions, showAnswers: false),
        ];
      },
    ),
  );
  return doc.save();
}

Future<Uint8List> buildAnswersPdf(Quiz quiz) async {
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return [
          pw.Text(
            '${quiz.title} - Answer Key',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${quiz.numQuestions} questions - Difficulty: ${quiz.difficulty.asString}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),
          ..._buildQuestionList(quiz.questions, showAnswers: true),
        ];
      },
    ),
  );
  return doc.save();
}

List<pw.Widget> _buildQuestionList(
  List<QuizQuestion> questions, {
  required bool showAnswers,
}) {
  final items = <pw.Widget>[];
  for (int i = 0; i < questions.length; i++) {
    final q = questions[i];
    items.add(
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Q${i + 1}. ${q.prompt}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              for (final opt in q.options)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 10,
                        height: 10,
                        margin: const pw.EdgeInsets.only(right: 6, top: 2),
                        decoration: pw.BoxDecoration(
                          color: showAnswers && opt.isCorrect
                              ? PdfColors.black
                              : null,
                          border: pw.Border.all(width: 1),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          opt.text,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: showAnswers && opt.isCorrect
                                ? pw.FontWeight.bold
                                : pw.FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (showAnswers && (q.explanation?.trim().isNotEmpty ?? false)) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              'Explanation:',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(q.explanation!, style: const pw.TextStyle(fontSize: 11)),
          ],
          pw.SizedBox(height: 14),
        ],
      ),
    );
  }
  return items;
}

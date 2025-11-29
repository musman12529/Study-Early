import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuizGenerationOptionsDialog extends StatefulWidget {
  const QuizGenerationOptionsDialog({super.key});

  @override
  State<QuizGenerationOptionsDialog> createState() =>
      _QuizGenerationOptionsDialogState();
}

class _QuizGenerationOptionsDialogState
    extends State<QuizGenerationOptionsDialog> {
  final TextEditingController _numController = TextEditingController(text: '5');
  final TextEditingController _instructionsController = TextEditingController();

  String _difficulty = 'Mixed';
  bool _includeExplanations = true;
  double _temperature = 0.5;

  int? _parsedNumQuestions = 5;
  String? _errorText;

  @override
  void dispose() {
    _numController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Quiz generation options'),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Number of Questions
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Number of questions',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _numController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'Enter a number from 1 to 20',
                  errorText: _errorText,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  final n = int.tryParse(value);
                  setState(() {
                    if (n == null || n < 1 || n > 20) {
                      _errorText = 'Enter a number from 1 to 20';
                      _parsedNumQuestions = null;
                    } else {
                      _errorText = null;
                      _parsedNumQuestions = n;
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Max 20 questions',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),

              const SizedBox(height: 16),

              // Custom Instructions / Focus Areas
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Custom Instructions / Focus Areas',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _instructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText:
                      'E.g., Emphasize definitions, prioritise chapters 3–4, focus on proofs…',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              const SizedBox(height: 16),

              // Difficulty Level
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Difficulty level',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _difficulty,
                items: const [
                  DropdownMenuItem(value: 'Easy', child: Text('Easy')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'Hard', child: Text('Hard')),
                  DropdownMenuItem(value: 'Mixed', child: Text('Mixed')),
                ],
                onChanged: (v) => setState(() => _difficulty = v ?? 'Mixed'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              const SizedBox(height: 8),

              // Include Explanations
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Include explanations'),
                value: _includeExplanations,
                onChanged: (v) => setState(() => _includeExplanations = v),
              ),

              const SizedBox(height: 8),

              // Temperature
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Temperature',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Slider(
                value: _temperature,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: _temperature.toStringAsFixed(2),
                onChanged: (v) => setState(() => _temperature = v),
              ),
              const SizedBox(height: 0),
              Row(
                children: const [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'More\nStrict',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Balanced',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'More\nCreative',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<int?>(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _parsedNumQuestions == null
              ? null
              : () => Navigator.pop<int>(context, _parsedNumQuestions),
          child: const Text('Generate'),
        ),
      ],
    );
  }
}

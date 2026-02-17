import 'package:flutter/material.dart';
import 'database_helper.dart';

class FlashcardListPage extends StatefulWidget {
  const FlashcardListPage({
    super.key,
    required this.topicId,
    required this.topicName,
  });

  final int topicId;
  final String topicName;

  @override
  State<FlashcardListPage> createState() => _FlashcardListPageState();
}

class _FlashcardListPageState extends State<FlashcardListPage> {
  List<Map<String, Object?>> _qna = <Map<String, Object?>>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQnA();
  }

  Future<void> _loadQnA() async {
    final List<Map<String, Object?>> rows =
        await DatabaseHelper.instance.getQnAForTopic(widget.topicId);

    if (!mounted) {
      return;
    }

    setState(() {
      _qna = rows;
      _isLoading = false;
    });
  }

  Future<void> _showAddFlashcardDialog() async {
    final TextEditingController questionController = TextEditingController();
    final TextEditingController answerController = TextEditingController();

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add Flashcard'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: questionController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Enter question',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: answerController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Enter answer',
                ),
                onSubmitted: (_) => Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    final String question = questionController.text.trim();
    final String answer = answerController.text.trim();

    if (shouldSave == true && question.isNotEmpty && answer.isNotEmpty) {
      await DatabaseHelper.instance.insertQnA(
        topicId: widget.topicId,
        question: question,
        answer: answer,
      );
      await _loadQnA();
    }

    questionController.dispose();
    answerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicName),
        actions: <Widget>[
          IconButton(
            onPressed: _showAddFlashcardDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add flashcard',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _qna.isEmpty
              ? const Center(
                  child: Text('No questions yet. Tap + to add one.'),
                )
              : ListView.separated(
                  itemCount: _qna.length,
                  padding: const EdgeInsets.all(12),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, Object?> row = _qna[index];
                    final String question = row['question'] as String? ?? '';
                    final String answer = row['answer'] as String? ?? '';

                    return Card(
                      child: ListTile(
                        title: Text(question),
                        subtitle: answer.isEmpty ? null : Text(answer),
                      ),
                    );
                  },
                ),
    );
  }
}

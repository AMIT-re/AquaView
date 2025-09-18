import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      setState(() => _submitted = true);
      // Here you could send feedback to a server or save it
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report & Feedback')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _submitted
            ? const Center(child: Text('Thank you for your feedback!'))
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Let us know your issue or feedback:', style: TextStyle(fontSize: 18)),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _controller,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Describe your issue or feedback...',
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Please enter some feedback'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

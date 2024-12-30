import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voyagers/screens/moments_page.dart';
import '../database_helper.dart';

class ViewMomentPage extends StatefulWidget {
  const ViewMomentPage({super.key});

  @override
  _ViewMomentPageState createState() => _ViewMomentPageState();
}

class _ViewMomentPageState extends State<ViewMomentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feelingsController = TextEditingController();
  final _idealController = TextEditingController();
  int _intensity = 5;

  Future<void> _saveMoment() async {
    if (_formKey.currentState!.validate()) {
      try {
        String today = DateFormat('yyyyMMdd').format(DateTime.now());
        
        await DatabaseHelper.instance.addMoment(
          _titleController.text,
          today,
          'open',
          _descriptionController.text,
          _feelingsController.text,
          _idealController.text,
          _intensity.toString(),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MomentsPage()),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _feelingsController.dispose();
    _idealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Moment'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 80.0, // Add padding at bottom for the fixed button
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null, // Allows the field to expand
                    keyboardType: TextInputType.multiline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    minLines: 3,
                    keyboardType: TextInputType.multiline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _feelingsController,
                    decoration: const InputDecoration(
                      labelText: 'Feelings',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    minLines: 2,
                    keyboardType: TextInputType.multiline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your feelings';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _idealController,
                    decoration: const InputDecoration(
                      labelText: 'Ideal Outcome',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    minLines: 2,
                    keyboardType: TextInputType.multiline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the ideal outcome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _intensity,
                    decoration: const InputDecoration(
                      labelText: 'Intensity',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(10, (index) => index + 1)
                        .map((int value) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _intensity = newValue;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select an intensity level';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveMoment,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Save Moment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
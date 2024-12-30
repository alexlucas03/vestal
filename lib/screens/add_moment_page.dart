import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../widgets/models/moment.dart';

class AddMomentPage extends StatefulWidget {
  final Moment? moment;

  const AddMomentPage({super.key, this.moment});

  @override
  _AddMomentPageState createState() => _AddMomentPageState();
}

class _AddMomentPageState extends State<AddMomentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _feelingsController = TextEditingController();
  final _idealController = TextEditingController();
  int _intensity = 5;

  @override
  void initState() {
    super.initState();
    if (widget.moment != null) {
      _titleController.text = widget.moment!.title;
      _descriptionController.text = widget.moment!.description;
      _feelingsController.text = widget.moment!.feelings;
      _idealController.text = widget.moment!.ideal;
      // Safely parse the intensity string to int
      _intensity = int.tryParse(widget.moment!.intensity) ?? 5;
    }
  }

  Future<void> _saveMoment() async {
    if (_formKey.currentState!.validate()) {
      try {
        String today = DateFormat('yyyyMMdd').format(DateTime.now());
        
        if (widget.moment != null) {
          // Update existing moment
          await DatabaseHelper.instance.updateMoment(
            widget.moment!.id!,
            _titleController.text,
            widget.moment!.status,
            _descriptionController.text,
            _feelingsController.text,
            _idealController.text,
            _intensity.toString(),
          );
        } else {
          // Add new moment
          await DatabaseHelper.instance.addMoment(
            _titleController.text,
            today,
            'open',
            _descriptionController.text,
            _feelingsController.text,
            _idealController.text,
            _intensity.toString(),
          );
        }

        if (mounted) {
          Navigator.pop(context, true);
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
        title: Text(widget.moment != null ? 'Edit Moment' : 'Add Moment'),
      ),
      // Rest of the build method remains the same
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 80.0,
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
                    maxLines: null,
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(widget.moment != null ? 'Update Moment' : 'Save Moment'),
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
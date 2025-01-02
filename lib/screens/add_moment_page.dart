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
  String _status = 'Open';
  String _type = 'good';
  final _descriptionController = TextEditingController();
  final _feelingsController = TextEditingController();
  final _idealController = TextEditingController();
  int? _intensity;

  @override
  void initState() {
    super.initState();
    if (widget.moment != null) {
      _titleController.text = widget.moment!.title;
      _descriptionController.text = widget.moment!.description;
      _feelingsController.text = widget.moment!.feelings;
      _idealController.text = widget.moment!.ideal;
      _status = widget.moment!.status[0].toUpperCase() + widget.moment!.status.substring(1);
      _intensity = widget.moment!.intensity.isEmpty ? null : int.parse(widget.moment!.intensity);
      _type = widget.moment!.type;
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
            _status.toLowerCase(),
            _descriptionController.text,
            _feelingsController.text,
            _idealController.text,
            _intensity?.toString() ?? '',
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
            _intensity?.toString() ?? '',
            _type,
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

  Future<void> _removeMoment() async {
    if (widget.moment != null) {
      try {
        await DatabaseHelper.instance.removeMoment(widget.moment!.id!);

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
  Future<void> _sendMoment(Moment moment) async {
    try {
      String? userCode = await DatabaseHelper.instance.getUserCode();
      if (userCode == null) {
        throw Exception('User code not found');
      }
      await DatabaseHelper.instance.cloudAddMoment(moment, userCode);
    } catch (e) {
      print('Error sending moment: $e');
      rethrow;
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
    final bool isGoodMoment = widget.moment?.type == 'good' || (widget.moment?.type != null && _type == 'good');

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        centerTitle: true,
        title: Text(widget.moment != null ? 'Edit Moment' : 'Add Moment'),
        actions: [
          if (widget.moment != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _removeMoment,
              color: Colors.white,
            ),
          if (widget.moment != null)
            IconButton(
              icon: const Icon(Icons.send_rounded),
              onPressed: () async {
                try {
                  String? userCode = await DatabaseHelper.instance.getUserCode();
                  if (userCode == null) {
                    throw Exception('User code not found');
                  }

                  final moment = Moment(
                    title: _titleController.text,
                    date: widget.moment?.date ?? DateFormat('yyyyMMdd').format(DateTime.now()),
                    status: _status.toLowerCase(),
                    description: _descriptionController.text,
                    feelings: _feelingsController.text,
                    ideal: _idealController.text,
                    intensity: _intensity?.toString() ?? '',
                    type: _type,
                    owner: userCode,  // Use the actual userCode
                  );
                  
                  await _sendMoment(moment);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Moment shared successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error sharing moment: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              color: Colors.white,
            ),
        ],
      ),
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
                      labelText: 'Title*',
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
                  if (widget.moment == null) ...[
                    DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type*',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'good',
                          child: Text('Good'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'bad',
                          child: Text('Bad'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _type = newValue;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (!isGoodMoment && _type.toLowerCase() != 'good') 
                    DropdownButtonFormField<String>(
                      value: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status*',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'Open',
                          child: Text('Open'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Closed',
                          child: Text('Closed'),
                        ),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _status = newValue;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a status';
                        }
                        return null;
                      },
                    ),
                  if (!isGoodMoment && _type.toLowerCase() != 'good') 
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
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int?>(
                    value: _intensity,
                    decoration: const InputDecoration(
                      labelText: 'Intensity',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Not specified'),
                      ),
                      ...List.generate(10, (index) => index + 1)
                          .map((int value) {
                        return DropdownMenuItem<int?>(
                          value: value,
                          child: Text(value.toString()),
                        );
                      }).toList(),
                    ],
                    onChanged: (int? newValue) {
                      setState(() {
                        _intensity = newValue;
                      });
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
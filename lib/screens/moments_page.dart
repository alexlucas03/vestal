import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voyagers/screens/add_moment_page.dart';
import '../database_helper.dart';
import '../widgets/models/moment.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  _MomentsPageState createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> {
  List<Map<String, dynamic>> _moments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    try {
      final moments = await DatabaseHelper.instance.queryAllMoments();
      if (mounted) {
        setState(() {
          _moments = moments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('Error loading moments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading moments: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(String dateString) {
    try {
      String formattedString = '${dateString.substring(0, 4)}-${dateString.substring(4, 6)}-${dateString.substring(6, 8)}';
      final date = DateTime.parse(formattedString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      print('Error formatting date: $e');
      return dateString;
    }
  }

  Future<void> _navigateToAddMoment([Map<String, dynamic>? momentMap]) async {
    final route = MaterialPageRoute(
      builder: (context) => AddMomentPage(
        moment: momentMap != null ? Moment.fromMap(momentMap) : null,
      ),
    );
    
    final result = await Navigator.push(context, route);
    
    if (result == true) {
      _loadMoments(); // Reload the list if changes were made
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Moments Journal'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moments Journal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: _moments.isEmpty
                ? const Center(
                    child: Text(
                      'No moments recorded yet',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView.builder(
                    itemCount: _moments.length,
                    itemBuilder: (context, index) {
                      final moment = _moments[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: InkWell(
                          onTap: () => _navigateToAddMoment(moment),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    moment['title']?.toString() ?? 'Untitled',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDate(moment['date']?.toString() ?? ''),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
            ),
            ElevatedButton(
              onPressed: () => _navigateToAddMoment(),
              child: const Text('Add Moment'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
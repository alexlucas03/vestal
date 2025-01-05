import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vestal/screens/add_moment_page.dart';
import '../database_helper.dart';
import '../widgets/models/moment.dart';

class MomentsPage extends StatefulWidget {
  const MomentsPage({super.key});

  @override
  _MomentsPageState createState() => _MomentsPageState();
}

class _MomentsPageState extends State<MomentsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  List<Map<String, dynamic>> _moments = [];
  List<Map<String, dynamic>> _archivedMoments = [];
  bool _isLoading = true;
  bool _showArchive = false;
  String? _userCode;

  @override
  void initState() {
    super.initState();
    _loadMoments();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadMoments() async {
    try {
      _userCode = await DatabaseHelper.instance.getUserCode();
      List<Map<String, dynamic>> moments = await DatabaseHelper.instance.getAllMomentData();

      if (mounted) {
        setState(() {
          // Separate active and archived moments
          _moments = moments.where((moment) => 
            !(moment['type']?.toString().toLowerCase() == 'bad' && 
              moment['status']?.toString().toLowerCase() == 'closed')).toList();
          
          _archivedMoments = moments.where((moment) => 
            moment['type']?.toString().toLowerCase() == 'bad' && 
            moment['status']?.toString().toLowerCase() == 'closed').toList();
          
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
      if (mounted && context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading moments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Widget _buildMomentCard(Map<String, dynamic> moment, {bool isArchived = false}) {
    final momentType = moment['type']?.toString() ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      elevation: 4,
      shadowColor: isArchived 
          ? Colors.grey
          : momentType.toLowerCase() == 'good' 
              ? Colors.green
              : momentType.toLowerCase() == 'bad'
                  ? Colors.red
                  : Colors.grey,
      child: InkWell(
        onTap: () => _navigateToAddMoment(moment),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  moment['title'].toString(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: moment['owner']?.toString() == _userCode
                        ? const Color(0xFF222D49)
                        : Colors.pink,
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
          title: const Text('Moments Journal'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        title: const Text('Moments Journal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: _moments.isEmpty && _archivedMoments.isEmpty
                ? const Center(
                    child: Text(
                      'No moments recorded yet',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : ListView(
                    children: [
                      ..._moments.map((moment) => _buildMomentCard(moment)),
                      if (_archivedMoments.isNotEmpty) ...[
                        Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                          elevation: 4,
                          shadowColor: Colors.grey,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _showArchive = !_showArchive;
                                if (_showArchive) {
                                  _controller.forward();
                                } else {
                                  _controller.reverse();
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Archive',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Icon(
                                    _showArchive 
                                        ? Icons.keyboard_arrow_up 
                                        : Icons.keyboard_arrow_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizeTransition(
                          sizeFactor: _animation,
                          axisAlignment: -1.0,
                          child: Container(
                            clipBehavior: Clip.none,
                            child: Column(
                              children: _archivedMoments.map(
                                (moment) => _buildMomentCard(moment, isArchived: true),
                              ).toList(),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
            ),
            ElevatedButton(
              onPressed: () => _navigateToAddMoment(),
              style: ElevatedButton.styleFrom(
                foregroundColor: Color(0xFF222D49),
              ),
              child: const Text('Add Moment'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
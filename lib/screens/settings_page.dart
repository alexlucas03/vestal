import 'package:flutter/material.dart';
import '../database_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? userCode;
  String? partnerCode;
  bool _isLoading = false;
  bool _isPinkColor = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final code = await DatabaseHelper.instance.getUserCode();
      final pCode = await DatabaseHelper.instance.getPartnerCode();
      final isPink = await DatabaseHelper.instance.getColorPreference();  // Add this line
      if (!mounted) return;
      setState(() {
        userCode = code;
        partnerCode = pCode;
        _isPinkColor = isPink;  // Add this line
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createPartnerTable(String partnerCode, String userCode) async {
    await DatabaseHelper.instance.createPartnerTable(partnerCode, userCode);
  }

  void _showPartnerCodeDialog(BuildContext context) {
    // Create a StatefulBuilder to manage dialog state
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final TextEditingController dialogController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enter Partner\'s Code'),
              content: TextField(
                controller: dialogController,
                maxLength: 6,
                decoration: const InputDecoration(
                  hintText: 'Enter 6-digit code',
                  border: OutlineInputBorder(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final code = dialogController.text;
                    if (code.length == 6) {
                      try {
                        await DatabaseHelper.instance.storePartnerCode(code);
                        if (!mounted) return;
                        
                        // Get the current user code
                        final userCode = await DatabaseHelper.instance.getUserCode();
                        if (userCode != null) {
                          // Create partner table with the submitted code and user code
                          await _createPartnerTable(code, userCode);
                        }
                        
                        Navigator.of(dialogContext).pop();
                        // Use Future.microtask to avoid setState during build
                        Future.microtask(() => _loadData());
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid 6-digit code')),
                      );
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      // Ensure dialog controller is disposed when dialog is closed
      if (mounted) {
        setState(() {
          // Refresh state if needed after dialog closes
        });
      }
    });
  }

  Future<void> _toggleColor() async {
    setState(() => _isPinkColor = !_isPinkColor);
    await DatabaseHelper.instance.storeColorPreference(_isPinkColor);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Your Code: ${userCode ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Partner\'s Code: ${partnerCode?.toUpperCase() ?? ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: _isPinkColor ? Colors.pink : const Color(0xFF3A4C7A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _toggleColor,
                  label: Text(
                    'Toggle User Color',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Color(0xFF3A4C7A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _showPartnerCodeDialog(context),
                  child: const Text(
                    'Add Partner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Color(0xFF3A4C7A),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    // Implement reset data logic
                    await DatabaseHelper.instance.clearDb();
                    if (mounted) {
                      _loadData();
                    }
                  },
                  child: const Text(
                    'Reset Data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
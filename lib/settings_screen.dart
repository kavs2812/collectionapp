import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<String> settingsBox;
  List<String> fields = [];

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    settingsBox = Hive.box<String>('settings');
    String? storedFields = settingsBox.get('fields');
    setState(() {
      fields = storedFields != null
          ? List<String>.from(jsonDecode(storedFields))
          : ['Name', 'Mobile Number', 'Occupation', 'Address', 'Amount'];
    });
  }

  void _saveFields() {
    settingsBox.put('fields', jsonEncode(fields));
  }

  void _addNewField() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text('Add New Field'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter field name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    fields.add(controller.text.trim());
                    _saveFields();
                  });
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _deleteField(int index) {
    setState(() {
      fields.removeAt(index);
      _saveFields();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(fields[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteField(index),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addNewField,
              child: Text('Add New Field'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _saveFields();
                Navigator.pop(context, fields);
              },
              child: Text("Save and Return"),
            ),
          ],
        ),
      ),
    );
  }
}

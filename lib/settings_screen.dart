import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Box<String> settingsBox = Hive.box<String>('settings');
  List<String> fields = [];

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  void _loadFields() {
    String? storedFields = settingsBox.get('fields');
    if (storedFields != null) {
      setState(() {
        fields = List<String>.from(jsonDecode(storedFields));
      });
    } else {
      setState(() {
        fields = ['Name', 'Mobile Number', 'Occupation', 'Address', 'Amount'];
      });
    }
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
                }
                Navigator.pop(context);
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
            Text('Fields Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ReorderableListView(
                children: fields.asMap().entries.map((entry) {
                  int index = entry.key;
                  String field = entry.value;
                  return Card(
                    key: ValueKey(field),
                    color: Colors.blue[50],
                    child: ListTile(
                      title: Text(field, style: TextStyle(fontSize: 16)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteField(index),
                      ),
                    ),
                  );
                }).toList(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = fields.removeAt(oldIndex);
                    fields.insert(newIndex, item);
                    _saveFields();
                  });
                },
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: ElevatedButton.icon(
                onPressed: _addNewField,
                icon: Icon(Icons.add),
                label: Text('Add New Field'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

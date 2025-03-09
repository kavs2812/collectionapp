import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<String> settingsBox;
  Map<String, String> fields = {}; // Stores field names with types

  final List<String> fieldTypes = [
    'Text',
    'Number',
    'Date',
    'Dropdown'
  ]; // Available field types

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    settingsBox = Hive.box<String>('settings');
    String? storedFields = settingsBox.get('fields');

    if (storedFields != null && storedFields.isNotEmpty) {
      try {
        setState(() {
          fields = Map<String, String>.from(jsonDecode(storedFields));
        });
      } catch (e) {
        setState(() {
          fields = {};
        });
      }
    } else {
      setState(() {
        fields = {
          'Name': 'Text',
          'Mobile Number': 'Number',
          'Occupation': 'Text',
          'Address': 'Text',
          'Amount': 'Number'
        };
      });
    }
  }

  void _saveFields() {
    settingsBox.put('fields', jsonEncode(fields));
  }

  void _addNewField() {
    TextEditingController fieldNameController = TextEditingController();
    String selectedType = fieldTypes[0];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add New Field'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fieldNameController,
                decoration: InputDecoration(hintText: 'Enter field name'),
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: fieldTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedType = value;
                  }
                },
                decoration: InputDecoration(labelText: 'Field Type'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String fieldName = fieldNameController.text.trim();
                if (fieldName.isNotEmpty) {
                  setState(() {
                    fields[fieldName] = selectedType;
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

  void _deleteField(String fieldName) {
    setState(() {
      fields.remove(fieldName);
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
                  String fieldName = fields.keys.elementAt(index);
                  return ListTile(
                    title: Text('$fieldName (${fields[fieldName]})'),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteField(fieldName),
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

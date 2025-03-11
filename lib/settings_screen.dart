import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'field_model.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<String> settingsBox;
  List<FieldModel> fields = [];

  final List<String> fieldTypes = [
    'Text',
    'Number',
    'Date',
    'DateTime',
    'Dropdown'
  ];

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
          fields = (jsonDecode(storedFields) as List)
              .map((e) => FieldModel.fromJson(e))
              .toList();
        });
      } catch (e) {
        setState(() {
          fields = [];
        });
      }
    }
  }

  void _saveFields() {
    settingsBox.put(
        'fields', jsonEncode(fields.map((e) => e.toJson()).toList()));
  }

  void _addNewField() {
    TextEditingController fieldNameController = TextEditingController();
    String selectedType = fieldTypes[0];
    bool isMandatory = false;

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
              SwitchListTile(
                title: Text('Mandatory'),
                value: isMandatory,
                onChanged: (value) {
                  setState(() {
                    isMandatory = value;
                  });
                },
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
                    fields.add(FieldModel(
                        name: fieldName,
                        type: selectedType,
                        isMandatory: isMandatory));
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
                  FieldModel field = fields[index];
                  return ListTile(
                    title: Text('${field.name} (${field.type})'),
                    subtitle: field.isMandatory
                        ? Text('Mandatory', style: TextStyle(color: Colors.red))
                        : null,
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

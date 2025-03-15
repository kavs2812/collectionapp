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

  final List<String> fixedFields = ['Name', 'Amount'];

  final List<FieldModel> defaultFields = [
    FieldModel(name: 'Name', type: 'Text', isMandatory: true),
    FieldModel(name: 'Amount', type: 'Number', isMandatory: true),
    FieldModel(name: 'Age', type: 'Number', isMandatory: false),
    FieldModel(name: 'Number', type: 'Number', isMandatory: false),
    FieldModel(name: 'Address', type: 'Text', isMandatory: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    settingsBox = Hive.box<String>('settings');
    String? storedFields = settingsBox.get('fields');

    if (storedFields == null || storedFields.isEmpty) {
      _resetToDefaultFields();
    } else {
      try {
        List<FieldModel> loadedFields = (jsonDecode(storedFields) as List)
            .map((e) => FieldModel.fromJson(e))
            .toList();
        setState(() {
          fields = loadedFields;
        });

        _ensureFixedFieldsPosition();
      } catch (e) {
        _resetToDefaultFields();
      }
    }
  }

  void _resetToDefaultFields() {
    setState(() {
      fields = defaultFields;
    });
    _saveFields();
  }

  void _saveFields() {
    settingsBox.put(
        'fields', jsonEncode(fields.map((e) => e.toJson()).toList()));
  }

  void _ensureFixedFieldsPosition() {
    setState(() {
      fields.sort((a, b) {
        if (a.name == "Name") return -1;
        if (b.name == "Name") return 1;
        if (a.name == "Amount") return -1;
        if (b.name == "Amount") return 1;
        return 0;
      });
    });
  }

  void _addNewField() {
    _showFieldDialog(isEdit: false);
  }

  void _editField(int index) {
    _showFieldDialog(isEdit: true, fieldIndex: index);
  }

  void _showFieldDialog({required bool isEdit, int? fieldIndex}) {
    String title = isEdit ? 'Edit Field' : 'Add New Field';
    FieldModel? editingField = isEdit ? fields[fieldIndex!] : null;

    TextEditingController fieldNameController =
        TextEditingController(text: editingField?.name ?? '');
    String selectedType = editingField?.type ?? fieldTypes[0];
    bool isMandatory = editingField?.isMandatory ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(title),
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
                        setStateDialog(() {
                          selectedType = value;
                        });
                      }
                    },
                    decoration: InputDecoration(labelText: 'Field Type'),
                  ),
                  SwitchListTile(
                    title: Text('Mandatory'),
                    value: isMandatory,
                    onChanged: (value) {
                      setStateDialog(() {
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
                        if (isEdit) {
                          fields[fieldIndex!] = FieldModel(
                              name: fieldName,
                              type: selectedType,
                              isMandatory: isMandatory);
                        } else {
                          fields.add(FieldModel(
                              name: fieldName,
                              type: selectedType,
                              isMandatory: isMandatory));
                        }
                        _ensureFixedFieldsPosition();
                        _saveFields();
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(isEdit ? 'Update' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteField(int index) {
    FieldModel field = fields[index];

    if (fixedFields.contains(field.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${field.name} cannot be deleted.")),
      );
      return;
    }

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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editField(index),
                        ),
                        if (!fixedFields.contains(field.name))
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteField(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addNewField,
              child: Text('Add New Field'),
            ),
          ],
        ),
      ),
    );
  }
}

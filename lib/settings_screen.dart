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
        List<dynamic> decodedFields = jsonDecode(storedFields);
        setState(() {
          fields = decodedFields.map((e) => FieldModel.fromJson(e)).toList();
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
    List<String> dropdownOptions = List.from(editingField?.options ?? []);
    TextEditingController optionController = TextEditingController();
    String? errorText;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 300,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: fieldNameController,
                        maxLength: 30,
                        decoration: InputDecoration(
                          hintText: 'Enter field name',
                          errorText: errorText,
                        ),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: fieldTypes.map((type) {
                          return DropdownMenuItem(
                              value: type, child: Text(type));
                        }).toList(),
                        onChanged: isEdit && selectedType == 'Dropdown'
                            ? null
                            : (value) {
                                setStateDialog(() {
                                  selectedType = value!;
                                  if (selectedType != 'Dropdown') {
                                    dropdownOptions.clear();
                                  }
                                });
                              },
                        decoration: InputDecoration(labelText: 'Field Type'),
                      ),
                      SizedBox(height: 10),
                      SwitchListTile(
                        title: Text('Mandatory'),
                        value: isMandatory,
                        onChanged: (value) {
                          setStateDialog(() {
                            isMandatory = value;
                          });
                        },
                      ),
                      if (selectedType == 'Dropdown') ...[
                        SizedBox(height: 10),
                        Text('Dropdown Options',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Container(
                          constraints: BoxConstraints(maxHeight: 150),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: dropdownOptions.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(dropdownOptions[index]),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setStateDialog(() {
                                      dropdownOptions.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optionController,
                                decoration:
                                    InputDecoration(hintText: 'Enter option'),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () {
                                if (optionController.text.trim().isNotEmpty) {
                                  setStateDialog(() {
                                    dropdownOptions
                                        .add(optionController.text.trim());
                                    optionController.clear();
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    String fieldName = fieldNameController.text.trim();

                    if (fieldName.isEmpty) {
                      setStateDialog(() {
                        errorText = "Field name cannot be empty";
                      });
                      return;
                    }

                    bool isDuplicate = fields.any((field) =>
                        field.name.toLowerCase() == fieldName.toLowerCase() &&
                        (!isEdit || fields[fieldIndex!].name != fieldName));

                    if (isDuplicate) {
                      setStateDialog(() {
                        errorText = "Field name already exists";
                      });
                      return;
                    }

                    if (selectedType == 'Dropdown' && dropdownOptions.isEmpty) {
                      setStateDialog(() {
                        errorText = "Dropdown must have at least one option";
                      });
                      return;
                    }

                    setState(() {
                      if (isEdit) {
                        fields[fieldIndex!] = FieldModel(
                          name: fieldName,
                          type: selectedType,
                          isMandatory: isMandatory,
                          options:
                              selectedType == 'Dropdown' ? dropdownOptions : [],
                        );
                      } else {
                        fields.add(FieldModel(
                          name: fieldName,
                          type: selectedType,
                          isMandatory: isMandatory,
                          options:
                              selectedType == 'Dropdown' ? dropdownOptions : [],
                        ));
                      }
                      _saveFields();
                    });
                    Navigator.pop(context);
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (field.isMandatory)
                          Text('Mandatory',
                              style: TextStyle(color: Colors.red)),
                        if (field.type == 'Dropdown' &&
                            field.options.isNotEmpty)
                          Text('Options: ${field.options.join(', ')}'),
                      ],
                    ),
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

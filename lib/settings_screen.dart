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
  final TextEditingController _nameController = TextEditingController();
  String _selectedType = 'Text';
  bool _isMandatory = false;
  bool _showAddFieldForm = false;
  final List<String> _fieldTypes = [
    'Text',
    'Number',
    'Dropdown',
    'Date',
    'DateTime'
  ];
  int _dropdownOptionCount = 2;
  List<TextEditingController> _optionControllers = [];

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box<String>('settings');
    _loadFields();
  }

  Future<void> _loadFields() async {
    String? storedFields = settingsBox.get('fields');
    if (storedFields != null && storedFields.isNotEmpty) {
      try {
        setState(() {
          fields = (jsonDecode(storedFields) as List)
              .map((e) => FieldModel.fromJson(e))
              .toList();
        });
      } catch (e) {
        _resetToDefaultFields();
      }
    }
  }

  void _resetToDefaultFields() {
    setState(() {
      fields = [
        FieldModel(name: 'Name', type: 'Text', isMandatory: true),
        FieldModel(name: 'Age', type: 'Number', isMandatory: true),
        FieldModel(name: 'Number', type: 'Number', isMandatory: true),
        FieldModel(name: 'Amount', type: 'Number', isMandatory: false),
        FieldModel(name: 'Address', type: 'Text', isMandatory: false),
        FieldModel(
          name: 'Gender',
          type: 'Dropdown',
          isMandatory: true,
          options: ['Male', 'Female'],
        ),
      ];
      _saveFields();
    });
  }

  void _saveFields() {
    settingsBox.put(
        'fields', jsonEncode(fields.map((e) => e.toJson()).toList()));
  }

  void _addField() {
    if (_nameController.text.isNotEmpty) {
      List<String> options = [];
      if (_selectedType == 'Dropdown') {
        options = _optionControllers
            .map((controller) => controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();
        if (options.isEmpty) {
          options = ['Male', 'Female']; // Default meaningful options
        }
      }
      setState(() {
        fields.add(FieldModel(
          name: _nameController.text,
          type: _selectedType,
          isMandatory: _isMandatory,
          options: options,
        ));
        _nameController.clear();
        _selectedType = 'Text';
        _isMandatory = false;
        _dropdownOptionCount = 2;
        _optionControllers.clear();
        _showAddFieldForm = false;
        _saveFields();
      });
    }
  }

  void _removeField(int index) {
    setState(() {
      fields.removeAt(index);
      _saveFields();
    });
  }

  void _editField(int index) {
    final field = fields[index];
    _nameController.text = field.name;
    _selectedType = field.type;
    _isMandatory = field.isMandatory;
    _dropdownOptionCount = field.options.length;
    _optionControllers = field.options
        .map((option) => TextEditingController(text: option))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Field'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Field Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Field Type',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _fieldTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              SizedBox(height: 12),
              if (_selectedType == 'Dropdown') ...[
                DropdownButtonFormField<int>(
                  value: _dropdownOptionCount,
                  decoration: InputDecoration(
                    labelText: 'Number of Options',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: List.generate(10, (index) => index + 1)
                      .map((count) =>
                          DropdownMenuItem(value: count, child: Text('$count')))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _dropdownOptionCount = value!;
                      while (_optionControllers.length < _dropdownOptionCount) {
                        _optionControllers.add(TextEditingController());
                      }
                      while (_optionControllers.length > _dropdownOptionCount) {
                        _optionControllers.removeLast();
                      }
                    });
                  },
                ),
                SizedBox(height: 12),
                ...List.generate(
                  _dropdownOptionCount,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: _optionControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Option ${index + 1}',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 12),
              CheckboxListTile(
                title: Text('Mandatory'),
                value: _isMandatory,
                onChanged: (value) => setState(() => _isMandatory = value!),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                List<String> options = _selectedType == 'Dropdown'
                    ? _optionControllers
                        .map((controller) => controller.text.trim())
                        .where((text) => text.isNotEmpty)
                        .toList()
                    : [];
                if (_selectedType == 'Dropdown' && options.isEmpty) {
                  options = field.options.isNotEmpty
                      ? field.options
                      : ['Male', 'Female'];
                }
                setState(() {
                  fields[index] = FieldModel(
                    name: _nameController.text,
                    type: _selectedType,
                    isMandatory: _isMandatory,
                    options: options,
                  );
                  _saveFields();
                  _nameController.clear();
                  _selectedType = 'Text';
                  _isMandatory = false;
                  _dropdownOptionCount = 2;
                  _optionControllers.clear();
                });
                Navigator.pop(context);
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
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
            Text('Manage Fields',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            if (_showAddFieldForm) ...[
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Field Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: 'Field Type',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _fieldTypes
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              if (_selectedType == 'Dropdown') ...[
                SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _dropdownOptionCount,
                  decoration: InputDecoration(
                    labelText: 'Number of Options',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: List.generate(10, (index) => index + 1)
                      .map((count) =>
                          DropdownMenuItem(value: count, child: Text('$count')))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _dropdownOptionCount = value!;
                      while (_optionControllers.length < _dropdownOptionCount) {
                        _optionControllers.add(TextEditingController());
                      }
                      while (_optionControllers.length > _dropdownOptionCount) {
                        _optionControllers.removeLast();
                      }
                    });
                  },
                ),
                SizedBox(height: 12),
                ...List.generate(
                  _dropdownOptionCount,
                  (index) => Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: TextField(
                      controller: _optionControllers.length > index
                          ? _optionControllers[index]
                          : (_optionControllers.add(TextEditingController())
                              as Null),
                      decoration: InputDecoration(
                        labelText: 'Option ${index + 1}',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 12),
              CheckboxListTile(
                title: Text('Mandatory'),
                value: _isMandatory,
                onChanged: (value) => setState(() => _isMandatory = value!),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Save Field'),
                    onPressed: _addField,
                  ),
                  TextButton(
                    onPressed: () => setState(() => _showAddFieldForm = false),
                    child: Text('Cancel', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ] else ...[
              ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('Add Field'),
                onPressed: () => setState(() => _showAddFieldForm = true),
              ),
            ],
            SizedBox(height: 20),
            Text('Current Fields',
                style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: ListView.builder(
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final field = fields[index];
                  final isProtectedField = field.name.toLowerCase() == 'name' ||
                      field.name.toLowerCase() == 'amount';
                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text('${field.name} (${field.type})'),
                      subtitle: field.type == 'Dropdown'
                          ? Text('Options: ${field.options.join(', ')}')
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editField(index),
                          ),
                          if (!isProtectedField)
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeField(index),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

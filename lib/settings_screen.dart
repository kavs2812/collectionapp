import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'field_model.dart';
import 'package:collectionapp/l10n/app_localizations.dart'
    show AppLocalizations;

class SettingsScreen extends StatefulWidget {
  final Function(Locale) changeLanguage;

  const SettingsScreen({Key? key, required this.changeLanguage})
      : super(key: key);
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<String> settingsBox;
  List<FieldModel> fields = [];
  String selectedInvoiceTemplate = 'Default'; // Default template

  final List<String> fieldTypes = ['Text', 'Number', 'Dropdown'];
  final List<String> fixedFields = ['Name', 'Amount'];
  final List<String> invoiceTemplates = [
    'Default',
    'Temple Fund Collection',
    'Treasurer Fund Collection'
  ];

  List<FieldModel> defaultFields = [];

  String _localizeFieldType(String type) {
    final loc = AppLocalizations.of(context)!;
    switch (type.toLowerCase()) {
      case 'text':
        return loc.text;
      case 'number':
        return loc.number;
      case 'dropdown':
        return loc.dropdown;
      default:
        return type;
    }
  }

  String _localizeFieldName(String name) {
    final loc = AppLocalizations.of(context)!;
    switch (name.toLowerCase()) {
      case 'name':
        return loc.name;
      case 'amount':
        return loc.amount;
      case 'age':
        return loc.age;
      case 'number':
        return loc.number;
      case 'address':
        return loc.address;
      default:
        return name;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    defaultFields = [
      FieldModel(
          name: AppLocalizations.of(context)!.name,
          type: AppLocalizations.of(context)!.text,
          isMandatory: true),
      FieldModel(
          name: AppLocalizations.of(context)!.amount,
          type: AppLocalizations.of(context)!.number,
          isMandatory: true),
      FieldModel(
          name: AppLocalizations.of(context)!.age,
          type: AppLocalizations.of(context)!.number,
          isMandatory: false),
      FieldModel(
          name: AppLocalizations.of(context)!.number,
          type: AppLocalizations.of(context)!.number,
          isMandatory: false),
      FieldModel(
          name: AppLocalizations.of(context)!.address,
          type: AppLocalizations.of(context)!.text,
          isMandatory: false),
    ];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _loadFields();
    _loadInvoiceTemplate();
  }

  Future<void> _loadFields() async {
    settingsBox = Hive.box<String>('settings');
    String? storedFields = settingsBox.get('fields');

    if (storedFields == null || storedFields.isEmpty) {
      _resetToDefaultFields();
    } else {
      try {
        List<dynamic> decodedFields = jsonDecode(storedFields);
        setState(() {
          fields = decodedFields.map((e) => FieldModel.fromJson(e)).toList();
        });
        _ensureFixedFieldsPosition();
      } catch (e) {
        _resetToDefaultFields();
      }
    }
  }

  Future<void> _loadInvoiceTemplate() async {
    settingsBox = Hive.box<String>('settings');
    String? storedTemplate = settingsBox.get('invoice_template');
    setState(() {
      selectedInvoiceTemplate = storedTemplate ?? 'Default';
    });
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

  void _saveInvoiceTemplate() {
    settingsBox.put('invoice_template', selectedInvoiceTemplate);
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
    String title = isEdit
        ? AppLocalizations.of(context)!.editField
        : AppLocalizations.of(context)!.addField;

    FieldModel? editingField =
        (isEdit && fieldIndex != null && fieldIndex < fields.length)
            ? fields[fieldIndex]
            : null;

    TextEditingController fieldNameController =
        TextEditingController(text: editingField?.name ?? '');
    String selectedType = editingField?.type ??
        AppLocalizations.of(context)!.text; // Default to localized 'Text'
    bool isMandatory = editingField?.isMandatory ?? false;
    List<String> dropdownOptions = List.from(editingField?.options ?? []);
    TextEditingController optionController = TextEditingController();
    String? errorText;

    List<String> localizedFieldTypes = [
      AppLocalizations.of(context)!.text,
      AppLocalizations.of(context)!.number,
      AppLocalizations.of(context)!.dropdown
    ];

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
                          hintText:
                              AppLocalizations.of(context)!.enterFieldName,
                          errorText: errorText,
                        ),
                      ),
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: selectedType,
                        items: localizedFieldTypes
                            .map((type) => DropdownMenuItem(
                                value: type, child: Text(type)))
                            .toList(),
                        onChanged: (value) {
                          setStateDialog(() {
                            selectedType = value!;
                            if (selectedType !=
                                AppLocalizations.of(context)!.dropdown) {
                              dropdownOptions.clear();
                            }
                          });
                        },
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.fieldType),
                      ),
                      SizedBox(height: 10),
                      SwitchListTile(
                        title: Text(AppLocalizations.of(context)!.mandatory),
                        value: isMandatory,
                        onChanged: (value) {
                          setStateDialog(() {
                            isMandatory = value;
                          });
                        },
                      ),
                      if (selectedType ==
                          AppLocalizations.of(context)!.dropdown) ...[
                        SizedBox(height: 10),
                        Text(AppLocalizations.of(context)!.dropdownOptions,
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
                                decoration: InputDecoration(
                                    hintText: AppLocalizations.of(context)!
                                        .enterOption),
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
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: () {
                    String fieldName = fieldNameController.text.trim();

                    if (fieldName.isEmpty) {
                      setStateDialog(() {
                        errorText =
                            AppLocalizations.of(context)!.fieldNameEmpty;
                      });
                      return;
                    }

                    bool isDuplicate = fields.any((field) =>
                        field.name.toLowerCase() == fieldName.toLowerCase() &&
                        (!isEdit || fields[fieldIndex!].name != fieldName));

                    if (isDuplicate) {
                      setStateDialog(() {
                        errorText = AppLocalizations.of(context)!.fieldExists;
                      });
                      return;
                    }

                    if (selectedType ==
                            AppLocalizations.of(context)!.dropdown &&
                        dropdownOptions.isEmpty) {
                      setStateDialog(() {
                        errorText = AppLocalizations.of(context)!.dropdownEmpty;
                      });
                      return;
                    }

                    setState(() {
                      if (isEdit &&
                          fieldIndex != null &&
                          fieldIndex < fields.length) {
                        fields[fieldIndex] = FieldModel(
                          name: fieldName,
                          type: selectedType,
                          isMandatory: isMandatory,
                          options: selectedType ==
                                  AppLocalizations.of(context)!.dropdown
                              ? dropdownOptions
                              : [],
                        );
                      } else {
                        fields.add(FieldModel(
                          name: fieldName,
                          type: selectedType,
                          isMandatory: isMandatory,
                          options: selectedType ==
                                  AppLocalizations.of(context)!.dropdown
                              ? dropdownOptions
                              : [],
                        ));
                      }
                      _ensureFixedFieldsPosition();
                      _saveFields();
                    });
                    Navigator.pop(context);
                  },
                  child: Text(isEdit
                      ? AppLocalizations.of(context)!.update
                      : AppLocalizations.of(context)!.add),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteField(int index) {
    if (index < 0 || index >= fields.length) return;

    FieldModel field = fields[index];
    if (fixedFields.contains(field.name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .fieldCannotBeDeleted
                .replaceFirst("{field}", field.name))),
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            // 🌐 Choose Language Block
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.choose_language,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Locale>(
                        value: Localizations.localeOf(context),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                        dropdownColor: Colors.white,
                        items: const [
                          DropdownMenuItem(
                            value: Locale('en'),
                            child: Text('English'),
                          ),
                          DropdownMenuItem(
                            value: Locale('ta'),
                            child: Text('தமிழ்'),
                          ),
                        ],
                        onChanged: (Locale? newLocale) {
                          if (newLocale != null) {
                            widget.changeLanguage(newLocale);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 📜 Invoice Template Selection Block
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Invoice Template',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedInvoiceTemplate,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                        dropdownColor: Colors.white,
                        items: invoiceTemplates
                            .map((template) => DropdownMenuItem(
                                  value: template,
                                  child: Text(template),
                                ))
                            .toList(),
                        onChanged: (String? newTemplate) {
                          if (newTemplate != null) {
                            setState(() {
                              selectedInvoiceTemplate = newTemplate;
                              _saveInvoiceTemplate();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🌾 Manage Fields Block
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.manageFields,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          icon: const Icon(Icons.more_vert),
                          isDense: true,
                          items: [
                            DropdownMenuItem(
                              value: 'add',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      color: Colors.green, size: 20),
                                  SizedBox(width: 6),
                                  Text(AppLocalizations.of(context)!.addField),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (String? value) {
                            switch (value) {
                              case 'add':
                                _showFieldDialog(isEdit: false);
                                break;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🧾 List of Fields Block
            Text(
              AppLocalizations.of(context)!.currentFields,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: fields.length,
              itemBuilder: (context, index) {
                final field = fields[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 1.5,
                          offset: Offset(0, 1)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_localizeFieldName(field.name)} (${_localizeFieldType(field.type)})',
                              style: const TextStyle(fontSize: 16),
                            ),
                            if (field.isMandatory)
                              Text(
                                AppLocalizations.of(context)!.mandatory,
                                style: const TextStyle(
                                    color: Colors.red, fontSize: 12),
                              ),
                            if (_localizeFieldType(field.type) ==
                                    AppLocalizations.of(context)!.dropdown &&
                                field.options.isNotEmpty)
                              Text(
                                '${AppLocalizations.of(context)!.dropdownOptions}: ${field.options.join(', ')}',
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey[800]),
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Edit button for all fields
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.orange, size: 20),
                            onPressed: () => _editField(index),
                          ),
                          // Delete button only for non-fixed fields
                          if (!fixedFields.contains(field.name))
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red, size: 20),
                              onPressed: () => _deleteField(index),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

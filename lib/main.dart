import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'field_model.dart';
import 'settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Hive.init('hive_data');
  Hive.registerAdapter(FieldModelAdapter());
  await Hive.openBox<String>('settings');
  await Hive.openBox<List>('collection_data');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 1;

  final List<Widget> _screens = [
    SettingsScreen(),
    CollectionScreen(),
    ReportScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Settings'),
            BottomNavigationBarItem(
                icon: Icon(Icons.list), label: 'Collection'),
            BottomNavigationBarItem(
                icon: Icon(Icons.insert_chart), label: 'Report'),
          ],
        ),
      ),
    );
  }
}

class CollectionScreen extends StatefulWidget {
  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late Box<String> settingsBox;
  late Box<List> dataBox;
  List<FieldModel> fields = [];
  Map<String, TextEditingController> _controllers = {};
  List<Map<String, String>> savedData = [];

  final List<FieldModel> defaultFields = [
    FieldModel(name: 'Name', type: 'Text', isMandatory: true),
    FieldModel(name: 'Age', type: 'Number', isMandatory: true),
    FieldModel(name: 'Number', type: 'Number', isMandatory: true),
    FieldModel(name: 'Amount', type: 'Number', isMandatory: false),
    FieldModel(name: 'Address', type: 'Text', isMandatory: false),
  ];

  @override
  void initState() {
    super.initState();
    _loadFields();
    _loadSavedData();
  }

  Future<void> _loadFields() async {
    settingsBox = Hive.box<String>('settings');
    dataBox = Hive.box<List>('collection_data');

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
    } else {
      _resetToDefaultFields();
    }

    _initializeControllers();
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

  void _initializeControllers() {
    for (var field in fields) {
      _controllers[field.name] = TextEditingController();
    }
  }

  void _loadSavedData() {
    dataBox = Hive.box<List>('collection_data');
    List<dynamic>? storedData = dataBox.get('data');

    if (storedData != null) {
      setState(() {
        savedData = storedData.cast<Map<String, String>>();
      });
    }
  }

  void _clearAllFields() {
    setState(() {
      _controllers.forEach((key, controller) => controller.clear());
    });
  }

  Widget _buildField(FieldModel field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: _controllers[field.name],
        decoration: InputDecoration(
          prefixIcon:
              Icon(field.type == 'Number' ? Icons.numbers : Icons.text_fields),
          labelText: '${field.name} ${field.isMandatory ? '*' : ''}',
          border: OutlineInputBorder(),
        ),
        keyboardType:
            field.type == 'Number' ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (field.isMandatory && (value == null || value.isEmpty)) {
            return '${field.name} is mandatory';
          }
          if (field.type == 'Number' &&
              !RegExp(r'^\d+$').hasMatch(value ?? '')) {
            return 'Only numbers allowed';
          }
          if (field.name.toLowerCase() == 'number' && value!.length != 10) {
            return 'Mobile number must be exactly 10 digits';
          }
          return null;
        },
      ),
    );
  }

  void _saveData() {
    if (_formKey.currentState!.validate()) {
      Map<String, String> newData = {};
      for (var field in fields) {
        newData[field.name] = _controllers[field.name]!.text;
        _controllers[field.name]!.clear();
      }

      setState(() {
        savedData.add(newData);
      });

      dataBox.put('data', savedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data Saved Successfully')),
      );
    }
  }

  Widget _buildSavedDataList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: savedData.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 4.0),
          child: ListTile(
            title: Text('Entry ${index + 1}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: savedData[index]
                  .entries
                  .map((e) => Text('${e.key}: ${e.value}'))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Collection')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ...fields.map((field) => _buildField(field)).toList(),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _saveData,
                            child: Text('Save',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          TextButton(
                            onPressed: _clearAllFields,
                            child: Text('Clear All',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 16)),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text('Saved Data',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      _buildSavedDataList(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Report')),
      body: Center(child: Text('Report Screen')),
    );
  }
}

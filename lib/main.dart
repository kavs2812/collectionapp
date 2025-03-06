import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'settings_screen.dart';
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>('collections');
  await Hive.openBox<String>('settings');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 1;
  List<String> _fields = [];

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  void _loadFields() {
    final settingsBox = Hive.box<String>('settings');
    String? storedFields = settingsBox.get('fields');
    setState(() {
      _fields = storedFields != null
          ? List<String>.from(jsonDecode(storedFields))
          : ['Name', 'Mobile Number', 'Occupation', 'Address', 'Amount'];
    });
  }

  void _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      final updatedFields = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(builder: (context) => SettingsScreen()),
      );
      if (updatedFields != null) {
        final settingsBox = Hive.box<String>('settings');
        settingsBox.put('fields', jsonEncode(updatedFields));
        setState(() {
          _fields = updatedFields;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        body: _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Settings'),
            BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Collection'),
            BottomNavigationBarItem(
                icon: Icon(Icons.description), label: 'Reports'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blueAccent,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 10,
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return SettingsScreen();
      case 1:
        return CollectionScreen(fields: _fields);
      case 2:
        return Center(
            child: Text('Reports Screen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)));
      default:
        return CollectionScreen(fields: _fields);
    }
  }
}

class CollectionScreen extends StatefulWidget {
  final List<String> fields;

  CollectionScreen({required this.fields});

  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Box<String> collectionBox = Hive.box<String>('collections');

  @override
  void initState() {
    super.initState();
    _updateControllers();
  }

  void _updateControllers() {
    _controllers.clear();
    for (var field in widget.fields) {
      _controllers[field] = TextEditingController();
    }
  }

  void _saveData() {
    if (_formKey.currentState!.validate()) {
      final Map<String, String> dataMap = {};
      for (var field in widget.fields) {
        dataMap[field] = _controllers[field]?.text ?? '';
      }
      collectionBox.put(DateTime.now().toString(), jsonEncode(dataMap));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Data saved!')));
      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      for (var controller in _controllers.values) {
        controller.clear();
      }
    });
  }

  void _deleteData(int index) {
    final key = collectionBox.keyAt(index);
    collectionBox.delete(key);
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Data deleted!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Collection')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: widget.fields.map((field) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: TextFormField(
                        controller: _controllers[field],
                        decoration: InputDecoration(
                          labelText: 'Enter $field',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Please enter $field' : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _resetForm,
                  child: Text('Reset'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                ),
                ElevatedButton(
                  onPressed: _saveData,
                  child: Text('Save'),
                  style: ElevatedButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15)),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: collectionBox.isEmpty
                  ? Center(
                      child: Text('No data available',
                          style: TextStyle(fontSize: 16)))
                  : ListView.builder(
                      itemCount: collectionBox.length,
                      itemBuilder: (context, index) {
                        final key = collectionBox.keyAt(index);
                        final data = jsonDecode(collectionBox.get(key)!);
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          elevation: 4,
                          child: ListTile(
                            title: Text(data[widget.fields.first] ?? 'No Name',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: widget.fields.map((field) {
                                return Text("$field: ${data[field] ?? ''}");
                              }).toList(),
                            ),
                            trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteData(index)),
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

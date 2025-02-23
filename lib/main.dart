import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'collection_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CollectionDataAdapter());
  await Hive.openBox<CollectionData>('collections');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CollectionScreen(),
    );
  }
}

class CollectionScreen extends StatefulWidget {
  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _occupationController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Enter Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(labelText: 'Enter Mobile Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a mobile number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _occupationController,
                decoration: InputDecoration(labelText: 'Enter Occupation'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an occupation';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Enter Address'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an address';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Enter Amount'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _formKey.currentState?.reset();
                      _nameController.clear();
                      _mobileController.clear();
                      _occupationController.clear();
                      _addressController.clear();
                      _amountController.clear();
                    },
                    child: Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Reset button is red
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final data = CollectionData(
                          name: _nameController.text,
                          mobileNumber: _mobileController.text,
                          occupation: _occupationController.text,
                          address: _addressController.text,
                          amount: double.parse(_amountController.text),
                        );
                        final box = Hive.box<CollectionData>('collections');
                        box.add(data);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Data saved!')),
                        );
                        _formKey.currentState?.reset();
                        _nameController.clear();
                        _mobileController.clear();
                        _occupationController.clear();
                        _addressController.clear();
                        _amountController.clear();
                      }
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Collection',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Reports',
          ),
        ],
        currentIndex: 1, // Collection is selected
        selectedItemColor: Colors.blue,
      ),
    );
  }
}

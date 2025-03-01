import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'collection_model.dart';
import 'settings_screen.dart'; // Import SettingsScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CollectionDataAdapter());
  await Hive.openBox<CollectionData>('collections');
  await Hive.openBox<String>('settings'); // Open settings box
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _screens = [
    SettingsScreen(),
    CollectionScreen(),
    Scaffold(body: Center(child: Text('Reports Screen'))),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Collection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Settings'),
            BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Collection'),
            BottomNavigationBarItem(
                icon: Icon(Icons.description), label: 'Reports'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          onTap: _onItemTapped,
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
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _occupationController = TextEditingController();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  final Box<CollectionData> collectionBox =
      Hive.box<CollectionData>('collections');

  void _saveData() {
    if (_formKey.currentState!.validate()) {
      final data = CollectionData(
        name: _nameController.text,
        mobileNumber: _mobileController.text,
        occupation: _occupationController.text,
        address: _addressController.text,
        amount: double.parse(_amountController.text),
      );
      collectionBox.add(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data saved!')),
      );
      _resetForm();
      setState(() {});
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _mobileController.clear();
    _occupationController.clear();
    _addressController.clear();
    _amountController.clear();
  }

  void _deleteData(int index) {
    collectionBox.deleteAt(index);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data deleted!')),
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Enter Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a name' : null,
                  ),
                  TextFormField(
                    controller: _mobileController,
                    decoration:
                        InputDecoration(labelText: 'Enter Mobile Number'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter a mobile number' : null,
                  ),
                  TextFormField(
                    controller: _occupationController,
                    decoration: InputDecoration(labelText: 'Enter Occupation'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an occupation' : null,
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: 'Enter Address'),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an address' : null,
                  ),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(labelText: 'Enter Amount'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    validator: (value) =>
                        value!.isEmpty ? 'Please enter an amount' : null,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _resetForm,
                        child: Text('Reset'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                      ),
                      ElevatedButton(
                        onPressed: _saveData,
                        child: Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: collectionBox.isEmpty
                  ? Center(child: Text('No data available'))
                  : ListView.builder(
                      itemCount: collectionBox.length,
                      itemBuilder: (context, index) {
                        final data = collectionBox.getAt(index);
                        return Card(
                          child: ListTile(
                            title: Text(data!.name),
                            subtitle: Text(
                              "Mobile: ${data.mobileNumber}\n"
                              "Occupation: ${data.occupation}\n"
                              "Address: ${data.address}\n"
                              "Amount: ₹${data.amount}",
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteData(index),
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

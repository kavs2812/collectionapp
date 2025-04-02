import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'field_model.dart';
import 'settings_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:html' as html; // For web support
import 'dart:typed_data'; // For handling bytes
import 'dart:ui' show kIsWeb; // Import for kIsWeb
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // For WebView

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter('hive_data');
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
    ReportsScreen(),
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
          print("Loaded fields: $fields"); // Debug print
        });
      } catch (e) {
        print("Error loading fields: $e"); // Debug print
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
    print("Saved fields: ${settingsBox.get('fields')}"); // Debug print
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
        print("Loaded saved data: $savedData"); // Debug print
      });
    } else {
      print("No saved data found in Hive box."); // Debug print
    }
  }

  void _clearAllFields() {
    setState(() {
      _controllers.forEach((key, controller) => controller.clear());
    });
  }

  Widget _buildField(FieldModel field) {
    if (field.type == 'Dropdown') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: DropdownButtonFormField<String>(
          value: _controllers[field.name]!.text.isNotEmpty
              ? _controllers[field.name]!.text
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.arrow_drop_down),
            labelText: '${field.name} ${field.isMandatory ? '*' : ''}',
            border: OutlineInputBorder(),
          ),
          items: field.options
              .map((option) =>
                  DropdownMenuItem(value: option, child: Text(option)))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              _controllers[field.name]!.text = value;
            }
          },
          validator: (value) {
            if (field.isMandatory && (value == null || value.isEmpty)) {
              return '${field.name} is mandatory';
            }
            return null;
          },
        ),
      );
    }

    // Handle Date field with date picker
    if (field.type == 'Date') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextFormField(
          controller: _controllers[field.name],
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.calendar_today),
            labelText: '${field.name} ${field.isMandatory ? '*' : ''}',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.date_range),
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _controllers[field.name]!.text =
                        DateFormat('yyyy-MM-dd').format(pickedDate);
                  });
                }
              },
            ),
          ),
          readOnly: true, // Makes the field non-editable directly
          validator: (value) {
            if (field.isMandatory && (value == null || value.isEmpty)) {
              return '${field.name} is mandatory';
            }
            return null;
          },
        ),
      );
    }

    // Handle DateTime field with date and time picker
    if (field.type == 'DateTime') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: TextFormField(
          controller: _controllers[field.name],
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.calendar_today),
            labelText: '${field.name} ${field.isMandatory ? '*' : ''}',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.access_time),
              onPressed: () async {
                // First pick date
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  // Then pick time
                  TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    final dateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                    setState(() {
                      _controllers[field.name]!.text =
                          DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
                    });
                  }
                }
              },
            ),
          ),
          readOnly: true, // Makes the field non-editable directly
          validator: (value) {
            if (field.isMandatory && (value == null || value.isEmpty)) {
              return '${field.name} is mandatory';
            }
            return null;
          },
        ),
      );
    }

    // Default handling for Text and Number fields
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
      }
      newData['date'] =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      setState(() {
        savedData.add(newData);
        _controllers.forEach((key, controller) => controller.clear());
      });

      dataBox.put('data', savedData);
      print("Saved data to Hive: $savedData"); // Debug print

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data Saved Successfully')),
      );
    }
  }

  Future<void> _generateAndDownloadBill(Map<String, String> data) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Bill Receipt',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Date: ${data['date']}',
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Field',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Value',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...data.entries
                      .map((entry) => pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(entry.key),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(entry.value),
                              ),
                            ],
                          ))
                      .toList(),
                ],
              ),
            ],
          ),
        ),
      );

      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              'bill_${data['date']?.replaceAll(':', '-') ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill downloaded via browser')),
        );
      } else {
        if (await Permission.storage.request().isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Storage permission is required to save the bill')),
          );
          return;
        }

        Directory? directory;
        try {
          directory = await getDownloadsDirectory();
          if (directory == null) {
            throw Exception('Downloads directory not available');
          }
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }

        final fileName =
            'bill_${data['date']?.replaceAll(':', '-') ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');

        await directory.create(recursive: true);
        await file.writeAsBytes(pdfBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bill downloaded to ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download bill: $e')),
      );
    }
  }

  String _generateHtmlInvoice(Map<String, String> data) {
    return '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <title>Invoice</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .invoice-box { max-width: 800px; margin: auto; padding: 30px; border: 1px solid #eee; box-shadow: 0 0 10px rgba(0, 0, 0, 0.15); }
        .invoice-box table { width: 100%; line-height: 1.5; border-collapse: collapse; }
        .invoice-box table td { padding: 5px; vertical-align: top; }
        .invoice-box table tr td:nth-child(2) { text-align: right; }
        .invoice-box .title { font-size: 24px; text-align: center; margin-bottom: 20px; }
        .invoice-box .header { background-color: #f7f7f7; font-weight: bold; }
      </style>
    </head>
    <body>
      <div class="invoice-box">
        <div class="title">Invoice Receipt</div>
        <table>
          <tr class="header">
            <td>Field</td>
            <td>Value</td>
          </tr>
          ${fields.map((field) => '''
            <tr>
              <td>${field.name}</td>
              <td>${data[field.name] ?? 'N/A'}</td>
            </tr>
          ''').join('')}
          <tr>
            <td>Date</td>
            <td>${data['date']}</td>
          </tr>
          <tr>
            <td><strong>Total Amount</strong></td>
            <td><strong>${data['Amount'] ?? '0'}</strong></td>
          </tr>
        </table>
        <p style="text-align: center; margin-top: 20px;">Thank you for your business!</p>
      </div>
    </body>
    </html>
    ''';
  }

  void _showInvoiceInWebView(Map<String, String> data) {
    final htmlContent = _generateHtmlInvoice(data);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceWebViewScreen(htmlContent: htmlContent),
      ),
    );
  }

  Future<void> _exportToCsv() async {
    try {
      List<Map<String, String>> collectionInfo = savedData;

      if (collectionInfo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No data to export')),
        );
        return;
      }

      List<List<dynamic>> csvData = [
        collectionInfo.first.keys.toList(),
        ...collectionInfo.map((entry) => entry.values.toList()),
      ];

      String csv = const ListToCsvConverter().convert(csvData);

      if (kIsWeb) {
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              'collection_${DateTime.now().millisecondsSinceEpoch}.csv')
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV downloaded via browser')),
        );
      } else {
        if (await Permission.storage.request().isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Storage permission is required to export CSV')),
          );
          return;
        }

        Directory? directory;
        try {
          directory = await getDownloadsDirectory();
          if (directory == null) {
            throw Exception('Downloads directory not available');
          }
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }

        final fileName =
            'collection_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File('${directory.path}/$fileName');

        await directory.create(recursive: true);
        await file.writeAsString(csv);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV exported to ${file.path}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
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
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_red_eye_outlined),
                  onPressed: () => _showInvoiceInWebView(savedData[index]),
                ),
                IconButton(
                  icon: Icon(Icons.print),
                  onPressed: () => _generateAndDownloadBill(savedData[index]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collection'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportToCsv,
          ),
        ],
      ),
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

class InvoiceWebViewScreen extends StatelessWidget {
  final String htmlContent;

  const InvoiceWebViewScreen({Key? key, required this.htmlContent})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice Preview'),
      ),
      body: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: htmlContent,
          mimeType: 'text/html',
          encoding: 'utf-8',
        ),
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            javaScriptEnabled: true,
            useShouldOverrideUrlLoading: true,
          ),
        ),
        onWebViewCreated: (controller) {},
      ),
    );
  }
}

class ReportsScreen extends StatefulWidget {
  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Box<List> collectionBox;
  String selectedFilter = "Today";
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    collectionBox = Hive.box<List>('collection_data');
    _storeDummyData();
  }

  void _storeDummyData() {
    DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
    List<dynamic>? existingData = collectionBox.get('data');

    if (existingData == null || existingData.isEmpty) {
      Map<String, String> dummyEntry = {
        "Name": "John Doe",
        "Age": "30",
        "Number": "1234567890",
        "Amount": "500",
        "Address": "123 Poultry Street",
        "date": DateFormat('yyyy-MM-dd HH:mm:ss').format(yesterday),
      };
      setState(() {
        collectionBox.put('data', [dummyEntry]);
        print("Stored dummy data: $dummyEntry"); // Debug print
      });
    }
  }

  List<Map<String, String>> getFilteredCollectionInfo({String? specificDate}) {
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(Duration(days: 1)));

    List<dynamic>? storedData = collectionBox.get('data');
    List<Map<String, String>> collectionInfo = (storedData ?? [])
        .map((item) => Map<String, String>.from(item as Map))
        .toList();

    print("All collection info: $collectionInfo"); // Debug print

    if (specificDate != null) {
      return collectionInfo
          .where((entry) =>
              entry["date"]?.toString().startsWith(specificDate) ?? false)
          .toList();
    }

    if (selectedFilter == "Today") {
      return collectionInfo
          .where(
              (entry) => entry["date"]?.toString().startsWith(today) ?? false)
          .toList();
    } else if (selectedFilter == "Yesterday") {
      return collectionInfo
          .where((entry) =>
              entry["date"]?.toString().startsWith(yesterday) ?? false)
          .toList();
    }

    return collectionInfo;
  }

  void _showDateDataPopup(String selectedDate) {
    List<Map<String, String>> filteredData =
        getFilteredCollectionInfo(specificDate: selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Data for $selectedDate",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              filteredData.isNotEmpty
                  ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredData.length,
                        itemBuilder: (context, index) {
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text('Entry ${index + 1}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: filteredData[index]
                                    .entries
                                    .map((e) => Text('${e.key}: ${e.value}'))
                                    .toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(child: Text("No data available for this date.")),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
      _showDateDataPopup(selectedDate!);
    }
  }

  Future<void> _exportToCsv() async {
    try {
      List<Map<String, String>> collectionInfo = getFilteredCollectionInfo();
      print(
          "Filtered collection info for export: $collectionInfo"); // Debug print

      if (collectionInfo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No data to export')),
        );
        return;
      }

      List<List<dynamic>> csvData = [
        collectionInfo.first.keys.toList(),
        ...collectionInfo.map((entry) => entry.values.toList()),
      ];

      print("CSV data prepared: $csvData"); // Debug print

      String csv = const ListToCsvConverter().convert(csvData);
      print("Generated CSV string: $csv"); // Debug print

      if (kIsWeb) {
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              'report_${selectedFilter}_${DateTime.now().millisecondsSinceEpoch}.csv')
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('CSV downloaded via browser')),
        );
      } else {
        if (await Permission.storage.request().isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Storage permission is required to export CSV')),
          );
          return;
        }

        Directory? directory;
        try {
          directory = await getDownloadsDirectory();
          if (directory == null) {
            throw Exception('Downloads directory not available');
          }
        } catch (e) {
          print("Error accessing Downloads directory: $e"); // Debug print
          directory = await getApplicationDocumentsDirectory();
        }

        final fileName =
            'report_${selectedFilter}_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File('${directory.path}/$fileName');

        print("Saving CSV to: ${file.path}"); // Debug print

        await directory.create(recursive: true);
        await file.writeAsString(csv);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report exported to ${file.path}')),
        );
      }
    } catch (e) {
      print("Error in _exportToCsv: $e"); // Debug print
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export CSV: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> collectionInfo = getFilteredCollectionInfo();

    return Scaffold(
      appBar: AppBar(
        title: Text("Reports"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _exportToCsv,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickDate,
              child: Text(selectedDate ?? "Select Date"),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _filterButton("Today"),
                _filterButton("Yesterday"),
                _filterButton("This Week"),
                _filterButton("This Month"),
              ],
            ),
            SizedBox(height: 16),
            _buildSummaryGrid(collectionInfo),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Recent Collection",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: collectionInfo.isNotEmpty
                  ? ListView.builder(
                      itemCount: collectionInfo.length,
                      itemBuilder: (context, index) {
                        return _listItem(collectionInfo[index], index);
                      },
                    )
                  : Center(
                      child: Text(
                          "No data available for ${selectedDate ?? selectedFilter}")),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(List<Map<String, String>> collectionInfo) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 6,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _summaryCard(
            "Total Collection", _calculateTotal(collectionInfo, "count")),
        _summaryCard("Previous Collection", _calculatePreviousTotal()),
        _summaryCard("Total Clients", _calculateTotalClients(collectionInfo)),
        _summaryCard("Total Payments", _calculateTotalPayments(collectionInfo)),
      ],
    );
  }

  String _calculateTotal(List<Map<String, String>> collectionInfo, String key) {
    return collectionInfo.length.toString();
  }

  String _calculateTotalPayments(List<Map<String, String>> collectionInfo) {
    double total = collectionInfo.fold(0.0, (sum, item) {
      return sum + (double.tryParse(item["Amount"] ?? '0') ?? 0.0);
    });
    return total.toStringAsFixed(2);
  }

  String _calculatePreviousTotal() {
    DateTime now = DateTime.now();
    List<dynamic>? storedData = collectionBox.get('data');
    List<Map<String, String>> collectionInfo = (storedData ?? [])
        .map((item) => Map<String, String>.from(item as Map))
        .toList();

    String filterDate = "";

    if (selectedFilter == "Today") {
      DateTime yesterday = now.subtract(Duration(days: 1));
      filterDate = DateFormat('yyyy-MM-dd').format(yesterday);
    } else if (selectedFilter == "Yesterday") {
      DateTime lastWeekSameDay = now.subtract(Duration(days: 7));
      filterDate = DateFormat('yyyy-MM-dd').format(lastWeekSameDay);
    } else if (selectedFilter == "This Week") {
      DateTime lastMonday = now.subtract(Duration(days: now.weekday + 6));
      DateTime lastSunday = lastMonday.add(Duration(days: 6));
      return collectionInfo
          .where((entry) {
            String date = entry["date"] ?? "";
            return date.compareTo(
                        DateFormat('yyyy-MM-dd').format(lastMonday)) >=
                    0 &&
                date.compareTo(DateFormat('yyyy-MM-dd').format(lastSunday)) <=
                    0;
          })
          .length
          .toString();
    } else if (selectedFilter == "This Month") {
      DateTime firstDayPrevMonth = DateTime(now.year, now.month - 1, 1);
      DateTime lastDayPrevMonth = DateTime(now.year, now.month, 0);
      return collectionInfo
          .where((entry) {
            String date = entry["date"] ?? "";
            return date.compareTo(
                        DateFormat('yyyy-MM-dd').format(firstDayPrevMonth)) >=
                    0 &&
                date.compareTo(
                        DateFormat('yyyy-MM-dd').format(lastDayPrevMonth)) <=
                    0;
          })
          .length
          .toString();
    }

    return collectionInfo
        .where((entry) => entry["date"]?.startsWith(filterDate) ?? false)
        .length
        .toString();
  }

  String _calculateTotalClients(List<Map<String, String>> collectionInfo) {
    Set<String> uniqueClients = {};
    for (var entry in collectionInfo) {
      String? clientName = entry["Name"]?.trim();
      String? mobileNumber = entry["Number"]?.trim();
      if (clientName != null &&
          mobileNumber != null &&
          clientName.isNotEmpty &&
          mobileNumber.isNotEmpty) {
        uniqueClients.add("$clientName|$mobileNumber");
      }
    }
    return uniqueClients.length.toString();
  }

  Widget _summaryCard(String title, String value) {
    return Container(
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(1, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w600, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String text) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor:
            selectedFilter == text ? Colors.blue : Colors.grey[300],
        foregroundColor: selectedFilter == text ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          selectedFilter = text;
          selectedDate = null;
        });
      },
      child: Text(text),
    );
  }

  Widget _listItem(Map<String, String> item, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text('Entry ${index + 1}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              item.entries.map((e) => Text('${e.key}: ${e.value}')).toList(),
        ),
      ),
    );
  }
}

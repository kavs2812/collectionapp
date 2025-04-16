import 'package:flutter/foundation.dart'; // Correct import for kIsWeb
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
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:collectionapp/l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

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
  Locale _appLocale = Locale('en');

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.add(SettingsScreen(changeLanguage: _changeLanguage));
    _screens.add(CollectionScreen());
    _screens.add(ReportsScreen());
  }

  void _changeLanguage(Locale locale) {
    setState(() {
      _appLocale = locale;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Collection App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          elevation: 2,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      supportedLocales: const [
        Locale('en'),
        Locale('ta'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: _appLocale,
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      home: Builder(builder: (context) {
        final localizations = AppLocalizations.of(context);

        return Scaffold(
          body: _screens[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 8,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: localizations?.settings ?? 'Settings'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: localizations?.collection ?? 'Collection'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.insert_chart),
                  label: localizations?.reports ?? 'Reports'),
            ],
          ),
        );
      }),
    );
  }
}

class CollectionScreen extends StatefulWidget {
  @override
  _CollectionScreenState createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
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

  String getLocalizedFieldName(BuildContext context, String fieldName) {
    final loc = AppLocalizations.of(context)!;

    switch (fieldName.toLowerCase()) {
      case 'name':
        return loc.name;
      case 'age':
        return loc.age;
      case 'number':
        return loc.number;
      case 'amount':
        return loc.amount;
      case 'address':
        return loc.address;
      default:
        return fieldName;
    }
  }

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

  Future<void> _pickDate(BuildContext context, FieldModel field) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
      setState(() {
        _controllers[field.name]!.text = formattedDate;
      });
    }
  }

  Future<void> _pickDateTime(BuildContext context, FieldModel field) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime combinedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        String formattedDateTime =
            DateFormat('yyyy-MM-dd HH:mm').format(combinedDateTime);
        setState(() {
          _controllers[field.name]!.text = formattedDateTime;
        });
      }
    }
  }

  Widget _buildField(FieldModel field) {
    if (field.type == 'Dropdown') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: DropdownButtonFormField<String>(
          value: _controllers[field.name]!.text.isNotEmpty
              ? _controllers[field.name]!.text
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.arrow_drop_down, color: Colors.blue),
            labelText:
                '${getLocalizedFieldName(context, field.name)} ${field.isMandatory ? '*' : ''}',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
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
              return '${getLocalizedFieldName(context, field.name)} is mandatory';
            }
            return null;
          },
        ),
      );
    } else if (field.type == 'Date') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: _controllers[field.name],
          readOnly: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.calendar_today, color: Colors.blue),
            labelText:
                '${getLocalizedFieldName(context, field.name)} ${field.isMandatory ? '*' : ''}',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          onTap: () => _pickDate(context, field),
          validator: (value) {
            if (field.isMandatory && (value == null || value.isEmpty)) {
              return '${getLocalizedFieldName(context, field.name)} is mandatory';
            }
            return null;
          },
        ),
      );
    } else if (field.type == 'DateTime') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: TextFormField(
          controller: _controllers[field.name],
          readOnly: true,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.date_range, color: Colors.blue),
            labelText:
                '${getLocalizedFieldName(context, field.name)} ${field.isMandatory ? '*' : ''}',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          onTap: () => _pickDateTime(context, field),
          validator: (value) {
            if (field.isMandatory && (value == null || value.isEmpty)) {
              return '${getLocalizedFieldName(context, field.name)} is mandatory';
            }
            return null;
          },
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _controllers[field.name],
        decoration: InputDecoration(
          prefixIcon: Icon(
              field.type == 'Number' ? Icons.numbers : Icons.text_fields,
              color: Colors.blue),
          labelText:
              '${getLocalizedFieldName(context, field.name)} ${field.isMandatory ? '*' : ''}',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        keyboardType:
            field.type == 'Number' ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (field.isMandatory && (value == null || value.isEmpty)) {
            return '${getLocalizedFieldName(context, field.name)} is mandatory';
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
      newData['Date'] =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      setState(() {
        savedData.add(newData);
        _controllers.forEach((key, controller) => controller.clear());
      });

      dataBox.put('data', savedData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.save)),
      );
    }
  }

  Future<void> _generateAndDownloadBill(Map<String, String> data) async {
    try {
      final pdf = pw.Document();
      final localizations = AppLocalizations.of(context)!;

      Uint8List? logoBytes;
      try {
        final byteData = await rootBundle.load('assets/images/logo.png');
        logoBytes = byteData.buffer.asUint8List();
      } catch (e) {
        print("Error loading logo: $e");
      }

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (logoBytes != null)
                pw.Center(
                  child: pw.Image(pw.MemoryImage(logoBytes),
                      width: 100, height: 100),
                )
              else
                pw.Center(
                  child: pw.Text(
                    'Logo Missing',
                    style: pw.TextStyle(color: PdfColor(1, 0, 0), fontSize: 16),
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Text(
                localizations.billReceipt,
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(
                    width: 1, color: PdfColor.fromHex('#000000')),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                children: [
                  for (var field in fields)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(field.name,
                              style: pw.TextStyle(fontSize: 14)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(data[field.name] ?? 'N/A',
                                style: pw.TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child:
                            pw.Text('Date', style: pw.TextStyle(fontSize: 14)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                              data['Date'] ??
                                  DateFormat('yyyy-MM-dd HH:mm:ss')
                                      .format(DateTime.now()),
                              style: pw.TextStyle(fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total Amount',
                            style: pw.TextStyle(
                                fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(data['Amount'] ?? '0',
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Thank you for your contribution!',
                  style: pw.TextStyle(fontSize: 12),
                  textAlign: pw.TextAlign.center),
            ],
          ),
        ),
      );

      final pdfBytes = await pdf.save();

      if (kIsWeb) {
        // Corrected to use kIsWeb without prefix
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              'bill_${data['Date']?.replaceAll(':', '-') ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.bill_downloaded_browser),
          ),
        );
      } else {
        if (await Permission.storage.request().isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.storage_permission_required),
            ),
          );
          return;
        }

        Directory? directory;
        try {
          directory = await getDownloadsDirectory();
          if (directory == null) {
            throw Exception(
                AppLocalizations.of(context)!.downloadsDirectoryNotAvailable);
          }
        } catch (e) {
          directory = await getApplicationDocumentsDirectory();
        }

        final fileName =
            'bill_${data['Date']?.replaceAll(':', '-') ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${directory.path}/$fileName');

        await directory.create(recursive: true);
        await file.writeAsBytes(pdfBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .bill_downloaded
                .replaceFirst('{path}', file.path)),
          ),
        );
      }
    } catch (e) {
      print("Error generating PDF: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!
              .failed_download_bill
              .replaceFirst('{error}', '$e')),
        ),
      );
    }
  }

  Future<String> _generateHtmlInvoice(Map<String, String> data) async {
    final byteData = await rootBundle.load('assets/images/logo.png');
    final base64Image = base64Encode(byteData.buffer.asUint8List());
    settingsBox = Hive.box<String>('settings');
    String selectedTemplate = settingsBox.get('invoice_template') ?? 'Default';

    if (selectedTemplate == 'Temple Fund Collection') {
      return '''
        <html>
          <head>
            <style>
              @import url('https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap');
              body {
                font-family: 'Roboto', sans-serif;
                background: linear-gradient(135deg, #fff3e0 0%, #ffebee 100%);
                padding: 30px;
                margin: 0;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
              }
              .receipt-container {
                width: 90%;
                max-width: 600px;
                background: #ffffff;
                border-radius: 16px;
                box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
                padding: 24px;
                position: relative;
                overflow: hidden;
              }
              .header {
                text-align: center;
                margin-bottom: 24px;
                border-bottom: 2px solid #ffd700;
                padding-bottom: 16px;
              }
              .header h1 {
                color: #d32f2f;
                font-size: 28px;
                font-weight: 700;
                margin: 0;
                text-transform: uppercase;
              }
              .header h2 {
                color: #1976d2;
                font-size: 20px;
                font-weight: 400;
                margin: 8px 0 0;
              }
              .content {
                display: flex;
                flex-wrap: wrap;
                gap: 24px;
                margin-bottom: 24px;
              }
              .left-section {
                flex: 1;
                min-width: 200px;
                text-align: center;
              }
              .right-section {
                flex: 1;
                min-width: 200px;
              }
              .image-container img {
                width: 120px;
                height: auto;
                border-radius: 8px;
                margin-bottom: 16px;
                box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
              }
              .left-section p {
                color: #424242;
                font-size: 14px;
                line-height: 1.6;
                margin: 8px 0;
              }
              .right-section table {
                width: 100%;
                border-collapse: collapse;
                margin-top: 16px;
              }
              .right-section td {
                padding: 12px 8px;
                font-size: 15px;
                color: #212121;
                border-bottom: 1px solid #eeeeee;
              }
              .right-section td:first-child {
                font-weight: 700;
                color: #d32f2f;
              }
              .right-section .bold {
                font-weight: 700;
                color: #1976d2;
              }
              .footer {
                text-align: center;
                margin-top: 24px;
                padding-top: 16px;
                border-top: 2px solid #ffd700;
                color: #616161;
                font-size: 13px;
                font-style: italic;
              }
              .ornament {
                position: absolute;
                top: 0;
                left: 0;
                width: 100%;
                height: 8px;
                background: linear-gradient(90deg, #ffd700, #d32f2f);
              }
            </style>
          </head>
          <body>
            <div class="receipt-container">
              <div class="ornament"></div>
              <div class="header">
                <h1>Temple Fund Collection</h1>
                <h2>Divine Contribution Receipt</h2>
              </div>
              <div class="content">
                <div class="left-section">
                  <div class="image-container">
                    <img src="data:image/png;base64,$base64Image" alt="Deity Image" />
                  </div>
                  <p>Sacred Fund Collection</p>
                  <p>Supporting the divine mission of our temple with your generous offerings.</p>
                </div>
                <div class="right-section">
                  <table>
                    <tr><td>Name:</td><td>${data['Name'] ?? 'N/A'}</td></tr>
                    <tr><td>Age:</td><td>${data['Age'] ?? 'N/A'}</td></tr>
                    <tr><td>Contact:</td><td>${data['Number'] ?? 'N/A'}</td></tr>
                    <tr><td>Amount:</td><td class="bold">${data['Amount'] ?? '0'}</td></tr>
                    <tr><td>Address:</td><td>${data['Address'] ?? 'N/A'}</td></tr>
                    <tr><td>Date:</td><td>${data['Date'] ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}</td></tr>
                  </table>
                </div>
              </div>
              <div class="footer">
                <p>Blessings from the Temple Fund Committee</p>
              </div>
            </div>
          </body>
        </html>
      ''';
    } else if (selectedTemplate == 'Treasurer Fund Collection') {
      return '''
        <html>
          <head>
            <style>
              @import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;600&display=swap');
              body {
                font-family: 'Poppins', sans-serif;
                background: linear-gradient(135deg, #e8f5e9 0%, #c8e6c9 100%);
                padding: 30px;
                margin: 0;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
              }
              .receipt-container {
                width: 90%;
                max-width: 600px;
                background: #ffffff;
                border-radius: 16px;
                box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);
                padding: 24px;
                position: relative;
                overflow: hidden;
              }
              .header {
                background: linear-gradient(90deg, #388e3c, #4caf50);
                padding: 16px;
                border-radius: 12px 12px 0 0;
                text-align: center;
                color: #ffffff;
                margin: -24px -24px 24px -24px;
              }
              .header img {
                width: 80px;
                height: 80px;
                border-radius: 50%;
                margin-bottom: 12px;
                border: 3px solid #ffffff;
              }
              .header h2 {
                font-size: 24px;
                font-weight: 600;
                margin: 0;
              }
              table {
                width: 100%;
                border-collapse: collapse;
                margin-top: 16px;
              }
              th, td {
                padding: 12px;
                font-size: 15px;
                border-bottom: 1px solid #e0e0e0;
                text-align: left;
              }
              th {
                background: #f5f5f5;
                color: #388e3c;
                font-weight: 600;
              }
              td.right {
                text-align: right;
                color: #212121;
              }
              .total-row td {
                font-weight: 600;
                color: #388e3c;
              }
              .footer {
                text-align: center;
                margin-top: 24px;
                padding-top: 16px;
                border-top: 2px solid #4caf50;
                color: #616161;
                font-size: 13px;
              }
              .ornament {
                position: absolute;
                bottom: 0;
                left: 0;
                width: 100%;
                height: 6px;
                background: linear-gradient(90deg, #4caf50, #388e3c);
              }
            </style>
          </head>
          <body>
            <div class="receipt-container">
              <div class="header">
                <img src="data:image/png;base64,$base64Image" alt="College Logo"/>
                <h2>Treasurer Fund Collection</h2>
              </div>
              <table>
                <tr><th>${AppLocalizations.of(context)!.name}</th><td class="right">${data['Name'] ?? 'N/A'}</td></tr>
                <tr><th>${AppLocalizations.of(context)!.age}</th><td class="right">${data['Age'] ?? 'N/A'}</td></tr>
                <tr><th>${AppLocalizations.of(context)!.number}</th><td class="right">${data['Number'] ?? 'N/A'}</td></tr>
                <tr><th>${AppLocalizations.of(context)!.amount}</th><td class="right">${data['Amount'] ?? '0'}</td></tr>
                <tr><th>${AppLocalizations.of(context)!.address}</th><td class="right">${data['Address'] ?? 'N/A'}</td></tr>
                <tr><th>${AppLocalizations.of(context)!.date}</th><td class="right">${data['Date'] ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}</td></tr>
                <tr class="total-row"><th>Total Contribution</th><td class="right">${data['Amount'] ?? '0'}</td></tr>
              </table>
              <div class="footer">
                <p>Thank you for supporting our institution!</p>
              </div>
              <div class="ornament"></div>
            </div>
          </body>
        </html>
      ''';
    } else {
      return '''
        <html>
          <head>
            <style>
              @import url('https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;600&display=swap');
              body {
                font-family: 'Open Sans', sans-serif;
                background: linear-gradient(135deg, #fef6ff 0%, #f3e5f5 100%);
                padding: 30px;
                margin: 0;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
              }
              .receipt-container {
                width: 90%;
                max-width: 600px;
                background: #ffffff;
                border-radius: 12px;
                box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
                padding: 24px;
              }
              .header {
                text-align: center;
                margin-bottom: 24px;
              }
              .header img {
                width: 100px;
                height: 100px;
                margin-bottom: 12px;
              }
              .header h2 {
                color: #512da8;
                font-size: 24px;
                font-weight: 600;
                margin: 0;
              }
              table {
                width: 100%;
                border-collapse: collapse;
                margin-top: 16px;
              }
              td {
                padding: 12px;
                font-size: 15px;
                border-bottom: 1px solid #e0e0e0;
              }
              .right {
                text-align: right;
                color: #212121;
              }
              .footer {
                text-align: center;
                margin-top: 24px;
                color: #616161;
                font-size: 13px;
              }
            </style>
          </head>
          <body>
            <div class="receipt-container">
              <div class="header">
                <img src="data:image/png;base64,$base64Image" alt="Logo"/>
                <h2>Invoice Receipt</h2>
              </div>
              <table>
                <tr><td>Name</td><td class="right">${data['Name'] ?? 'N/A'}</td></tr>
                <tr><td>Age</td><td class="right">${data['Age'] ?? 'N/A'}</td></tr>
                <tr><td>Number</td><td class="right">${data['Number'] ?? 'N/A'}</td></tr>
                <tr><td>Amount</td><td class="right">${data['Amount'] ?? '0'}</td></tr>
                <tr><td>Address</td><td class="right">${data['Address'] ?? 'N/A'}</td></tr>
                <tr><td>Date</td><td class="right">${data['Date'] ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}</td></tr>
                <tr><td><strong>Total Amount</strong></td><td class="right"><strong>${data['Amount'] ?? '0'}</strong></td></tr>
              </table>
              <div class="footer">
                <p>Thank you for your business!</p>
              </div>
            </div>
          </body>
        </html>
      ''';
    }
  }

  void _showInvoiceInWebView(Map<String, String> data) async {
    final htmlContent = await _generateHtmlInvoice(data);
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
          SnackBar(content: Text(AppLocalizations.of(context)!.noDataToExport)),
        );
        return;
      }

      List<List<dynamic>> csvData = [
        collectionInfo.first.keys.toList(),
        ...collectionInfo.map((entry) => entry.values.toList()),
      ];

      String csv = const ListToCsvConverter().convert(csvData);

      if (kIsWeb) {
        // Corrected to use kIsWeb without prefix
        final bytes = utf8.encode(csv);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              'collection_${DateTime.now().millisecondsSinceEpoch}.csv')
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.csvDownloadedBrowser)),
        );
      } else {
        if (await Permission.storage.request().isDenied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!
                    .storagePermissionRequiredCsv)),
          );
          return;
        }

        Directory? directory;
        try {
          directory = await getDownloadsDirectory();
          if (directory == null) {
            throw Exception(
                AppLocalizations.of(context)!.downloadsDirectoryNotAvailable);
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
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .csvExportedTo
                  .replaceFirst('{path}', file.path))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!
                .failedToExportCsv
                .replaceFirst('{error}', e.toString()))),
      );
    }
  }

  String _getLocalizedFieldName(String key) {
    final localizations = AppLocalizations.of(context)!;

    switch (key.toLowerCase()) {
      case 'name':
        return localizations.name;
      case 'age':
        return localizations.age;
      case 'number':
        return localizations.number;
      case 'amount':
        return localizations.amount;
      case 'address':
        return localizations.address;
      case 'date':
        return localizations.date;
      default:
        return key;
    }
  }

  Widget _buildSavedDataList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: savedData.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            contentPadding: EdgeInsets.all(12),
            title: Text(
              "${AppLocalizations.of(context)!.entry} ${index + 1}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: savedData[index].entries.map((e) {
                final fieldLabel = _getLocalizedFieldName(e.key);
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text('$fieldLabel: ${e.value}'),
                );
              }).toList(),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_red_eye_outlined, color: Colors.blue),
                  onPressed: () => _showInvoiceInWebView(savedData[index]),
                ),
                IconButton(
                  icon: Icon(Icons.print, color: Colors.green),
                  onPressed: () => _generateAndDownloadBill(savedData[index]),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    setState(() {
                      savedData.removeAt(index);
                      dataBox.put('data', savedData);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(AppLocalizations.of(context)!.entryDeleted)),
                    );
                  },
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
        title: Text(AppLocalizations.of(context)!.collection),
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
                              backgroundColor: Colors.blue,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            onPressed: _saveData,
                            child: Text(AppLocalizations.of(context)!.save,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: _clearAllFields,
                            child: Text(AppLocalizations.of(context)!.clear_all,
                                style:
                                    TextStyle(color: Colors.red, fontSize: 16)),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(AppLocalizations.of(context)!.saved_data,
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
        title: Text(AppLocalizations.of(context)!.invoicePreview),
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

  String getLocalizedField(String key) {
    switch (key) {
      case "Name":
        return AppLocalizations.of(context)!.name;
      case "Age":
        return AppLocalizations.of(context)!.age;
      case "Number":
        return AppLocalizations.of(context)!.number;
      case "Amount":
        return AppLocalizations.of(context)!.amount;
      case "Address":
        return AppLocalizations.of(context)!.address;
      case "date":
        return AppLocalizations.of(context)!.date;
      default:
        return key;
    }
  }

  @override
  void initState() {
    super.initState();
    collectionBox = Hive.box<List>('collection_data');
    _storeDummyData();
  }

  void _storeDummyData() {
    DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
    String formattedDate = DateFormat('yyyy-MM-dd').format(yesterday);
    List<dynamic>? existingData = collectionBox.get('data');

    if (existingData == null || existingData.isEmpty) {
      Map<String, String> dummyEntry = {
        "Name": "John Doe",
        "Age": "30",
        "Number": "1234567890",
        "Amount": "500",
        "Address": "123 Poultry Street",
        "Date": DateFormat('yyyy-MM-dd HH:mm:ss').format(yesterday),
      };
      setState(() {
        collectionBox.put('data', [dummyEntry]);
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

    if (specificDate != null) {
      return collectionInfo
          .where((entry) =>
              entry["Date"]?.toString().startsWith(specificDate) ?? false)
          .toList();
    }

    if (selectedFilter == "Today") {
      return collectionInfo
          .where(
              (entry) => entry["Date"]?.toString().startsWith(today) ?? false)
          .toList();
    } else if (selectedFilter == "Yesterday") {
      return collectionInfo
          .where((entry) =>
              entry["Date"]?.toString().startsWith(yesterday) ?? false)
          .toList();
    }

    return collectionInfo;
  }

  void _showDateDataPopup(String selectedDate) {
    List<Map<String, String>> filteredData =
        getFilteredCollectionInfo(specificDate: selectedDate);

    String displayDate = DateFormat('dd-MMM-yyyy')
        .format(DateFormat('yyyy-MM-dd').parse(selectedDate));

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
                "${AppLocalizations.of(context)!.data_for} $displayDate",
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              title: Text(
                                "${AppLocalizations.of(context)!.entry} ${index + 1}",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: filteredData[index].entries.map((e) {
                                  String label = getLocalizedField(e.key);
                                  String value = e.key == "Date"
                                      ? DateFormat('dd-MMM-yyyy HH:mm:ss')
                                          .format(
                                              DateFormat('yyyy-MM-dd HH:mm:ss')
                                                  .parse(e.value))
                                      : e.value;
                                  return Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                    child: Text('$label: $value'),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child:
                          Text(AppLocalizations.of(context)!.no_data_available),
                    ),
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

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> collectionInfo = getFilteredCollectionInfo();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reports),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickDate,
              child: Text(
                  selectedDate ?? AppLocalizations.of(context)!.select_date),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _filterButton(AppLocalizations.of(context)!.today),
                _filterButton(AppLocalizations.of(context)!.yesterday),
                _filterButton(AppLocalizations.of(context)!.this_week),
                _filterButton(AppLocalizations.of(context)!.this_month),
              ],
            ),
            SizedBox(height: 16),
            _buildSummaryGrid(collectionInfo),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.recent_collection,
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
                        AppLocalizations.of(context)!.no_data_available,
                      ),
                    ),
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
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 4,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _summaryCard(AppLocalizations.of(context)!.total_collection,
            _calculateTotal(collectionInfo, "count")),
        _summaryCard(AppLocalizations.of(context)!.previous_collection,
            _calculatePreviousTotal()),
        _summaryCard(AppLocalizations.of(context)!.total_clients,
            _calculateTotalClients(collectionInfo)),
        _summaryCard(AppLocalizations.of(context)!.total_payments,
            _calculateTotalPayments(collectionInfo)),
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
            String date = entry["Date"] ?? "";
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
            String date = entry["Date"] ?? "";
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
        .where((entry) => entry["Date"]?.startsWith(filterDate) ?? false)
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
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
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
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 14),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _filterButton(String text) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        backgroundColor:
            selectedFilter == text ? Colors.blue : Colors.grey[200],
        foregroundColor: selectedFilter == text ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        setState(() {
          selectedFilter = text;
          selectedDate = null;
        });
      },
      child: Text(text, style: TextStyle(fontSize: 14)),
    );
  }

  Widget _listItem(Map<String, String> item, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        title: Text("${AppLocalizations.of(context)!.entry} ${index + 1}",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: item.entries.map((e) {
            String label = getLocalizedField(e.key);
            String value = e.value;
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Text('$label: $value'),
            );
          }).toList(),
        ),
      ),
    );
  }
}

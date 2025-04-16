// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (en).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get hello => 'Hello';
  @override
  String get welcome_message => 'Welcome to our app!';
  @override
  String get mandatory => 'Mandatory';
  @override
  String get choose_language => 'Choose Language';
  @override
  String get settings => 'Settings';
  @override
  String get name => 'Name';

  @override
  String get mobileNumber => 'Mobile Number';

  @override
  String get occupation => 'Occupation';

  @override
  String get address => 'Address';

  @override
  String get amount => 'Amount';

  @override
  String get number => 'Number';

  @override
  String get age => 'Age';

  @override
  String get collection => 'Collection';

  @override
  String get save => 'Save';

  @override
  String get clear_all => 'Clear All';

  @override
  String get saved_data => 'Saved Data';

  @override
  String get invoicePreview => 'Invoice Preview';

  @override
  String get reports => 'Reports';

  @override
  String get data_for => 'Data for';

  @override
  String get entry => 'Entry';

  @override
  String get no_data_for_date => 'No data for date';

  @override
  String get select_date => 'Select Date';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get this_week => 'This Week';

  @override
  String get this_month => 'This Month';

  @override
  String get recent_collection => 'Recent Collection';

  @override
  String get total_collection => 'Total Collection';

  @override
  String get previous_collection => 'Previous Collection';

  @override
  String get total_clients => 'Total Clients';

  @override
  String get total_payments => 'Total Payments';

  @override
  String get no_data_to_export => 'No data to export';

  @override
  String get csv_downloaded => 'CSV downloaded via browser';

  @override
  String get storage_permission_required =>
      'Storage permission is required to export CSV';

  @override
  String get downloads_directory_unavailable =>
      'Downloads directory not available';

  @override
  String get report_exported_to => 'Report exported to';

  @override
  String get failed_to_export_csv => 'Failed to export CSV';

  @override
  String get no_data_available => 'No data available';

  @override
  String get addField => 'Add New Field';

  @override
  String get editField => 'Edit Field';

  @override
  String get enterFieldName => 'Enter field name';

  @override
  String get fieldType => 'Field Type';

  @override
  String get dropdownOptions => 'Dropdown Options';

  @override
  String get enterOption => 'Enter option';

  @override
  String get cancel => 'Cancel';

  @override
  String get update => 'Update';

  @override
  String get add => 'Add';

  @override
  String get fieldNameEmpty => 'Field name cannot be empty';

  @override
  String get fieldExists => 'Field name already exists';

  @override
  String get dropdownEmpty => 'Dropdown must have at least one option';

  @override
  String get fieldCannotBeDeleted => 'Field cannot be deleted.';

  @override
  String get text => 'Text';

  @override
  String get date => 'Date';

  @override
  String get dateTime => 'Date & Time';

  @override
  String get dropdown => 'Dropdown';

  @override
  String get collectionApp => 'சேகரிப்பு பயன்பாடு';

  @override
  String get failedDownloadBill => 'Failed to download bill: {error}';

  @override
  String get billDownloaded => 'Bill downloaded to {path}';

  @override
  String get storagePermissionRequired =>
      'Storage permission is required to save the bill';

  @override
  String get billDownloadedBrowser => 'Bill downloaded via browser';

  @override
  String get billReceipt => 'Bill Receipt';

  @override
  String get field => 'Field';

  @override
  String get value => 'Value';

  @override
  String get noDataToExport => 'No data to export';

  @override
  String get csvDownloadedBrowser => 'CSV downloaded via browser';

  @override
  String get storagePermissionRequiredCsv =>
      'Storage permission is required to export CSV';

  @override
  String get downloadsDirectoryNotAvailable =>
      'Downloads directory not available';

  @override
  String get csvExportedTo => 'CSV exported to {path}';

  @override
  String get failedToExportCsv => 'Failed to export CSV: {error}';

  @override
  String get manageFields => 'Manage Fields';

  @override
  String get currentFields => 'Current Fields';

  @override
  String get deleteField => 'Delete Fields';

  @override
  String get selectOption => 'Select Option';

  @override
  String get noFieldsToEdit => 'No fields to edit';

  @override
  String get entryDeleted => 'Entry Deleted';

  @override
  // TODO: implement bill_downloaded
  String get bill_downloaded => throw UnimplementedError();

  @override
  // TODO: implement bill_downloaded_browser
  String get bill_downloaded_browser => throw UnimplementedError();

  @override
  // TODO: implement failed_download_bill
  String get failed_download_bill => throw UnimplementedError();
}

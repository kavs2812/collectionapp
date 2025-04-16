import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;
import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

abstract class AppLocalizations {
  AppLocalizations(this.locale);

  final String locale;

  static Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'ta':
        return AppLocalizationsTa();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get hello;
  String get welcome_message;
  String get mandatory;
  String get choose_language;
  String get settings;
  String get name;
  String get mobileNumber;
  String get occupation;
  String get address;
  String get amount;
  String get number;
  String get age;
  String get collection;
  String get save;
  String get clear_all;
  String get saved_data;
  String get invoicePreview;
  String get reports;
  String get data_for;
  String get entry;
  String get no_data_for_date;
  String get select_date;
  String get today;
  String get yesterday;
  String get this_week;
  String get this_month;
  String get recent_collection;
  String get total_collection;
  String get previous_collection;
  String get total_clients;
  String get total_payments;
  String get no_data_to_export;
  String get csv_downloaded;
  String get storage_permission_required;
  String get downloads_directory_unavailable;
  String get report_exported_to;
  String get failed_to_export_csv;
  String get no_data_available;
  String get editField;
  String get addField;
  String get enterFieldName;
  String get fieldType;
  String get dropdownOptions;
  String get enterOption;
  String get cancel;
  String get fieldNameEmpty;
  String get fieldExists;
  String get dropdownEmpty;
  String get update;
  String get add;
  String get fieldCannotBeDeleted;
  String get text;
  String get date;
  String get dateTime;
  String get dropdown;
  String get collectionApp;
  String get failed_download_bill;
  String get bill_downloaded;
  String get bill_downloaded_browser;
  String get billReceipt;
  String get field;
  String get value;
  String get noDataToExport;
  String get csvDownloadedBrowser;
  String get storagePermissionRequiredCsv;
  String get downloadsDirectoryNotAvailable;
  String get csvExportedTo;
  String get failedToExportCsv;
  String get manageFields;
  String get currentFields;
  String get deleteField;
  String get selectOption;
  String get noFieldsToEdit;
  String get entryDeleted;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(LocalizationsDelegate<AppLocalizations> old) => false;
}

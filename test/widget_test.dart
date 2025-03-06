import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:collectionapp/main.dart';

void main() {
  testWidgets('Collection App UI Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp()); // Removed 'const'

    // Verify that the text fields are present.
    expect(find.byType(TextFormField), findsNWidgets(5));

    // Verify that specific text labels are present.
    expect(find.text('Enter Name'), findsOneWidget);
    expect(find.text('Enter Mobile Number'), findsOneWidget);
    expect(find.text('Enter Occupation'), findsOneWidget);
    expect(find.text('Enter Address'), findsOneWidget);
    expect(find.text('Enter Amount'), findsOneWidget);

    // Verify that the buttons are present.
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);

    // Verify that the bottom navigation bar is present.
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}

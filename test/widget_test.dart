import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reception_app/widgets/search_bar.dart';

void main() {
  testWidgets('Search bar renders expected placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchBar(
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Search by name or id'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });
}

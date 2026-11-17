import 'package:djajan_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppTheme applies Plus Jakarta Sans and readable weight hierarchy', () {
    final textTheme = AppTheme.theme.textTheme;

    expect(textTheme.bodyMedium?.fontFamily, 'Plus Jakarta Sans');
    expect(textTheme.bodyMedium?.fontWeight, FontWeight.w400);
    expect(textTheme.titleMedium?.fontWeight, FontWeight.w600);
    expect(textTheme.labelMedium?.fontWeight, FontWeight.w500);
  });

  testWidgets('Bundled font renders through the global app theme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.theme,
        home: const Scaffold(body: Text('Djajan')),
      ),
    );

    final style = DefaultTextStyle.of(
      tester.element(find.text('Djajan')),
    ).style;
    expect(style.fontFamily, 'Plus Jakarta Sans');
    expect(tester.takeException(), isNull);
  });
}

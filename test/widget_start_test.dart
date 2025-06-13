import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:picto_grid/main.dart';

// Füge diese Zeilen hinzu:
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Initialisiere sqflite für Tests:
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App startet ohne Fehler', (tester) async {
    await tester.pumpWidget(const PictoGridApp()); // Passe ggf. den Namen deines Root-Widgets an
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}

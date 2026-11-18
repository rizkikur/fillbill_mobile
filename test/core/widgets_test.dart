import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fillbill_mobile/core/widgets/pin_keypad.dart';
import 'package:fillbill_mobile/core/widgets/pin_dots_display.dart';
import 'package:fillbill_mobile/core/widgets/status_badge.dart';
import 'package:fillbill_mobile/core/widgets/custom_button.dart';

void main() {
  testWidgets('PinKeypad input and backspace test', (tester) async {
    String enteredKey = '';
    bool backspaceCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinKeypad(
            onKeyPressed: (key) => enteredKey = key,
            onBackspacePressed: () => backspaceCalled = true,
          ),
        ),
      ),
    );

    // Tap number 7
    await tester.tap(find.text('7'));
    expect(enteredKey, equals('7'));

    // Tap number 0
    await tester.tap(find.text('0'));
    expect(enteredKey, equals('0'));

    // Tap backspace
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    expect(backspaceCalled, isTrue);
  });

  testWidgets('PinDotsDisplay renders correct dots', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PinDotsDisplay(length: 6, enteredLength: 3),
        ),
      ),
    );

    // Should render 6 animated containers
    expect(find.byType(AnimatedContainer), findsNWidgets(6));
  });

  testWidgets('StatusBadge maps financial statuses correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusBadge(status: 'success'),
              StatusBadge(status: 'pending'),
              StatusBadge(status: 'failed'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Berhasil'), findsOneWidget);
    expect(find.text('Menunggu'), findsOneWidget);
    expect(find.text('Gagal'), findsOneWidget);
  });

  testWidgets('CustomButton shows loading indicator when isLoading is true', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Bayar Sekarang',
            isLoading: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Bayar Sekarang'), findsNothing);
  });
}


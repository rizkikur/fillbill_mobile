import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fillbill_mobile/app/app.dart';
import 'package:fillbill_mobile/core/config/app_config.dart';

void main() {
  testWidgets('FillBillApp smoke test', (WidgetTester tester) async {
    AppConfig.initialize(AppConfig.dev());

    await tester.pumpWidget(
      const ProviderScope(
        child: FillBillApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(FillBillApp), findsOneWidget);
  });
}

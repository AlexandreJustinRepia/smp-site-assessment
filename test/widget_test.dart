import 'package:flutter_test/flutter_test.dart';

import 'package:smp_site_assessment/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SiteAssessmentApp());
    expect(find.text('Site Assessment'), findsOneWidget);
  });
}

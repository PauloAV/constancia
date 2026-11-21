import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:constancia/main.dart';

void main() {
  testWidgets('entra como colaborador e abre o início', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ConstanciaApp());
    expect(find.text('ENTRAR'), findsOneWidget);

    // não precisa digitar nada: o login não valida
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.text('Metas de hoje'), findsOneWidget);
  });
}

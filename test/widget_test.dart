
import 'package:flutter_test/flutter_test.dart';
import 'package:pokedex_app/main.dart';

void main() {
  testWidgets('La pantalla principal de la Pokédex funciona',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PokedexApp());

    // Comprobamos que aparezca el título principal.
    expect(find.text('Mi Pokédex'), findsOneWidget);

    // Comprobamos que aparezca el texto descriptivo.
    expect(
      find.text('Organiza tus equipos Pokémon'),
      findsOneWidget,
    );

    // Comprobamos que exista el botón para crear equipos.
    expect(find.text('Crear equipo'), findsOneWidget);
  });
}
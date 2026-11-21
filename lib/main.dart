import 'package:flutter/material.dart';
import 'estado.dart';
import 'tema.dart';
import 'telas.dart';
import 'telas_rh.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await estado.carregar(); // lê os dados salvos antes de abrir o app
  runApp(const ConstanciaApp());
}

class ConstanciaApp extends StatelessWidget {
  const ConstanciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Constância',
      debugShowCheckedModeBanner: false,
      theme: tema,
      initialRoute: '/login',
      // rotas com nome: Navigator.pushNamed(context, '/perfil')
      routes: {
        '/login': (_) => const LoginPage(),
        '/inicio': (_) => const HomePage(),
        '/rh': (_) => const PainelRHPage(),
        '/nova-meta': (_) => const NovaMetaPage(),
        '/perfil': (_) => const PerfilPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int aba = 0;

  final titulos = ['Constância', 'Treinamentos', 'Recompensas'];
  final telas = const [InicioTab(), TreinamentosTab(), RecompensasTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titulos[aba]),
        actions: [
          if (aba == 0)
            IconButton(
              icon: const Icon(Icons.account_circle),
              onPressed: () => Navigator.pushNamed(context, '/perfil'),
            ),
        ],
      ),
      body: telas[aba],
      floatingActionButton: aba == 0
          ? FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () => Navigator.pushNamed(context, '/nova-meta'),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: aba,
        onTap: (i) => setState(() => aba = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(
              icon: Icon(Icons.school), label: 'Treinamentos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.card_giftcard), label: 'Recompensas'),
        ],
      ),
    );
  }
}

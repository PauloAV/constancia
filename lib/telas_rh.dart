import 'package:material_ui/material_ui.dart';
import 'estado.dart';
import 'modelos.dart';
import 'tema.dart';
import 'telas.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  String papel = 'colaborador';

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  // não valida nada: entra com qualquer e-mail e senha (só para a demonstração)
  void entrar() {
    estado.entrar(papel);
    // colaborador vai para o Início e o RH vai direto para o painel
    Navigator.pushReplacementNamed(context, papel == 'rh' ? '/rh' : '/inicio');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.local_fire_department, color: laranja, size: 64),
              const SizedBox(height: 8),
              const Text('Constância',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w500)),
              const Text('Aprendizado na empresa'),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Colaborador'),
                    selected: papel == 'colaborador',
                    onSelected: (_) => setState(() => papel = 'colaborador'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('RH'),
                    selected: papel == 'rh',
                    onSelected: (_) => setState(() => papel = 'rh'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: senhaController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: entrar,
                  child: const Text('ENTRAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PainelRHPage extends StatelessWidget {
  const PainelRHPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel do RH'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                estado.sair();
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (rota) => false);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pedidos'),
              Tab(text: 'Recompensas'),
              Tab(text: 'Treinamentos'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [PedidosRhTab(), RecompensasRhTab(), TreinamentosRhTab()],
        ),
      ),
    );
  }
}

class PedidosRhTab extends StatelessWidget {
  const PedidosRhTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final pedidos = estado.pedidos.reversed.toList(); // mais novo primeiro

        if (pedidos.isEmpty) {
          return const Center(child: Text('Nenhum pedido de resgate ainda.'));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [for (final p in pedidos) cartaoPedido(context, p)],
        );
      },
    );
  }

  Widget cartaoPedido(BuildContext context, Pedido p) {
    final moeda = p.ouro ? 'ouro' : 'prata';

    String status;
    Color cor;
    if (p.status == 'pendente') {
      status = 'Pendente';
      cor = laranja;
    } else if (p.status == 'aceito') {
      status = 'Aceito';
      cor = verde;
    } else {
      status = 'Recusado · moedas devolvidas';
      cor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.recompensa, style: tituloSecao),
            const SizedBox(height: 4),
            Text('${estado.usuario.nome} · ${p.preco} $moeda'),
            const SizedBox(height: 4),
            Text(status,
                style: TextStyle(color: cor, fontWeight: FontWeight.w500)),
            if (p.status == 'pendente')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      estado.recusarPedido(p);
                      mostrarAviso(context,
                          'Pedido recusado. As moedas voltaram para o colaborador.');
                    },
                    child: const Text('RECUSAR'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      estado.aceitarPedido(p);
                      mostrarAviso(context, 'Pedido aceito.');
                    },
                    child: const Text('ACEITAR'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> excluirRecompensa(BuildContext context, Recompensa r) async {
  final ok = await confirmar(context, 'Excluir recompensa?',
      'A recompensa "${r.nome}" será removida da lista. Pedidos já feitos continuam valendo.');
  if (!ok || !context.mounted) return;

  estado.excluirRecompensa(r);
  mostrarAviso(context, 'Recompensa excluída.');
}

Future<void> excluirTreinamento(BuildContext context, Treinamento t) async {
  final ok = await confirmar(
      context, 'Excluir treinamento?', 'O treinamento "${t.nome}" será removido.');
  if (!ok || !context.mounted) return;

  final erro = estado.excluirTreinamento(t);
  mostrarAviso(context, erro ?? 'Treinamento excluído.');
}

class RecompensasRhTab extends StatelessWidget {
  const RecompensasRhTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NovaRecompensaPage()),
                );
              },
              child: const Text('+ NOVA RECOMPENSA'),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final r in estado.recompensas)
                    ListTile(
                      title: Text(r.nome),
                      subtitle: Text('${r.preco} ${r.ouro ? "ouro" : "prata"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        NovaRecompensaPage(recompensa: r)),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => excluirRecompensa(context, r),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class TreinamentosRhTab extends StatelessWidget {
  const TreinamentosRhTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NovoTreinamentoPage()),
                );
              },
              child: const Text('+ NOVO TREINAMENTO'),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  for (final t in estado.treinamentos)
                    ListTile(
                      title: Text(t.nome),
                      subtitle: Text(
                          '${t.obrigatorio ? "Obrigatório" : "Opcional"} · ${t.horas} h · ${t.modulos.length} módulos'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        NovoTreinamentoPage(treinamento: t)),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => excluirTreinamento(context, t),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class NovaRecompensaPage extends StatefulWidget {
  final Recompensa? recompensa; // se vier preenchida, a tela edita

  const NovaRecompensaPage({super.key, this.recompensa});

  @override
  State<NovaRecompensaPage> createState() => _NovaRecompensaPageState();
}

class _NovaRecompensaPageState extends State<NovaRecompensaPage> {
  late final TextEditingController nomeController;
  late final TextEditingController precoController;
  late String moeda;

  @override
  void initState() {
    super.initState();
    final r = widget.recompensa;
    nomeController = TextEditingController(text: r?.nome ?? '');
    precoController = TextEditingController(text: r == null ? '' : '${r.preco}');
    moeda = (r != null && r.ouro) ? 'Ouro' : 'Prata';
  }

  @override
  void dispose() {
    nomeController.dispose();
    precoController.dispose();
    super.dispose();
  }

  void salvar() {
    final nome = nomeController.text.trim();
    final preco = int.tryParse(precoController.text.trim());

    if (nome.isEmpty) {
      mostrarAviso(context, 'Digite o nome da recompensa.');
      return;
    }
    if (preco == null || preco <= 0) {
      mostrarAviso(context, 'Digite um preço maior que zero.');
      return;
    }

    final existente = widget.recompensa;
    if (existente == null) {
      estado.cadastrarRecompensa(nome, preco, moeda == 'Ouro');
    } else {
      estado.editarRecompensa(existente, nome, preco, moeda == 'Ouro');
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.recompensa == null ? 'Nova recompensa' : 'Editar recompensa'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: 'Nome da recompensa'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: precoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Preço'),
            ),
            const SizedBox(height: 24),
            const Text('Moeda'),
            DropdownButton<String>(
              value: moeda,
              isExpanded: true,
              items: ['Prata', 'Ouro']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (valor) => setState(() => moeda = valor!),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: salvar,
                child: const Text('SALVAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NovoTreinamentoPage extends StatefulWidget {
  final Treinamento? treinamento; // se vier preenchido, a tela edita

  const NovoTreinamentoPage({super.key, this.treinamento});

  @override
  State<NovoTreinamentoPage> createState() => _NovoTreinamentoPageState();
}

class _NovoTreinamentoPageState extends State<NovoTreinamentoPage> {
  late final TextEditingController nomeController;
  late final TextEditingController horasController;
  late final TextEditingController modulosController;
  late bool obrigatorio;
  DateTime? prazo;

  @override
  void initState() {
    super.initState();
    final t = widget.treinamento;
    nomeController = TextEditingController(text: t?.nome ?? '');
    horasController = TextEditingController(text: t == null ? '' : '${t.horas}');
    modulosController =
        TextEditingController(text: t == null ? '' : '${t.modulos.length}');
    obrigatorio = t?.obrigatorio ?? false;
    prazo = t?.prazo;
  }

  @override
  void dispose() {
    nomeController.dispose();
    horasController.dispose();
    modulosController.dispose();
    super.dispose();
  }

  Future<void> escolherPrazo() async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: hoje.add(const Duration(days: 14)),
      firstDate: hoje,
      lastDate: DateTime(hoje.year + 2),
    );
    if (data != null && mounted) {
      setState(() => prazo = data);
    }
  }

  void salvar() {
    final nome = nomeController.text.trim();
    final horas = int.tryParse(horasController.text.trim());
    final qtdModulos = int.tryParse(modulosController.text.trim());

    if (nome.isEmpty) {
      mostrarAviso(context, 'Digite o nome do treinamento.');
      return;
    }
    if (horas == null || horas <= 0) {
      mostrarAviso(context, 'Digite a carga horária em horas.');
      return;
    }
    // editando: os módulos não mudam, só os dados do treinamento
    final existente = widget.treinamento;
    if (existente != null) {
      estado.editarTreinamento(
        existente,
        nome: nome,
        horas: horas,
        obrigatorio: obrigatorio,
        prazo: prazo,
      );
      Navigator.pop(context);
      return;
    }

    if (qtdModulos == null || qtdModulos < 1 || qtdModulos > 20) {
      mostrarAviso(context, 'A quantidade de módulos deve ser de 1 a 20.');
      return;
    }

    estado.cadastrarTreinamento(
      nome: nome,
      horas: horas,
      qtdModulos: qtdModulos,
      obrigatorio: obrigatorio,
      prazo: prazo,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    String textoPrazo = 'ESCOLHER PRAZO (opcional)';
    if (prazo != null) {
      final dia = prazo!.day.toString().padLeft(2, '0');
      final mes = prazo!.month.toString().padLeft(2, '0');
      textoPrazo = 'Prazo: $dia/$mes/${prazo!.year}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.treinamento == null
            ? 'Novo treinamento'
            : 'Editar treinamento'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nomeController,
            decoration: const InputDecoration(labelText: 'Nome do treinamento'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: horasController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Carga horária (horas)'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: modulosController,
            enabled: widget.treinamento == null, // ao editar, não muda
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Quantidade de módulos'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Obrigatório'),
            value: obrigatorio,
            onChanged: (valor) => setState(() => obrigatorio = valor),
          ),
          OutlinedButton(
            onPressed: escolherPrazo,
            child: Text(textoPrazo),
          ),
          if (prazo != null)
            TextButton(
              onPressed: () => setState(() => prazo = null),
              child: const Text('REMOVER PRAZO'),
            ),
          const SizedBox(height: 8),
          const Text(
            'A avaliação final usa as perguntas padrão do app.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: salvar,
            child: const Text('SALVAR'),
          ),
        ],
      ),
    );
  }
}

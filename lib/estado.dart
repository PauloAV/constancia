import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'modelos.dart';

// transforma uma data em texto, ex.: 2026-11-19
String chaveDia(DateTime d) {
  final mes = d.month.toString().padLeft(2, '0');
  final dia = d.day.toString().padLeft(2, '0');
  return '${d.year}-$mes-$dia';
}

// perguntas usadas nos treinamentos que o RH cadastra
List<Pergunta> perguntasPadrao() {
  return [
    Pergunta('Qual é a melhor forma de fixar o que você aprendeu?',
        ['Praticar no dia a dia', 'Esquecer o conteúdo', 'Ler só uma vez'], 0),
    Pergunta('O que fazer quando surgir uma dúvida no treinamento?',
        ['Ignorar', 'Perguntar à liderança ou ao RH', 'Pular o módulo'], 1),
    Pergunta('Por que concluir os módulos antes da avaliação?', [
      'Para ganhar tempo',
      'Não faz diferença',
      'Para garantir que o conteúdo foi visto'
    ], 2),
  ];
}

// Guarda todos os dados do app. Quando algo muda, salva no celular
// e avisa as telas (notifyListeners) para se atualizarem.
class AppState extends ChangeNotifier {
  static const chave = 'constancia_dados';

  late Usuario usuario; // o colaborador dono dos dados
  late int prata;
  late int ouro;
  late List<Meta> metas;
  late List<Treinamento> treinamentos;
  late List<Recompensa> recompensas;
  late List<Pedido> pedidos;
  late List<String> diasCompletos; // dias em que todas as metas foram feitas
  late List<String> bonusDias; // dias em que o bônus de 7 dias foi dado
  late int recordeBase;
  late int metasCumpridas;
  late String ultimoDia;

  Usuario? logado; // quem entrou (não é salvo)

  AppState() {
    usarExemplo();
  }

  // ---------- dados de exemplo (iguais aos do Figma) ----------

  void usarExemplo() {
    final hoje = DateTime.now();

    usuario = Usuario(nome: 'Ana Souza', cargo: 'Analista de Compras');
    prata = 84;
    ouro = 2;
    recordeBase = 12;
    metasCumpridas = 47;
    ultimoDia = chaveDia(hoje);
    bonusDias = [];

    // 9 dias seguidos até ontem
    diasCompletos = [
      for (var i = 1; i <= 9; i++)
        chaveDia(DateTime(hoje.year, hoje.month, hoje.day - i)),
    ];

    metas = [
      Meta('Assistir 1 aula do treinamento', feita: true),
      Meta('Estudar 20 minutos', feita: true),
      Meta('Praticar inglês 15 minutos'),
    ];

    treinamentos = [
      Treinamento(
        nome: 'NR-12: Segurança em máquinas',
        horas: 8,
        obrigatorio: true,
        prazo: DateTime(2026, 11, 30),
        modulos: criarModulos([
          'Introdução à NR-12',
          'Riscos em máquinas',
          'Dispositivos de proteção',
          'Sinalização de segurança',
          'Procedimentos de trabalho',
          'Manutenção segura',
          'Bloqueio e etiquetagem',
          'Primeiros socorros',
          'Estudo de caso',
          'Avaliação final',
        ], 9),
        perguntas: [
          Pergunta('Qual é a função das proteções fixas em uma máquina?', [
            'Deixar a máquina mais bonita',
            'Impedir o acesso às zonas de perigo',
            'Reduzir o ruído',
            'Aumentar a velocidade'
          ], 1),
          Pergunta('O que significa bloqueio e etiquetagem?', [
            'Impedir o acionamento da máquina durante a manutenção',
            'Pintar a máquina',
            'Guardar a ferramenta',
            'Registrar o horário de entrada'
          ], 0),
          Pergunta('Antes de fazer manutenção em uma máquina, você deve:', [
            'Manter ela ligada',
            'Pedir a um colega para observar',
            'Desligar, bloquear e etiquetar',
            'Remover a proteção e seguir trabalhando'
          ], 2),
          Pergunta('Se a sinalização de segurança estiver apagada:', [
            'Ignorar',
            'Avisar a liderança para repor',
            'Esperar o fim do turno sem avisar',
            'Retirar a sinalização'
          ], 1),
        ],
        inscrito: true,
      ),
      Treinamento(
        nome: 'Código de conduta',
        horas: 2,
        obrigatorio: true,
        modulos: criarModulos(
            ['Valores', 'Regras', 'Canal de denúncia', 'Avaliação'], 4),
        perguntas: perguntasPadrao(),
        inscrito: true,
        concluido: true,
        nota: 10,
      ),
      Treinamento(
        nome: 'Excel intermediário',
        horas: 12,
        modulos: modulosNumerados(12, 3),
        perguntas: [
          Pergunta('Qual função soma os valores de um intervalo?',
              ['SOMA', 'PROCV', 'MÉDIA'], 0),
          Pergunta('Qual função procura um valor em uma tabela?',
              ['SOMA', 'PROCV', 'MÉDIA'], 1),
          Pergunta('O que faz o filtro de uma planilha?', [
            'Apaga as linhas',
            'Mostra só as linhas que atendem a um critério',
            'Soma as colunas'
          ], 1),
        ],
        inscrito: true,
      ),
      Treinamento(
        nome: 'Comunicação e feedback',
        horas: 4,
        modulos: modulosNumerados(4, 0),
        perguntas: perguntasPadrao(),
      ),
      Treinamento(
        nome: 'Inglês para negócios',
        horas: 20,
        modulos: modulosNumerados(10, 0),
        perguntas: perguntasPadrao(),
      ),
      Treinamento(
        nome: 'Introdução ao Power BI',
        horas: 6,
        modulos: modulosNumerados(6, 0),
        perguntas: perguntasPadrao(),
      ),
    ];

    recompensas = [
      Recompensa('Caneca da empresa', 60),
      Recompensa('Almoço com a liderança', 80),
      Recompensa('Vale-livro', 120),
      Recompensa('Curso externo', 2, ouro: true),
      Recompensa('Meio período de folga', 3, ouro: true),
    ];

    pedidos = [];
  }

  // cria a lista de módulos; os primeiros "feitos" já vêm marcados
  List<Modulo> criarModulos(List<String> nomes, int feitos) {
    return [
      for (var i = 0; i < nomes.length; i++) Modulo(nomes[i], feito: i < feitos),
    ];
  }

  List<Modulo> modulosNumerados(int total, int feitos) {
    final nomes = List.generate(total, (i) => 'Módulo ${i + 1}');
    return criarModulos(nomes, feitos);
  }

  // ---------- salvar e carregar no celular ----------

  Map<String, dynamic> toJson() => {
        'usuario': usuario.toJson(),
        'prata': prata,
        'ouro': ouro,
        'metas': metas.map((m) => m.toJson()).toList(),
        'treinamentos': treinamentos.map((t) => t.toJson()).toList(),
        'recompensas': recompensas.map((r) => r.toJson()).toList(),
        'pedidos': pedidos.map((p) => p.toJson()).toList(),
        'diasCompletos': diasCompletos,
        'bonusDias': bonusDias,
        'recordeBase': recordeBase,
        'metasCumpridas': metasCumpridas,
        'ultimoDia': ultimoDia,
      };

  void lerJson(Map<String, dynamic> json) {
    usuario = Usuario.fromJson(json['usuario']);
    prata = json['prata'];
    ouro = json['ouro'];
    metas = (json['metas'] as List).map((m) => Meta.fromJson(m)).toList();
    treinamentos = (json['treinamentos'] as List)
        .map((t) => Treinamento.fromJson(t))
        .toList();
    recompensas = (json['recompensas'] as List)
        .map((r) => Recompensa.fromJson(r))
        .toList();
    pedidos = (json['pedidos'] as List).map((p) => Pedido.fromJson(p)).toList();
    diasCompletos = List<String>.from(json['diasCompletos']);
    bonusDias = List<String>.from(json['bonusDias']);
    recordeBase = json['recordeBase'];
    metasCumpridas = json['metasCumpridas'];
    ultimoDia = json['ultimoDia'];
  }

  // chamado uma vez no main(), antes de abrir o app
  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString(chave);
    if (texto == null) return; // primeira vez: fica com os dados de exemplo

    try {
      lerJson(jsonDecode(texto));
    } catch (_) {
      usarExemplo(); // dados salvos em formato antigo: volta ao exemplo
    }
    virarDia();
  }

  Future<void> salvar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(chave, jsonEncode(toJson()));
  }

  void mudou() {
    salvar();
    notifyListeners();
  }

  // se o app foi aberto em outro dia, as metas voltam a ficar desmarcadas
  void virarDia() {
    final hoje = chaveDia(DateTime.now());
    if (ultimoDia == hoje) return;

    final ultima = DateTime.parse(ultimoDia);
    recordeBase = max(recordeBase, ofensivaAte(ultima));
    for (final m in metas) {
      m.feita = false;
    }
    ultimoDia = hoje;
  }

  // ---------- metas e ofensiva ----------

  // só as metas que valem hoje (pela frequência)
  List<Meta> get metasDeHoje {
    final fimDeSemana = DateTime.now().weekday >= 6;
    return metas.where((m) {
      if (m.frequencia == 'Dias úteis') return !fimDeSemana;
      if (m.frequencia == 'Fim de semana') return fimDeSemana;
      return true;
    }).toList();
  }

  int get metasFeitasHoje => metasDeHoje.where((m) => m.feita).length;

  bool get todasFeitas =>
      metasDeHoje.isNotEmpty && metasFeitasHoje == metasDeHoje.length;

  // conta os dias seguidos para trás a partir de um dia
  int ofensivaAte(DateTime dia) {
    var data = DateTime(dia.year, dia.month, dia.day);
    if (!diasCompletos.contains(chaveDia(data))) {
      data = DateTime(data.year, data.month, data.day - 1);
    }

    var total = 0;
    while (diasCompletos.contains(chaveDia(data))) {
      total++;
      data = DateTime(data.year, data.month, data.day - 1);
    }
    return total;
  }

  int get ofensiva => ofensivaAte(DateTime.now());

  int get recorde => max(recordeBase, ofensiva);

  bool get bonusHoje => bonusDias.contains(chaveDia(DateTime.now()));

  // marca o dia como completo (e dá o bônus) ou desfaz, conforme as metas
  void atualizarOfensiva() {
    final hoje = chaveDia(DateTime.now());

    if (todasFeitas) {
      if (!diasCompletos.contains(hoje)) {
        diasCompletos.add(hoje);
        if (ofensiva % 7 == 0) {
          prata += 5;
          bonusDias.add(hoje);
        }
      }
    } else if (diasCompletos.contains(hoje)) {
      diasCompletos.remove(hoje);
      if (bonusDias.contains(hoje)) {
        prata -= 5;
        bonusDias.remove(hoje);
      }
    }
  }

  void alternarMeta(Meta meta) {
    meta.feita = !meta.feita;
    prata += meta.feita ? 1 : -1;
    metasCumpridas += meta.feita ? 1 : -1;
    atualizarOfensiva();
    mudou();
  }

  // devolve o texto do erro, ou null se deu certo
  String? adicionarMeta(String nome, String frequencia) {
    if (nome.trim().isEmpty) return 'Digite o nome da meta.';

    final repetida = metas.any((m) => m.nome.toLowerCase() == nome.toLowerCase());
    if (repetida) return 'Já existe uma meta com esse nome.';

    metas.add(Meta(nome, frequencia: frequencia));
    atualizarOfensiva(); // uma meta nova pendente pode desfazer o dia completo
    mudou();
    return null;
  }

  // ---------- treinamentos ----------

  // obrigatório com prazo mais perto primeiro, depois o de mais progresso
  Treinamento? get treinamentoAtual {
    final lista =
        treinamentos.where((t) => t.inscrito && !t.concluido).toList();
    if (lista.isEmpty) return null;

    lista.sort((a, b) {
      if (a.obrigatorio != b.obrigatorio) return a.obrigatorio ? -1 : 1;
      if (a.prazo != null && b.prazo != null) {
        final ordem = a.prazo!.compareTo(b.prazo!);
        if (ordem != 0) return ordem;
      }
      return b.porcentagem.compareTo(a.porcentagem);
    });
    return lista.first;
  }

  int get treinamentosConcluidos =>
      treinamentos.where((t) => t.concluido).length;

  int get horasEstudo => treinamentos
      .where((t) => t.concluido)
      .fold(0, (soma, t) => soma + t.horas);

  void inscrever(Treinamento t) {
    t.inscrito = true;
    mudou();
  }

  void alternarModulo(Treinamento t, int indice) {
    if (t.concluido) return;
    t.modulos[indice].feito = !t.modulos[indice].feito;
    mudou();
  }

  void concluir(Treinamento t, double nota) {
    t.concluido = true;
    t.nota = nota;
    ouro += 1;
    mudou();
  }

  // ---------- recompensas e pedidos ----------

  bool temPedidoPendente(Recompensa r) {
    return pedidos.any((p) => p.recompensa == r.nome && p.status == 'pendente');
  }

  void resgatar(Recompensa r) {
    if (r.ouro) {
      ouro -= r.preco;
    } else {
      prata -= r.preco;
    }
    pedidos.add(Pedido(recompensa: r.nome, preco: r.preco, ouro: r.ouro));
    mudou();
  }

  void aceitarPedido(Pedido p) {
    p.status = 'aceito';
    mudou();
  }

  // recusar devolve as moedas para o colaborador
  void recusarPedido(Pedido p) {
    p.status = 'recusado';
    if (p.ouro) {
      ouro += p.preco;
    } else {
      prata += p.preco;
    }
    mudou();
  }

  // ---------- RH: cadastros ----------

  void cadastrarRecompensa(String nome, int preco, bool ouro) {
    recompensas.add(Recompensa(nome, preco, ouro: ouro));
    mudou();
  }

  void cadastrarTreinamento({
    required String nome,
    required int horas,
    required int qtdModulos,
    required bool obrigatorio,
    DateTime? prazo,
  }) {
    treinamentos.add(Treinamento(
      nome: nome,
      horas: horas,
      obrigatorio: obrigatorio,
      prazo: prazo,
      modulos: modulosNumerados(qtdModulos, 0),
      perguntas: perguntasPadrao(),
      inscrito: obrigatorio, // obrigatório já entra inscrito
    ));
    mudou();
  }

  // ---------- login ----------

  // entra direto, sem e-mail nem senha (só para a demonstração)
  void entrar(String papel) {
    if (papel == 'rh') {
      logado = Usuario(nome: 'Carla Mendes', cargo: 'Analista de RH', papel: 'rh');
    } else {
      logado = usuario;
    }
  }

  void sair() {
    logado = null;
  }
}

final estado = AppState();

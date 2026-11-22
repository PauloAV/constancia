// Cada classe aqui representa uma "coisa" do app.
// O toJson/fromJson serve para salvar e ler os dados no celular.

class Usuario {
  final String nome;
  final String cargo;
  final String papel; // 'colaborador' ou 'rh'

  Usuario({required this.nome, required this.cargo, this.papel = 'colaborador'});

  String get primeiroNome => nome.split(' ').first;

  Map<String, dynamic> toJson() => {'nome': nome, 'cargo': cargo, 'papel': papel};

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      nome: json['nome'],
      cargo: json['cargo'],
      papel: json['papel'],
    );
  }
}

class Meta {
  final String nome;
  final String frequencia; // 'Todo dia', 'Dias úteis' ou 'Fim de semana'
  bool feita;

  Meta(this.nome, {this.frequencia = 'Todo dia', this.feita = false});

  Map<String, dynamic> toJson() =>
      {'nome': nome, 'frequencia': frequencia, 'feita': feita};

  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(json['nome'], frequencia: json['frequencia'], feita: json['feita']);
  }
}

class Modulo {
  final String nome;
  bool feito;

  Modulo(this.nome, {this.feito = false});

  Map<String, dynamic> toJson() => {'nome': nome, 'feito': feito};

  factory Modulo.fromJson(Map<String, dynamic> json) {
    return Modulo(json['nome'], feito: json['feito']);
  }
}

// Pergunta da avaliação final: 'correta' é a posição da resposta certa em 'opcoes'
class Pergunta {
  final String enunciado;
  final List<String> opcoes;
  final int correta;

  Pergunta(this.enunciado, this.opcoes, this.correta);

  Map<String, dynamic> toJson() =>
      {'enunciado': enunciado, 'opcoes': opcoes, 'correta': correta};

  factory Pergunta.fromJson(Map<String, dynamic> json) {
    return Pergunta(
      json['enunciado'],
      List<String>.from(json['opcoes']),
      json['correta'],
    );
  }
}

class Treinamento {
  final String nome;
  final int horas;
  final bool obrigatorio;
  final DateTime? prazo;
  final List<Modulo> modulos;
  final List<Pergunta> perguntas;
  bool inscrito;
  bool concluido;
  double? nota;
  DateTime? concluidoEm;

  Treinamento({
    required this.nome,
    required this.horas,
    required this.modulos,
    required this.perguntas,
    this.obrigatorio = false,
    this.prazo,
    this.inscrito = false,
    this.concluido = false,
    this.nota,
    this.concluidoEm,
  });

  int get modulosFeitos => modulos.where((m) => m.feito).length;

  // o último módulo é a própria avaliação final: só os anteriores liberam o botão
  bool get liberaAvaliacao =>
      modulos.take(modulos.length - 1).every((m) => m.feito);

  // "NR-12: Segurança em máquinas" vira "NR-12" e "Segurança em máquinas"
  String get tituloCurto => nome.contains(': ') ? nome.split(': ').first : nome;

  String? get subtituloNome =>
      nome.contains(': ') ? nome.substring(nome.indexOf(': ') + 2) : null;

  int get porcentagem => (modulosFeitos / modulos.length * 100).round();

  String get textoPrazo {
    if (prazo == null) return '';
    final hoje = DateTime.now();
    final dias =
        prazo!.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
    final dia = prazo!.day.toString().padLeft(2, '0');
    final mes = prazo!.month.toString().padLeft(2, '0');

    if (dias < 0) return 'Prazo $dia/$mes · atrasado';
    if (dias == 0) return 'Prazo $dia/$mes · vence hoje';
    if (dias == 1) return 'Prazo $dia/$mes · falta 1 dia';
    return 'Prazo $dia/$mes · faltam $dias dias';
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'horas': horas,
        'obrigatorio': obrigatorio,
        'prazo': prazo?.toIso8601String(),
        'modulos': modulos.map((m) => m.toJson()).toList(),
        'perguntas': perguntas.map((p) => p.toJson()).toList(),
        'inscrito': inscrito,
        'concluido': concluido,
        'nota': nota,
        'concluidoEm': concluidoEm?.toIso8601String(),
      };

  factory Treinamento.fromJson(Map<String, dynamic> json) {
    return Treinamento(
      nome: json['nome'],
      horas: json['horas'],
      obrigatorio: json['obrigatorio'],
      prazo: json['prazo'] == null ? null : DateTime.parse(json['prazo']),
      modulos: (json['modulos'] as List).map((m) => Modulo.fromJson(m)).toList(),
      perguntas:
          (json['perguntas'] as List).map((p) => Pergunta.fromJson(p)).toList(),
      inscrito: json['inscrito'],
      concluido: json['concluido'],
      nota: (json['nota'] as num?)?.toDouble(),
      concluidoEm: json['concluidoEm'] == null
          ? null
          : DateTime.parse(json['concluidoEm']),
    );
  }
}

class Recompensa {
  final String nome;
  final int preco;
  final bool ouro; // true = custa ouro, false = custa prata

  Recompensa(this.nome, this.preco, {this.ouro = false});

  Map<String, dynamic> toJson() => {'nome': nome, 'preco': preco, 'ouro': ouro};

  factory Recompensa.fromJson(Map<String, dynamic> json) {
    return Recompensa(json['nome'], json['preco'], ouro: json['ouro']);
  }
}

// Pedido de resgate: o RH aceita ou recusa
class Pedido {
  final String recompensa;
  final int preco;
  final bool ouro;
  String status; // 'pendente', 'aceito' ou 'recusado'

  Pedido({
    required this.recompensa,
    required this.preco,
    required this.ouro,
    this.status = 'pendente',
  });

  Map<String, dynamic> toJson() => {
        'recompensa': recompensa,
        'preco': preco,
        'ouro': ouro,
        'status': status,
      };

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      recompensa: json['recompensa'],
      preco: json['preco'],
      ouro: json['ouro'],
      status: json['status'],
    );
  }
}

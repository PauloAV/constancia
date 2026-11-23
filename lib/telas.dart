import 'package:material_ui/material_ui.dart';
import 'estado.dart';
import 'modelos.dart';
import 'tema.dart';

const tituloSecao = TextStyle(fontSize: 16, fontWeight: FontWeight.w500);

void mostrarAviso(BuildContext context, String texto) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
}

// pergunta antes de excluir; devolve true se a pessoa confirmou
Future<bool> confirmar(BuildContext context, String titulo, String texto) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(contexto, false),
          child: const Text('CANCELAR'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(contexto, true),
          child: const Text('EXCLUIR'),
        ),
      ],
    ),
  );
  return resposta ?? false;
}

// menu de três pontinhos de cada meta: editar ou excluir
Future<void> acaoMeta(BuildContext context, Meta meta, String opcao) async {
  if (opcao == 'editar') {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NovaMetaPage(meta: meta)),
    );
    return;
  }

  final ok = await confirmar(
      context, 'Excluir meta?', 'A meta "${meta.nome}" será removida.');
  if (!ok || !context.mounted) return;

  final erro = estado.excluirMeta(meta);
  mostrarAviso(context, erro ?? 'Meta excluída.');
}

String mesAno(DateTime d) {
  const meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez'
  ];
  return '${meses[d.month - 1]}/${d.year}';
}

String formatarNota(double nota) {
  return nota.toStringAsFixed(1).replaceAll('.', ',');
}

class Moedas extends StatelessWidget {
  const Moedas({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, color: prataCor, size: 18),
        const SizedBox(width: 6),
        Text('${estado.prata} prata'),
        const SizedBox(width: 16),
        const Icon(Icons.circle, color: ouroCor, size: 18),
        const SizedBox(width: 6),
        Text('${estado.ouro} ouro'),
      ],
    );
  }
}

class InicioTab extends StatelessWidget {
  const InicioTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final metas = estado.metasDeHoje;
        final feitas = estado.metasFeitasHoje;
        final atual = estado.treinamentoAtual;
        final ofensiva = estado.ofensiva;
        final faltam = 7 - (ofensiva % 7);

        String mensagem;
        if (estado.bonusHoje) {
          mensagem = 'Metas de hoje feitas e bônus de +5 prata recebido!';
        } else if (estado.todasFeitas) {
          mensagem = 'Metas de hoje feitas! Faltam $faltam dias para o bônus de +5 prata.';
        } else if (ofensiva % 7 == 6) {
          mensagem = 'Termine as metas de hoje e ganhe +5 prata de bônus!';
        } else {
          mensagem = 'Termine as metas de hoje para manter a sequência.\n'
              'Faltam $faltam dias para o bônus de +5 prata.';
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Olá, ${estado.usuario.primeiroNome}!',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('$feitas de ${metas.length} metas feitas hoje'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: metas.isEmpty ? 0 : feitas / metas.length,
            ),
            const SizedBox(height: 12),
            const Moedas(),
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFFFFF3E0),
              child: ListTile(
                leading: const Icon(Icons.local_fire_department,
                    color: laranja, size: 32),
                title: Text(ofensiva == 0
                    ? 'Comece sua sequência de estudos hoje!'
                    : 'Você está há $ofensiva dias seguidos estudando!'),
                subtitle: Text(mensagem),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Metas de hoje', style: tituloSecao),
            Card(
              child: metas.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'Nenhuma meta para hoje. Toque no + para criar uma.'),
                    )
                  : Column(
                      children: [
                        for (final meta in metas)
                          CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            value: meta.feita,
                            title: Text(meta.nome),
                            subtitle: const Text('Vale 1 moeda de prata'),
                            secondary: PopupMenuButton<String>(
                              onSelected: (opcao) => acaoMeta(context, meta, opcao),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'editar', child: Text('Editar')),
                                PopupMenuItem(value: 'excluir', child: Text('Excluir')),
                              ],
                            ),
                            onChanged: (_) {
                              final erro = estado.alternarMeta(meta);
                              if (erro != null) {
                                mostrarAviso(context, erro);
                                return;
                              }
                              mostrarAviso(
                                context,
                                meta.feita
                                    ? 'Meta feita! Você ganhou 1 moeda de prata.'
                                    : 'Meta desmarcada. A moeda foi devolvida.',
                              );
                            },
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
            const Text('Treinamento atual', style: tituloSecao),
            Card(
              child: atual == null
                  ? const ListTile(
                      title: Text('Nenhum treinamento em andamento'),
                      subtitle: Text(
                          'Inscreva-se em um treinamento na aba Treinamentos.'),
                    )
                  : ListTile(
                      title: Text(atual.nome),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${atual.obrigatorio ? "Obrigatório · ${atual.textoPrazo}" : "Opcional"}\n'
                              '${atual.porcentagem}% · ${atual.modulosFeitos} de ${atual.modulos.length} módulos'),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: atual.modulosFeitos / atual.modulos.length,
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DetalhePage(atual)),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class NovaMetaPage extends StatefulWidget {
  final Meta? meta; // se vier preenchida, a tela edita essa meta

  const NovaMetaPage({super.key, this.meta});

  @override
  State<NovaMetaPage> createState() => _NovaMetaPageState();
}

class _NovaMetaPageState extends State<NovaMetaPage> {
  late final TextEditingController nomeController;
  late String frequencia;

  @override
  void initState() {
    super.initState();
    nomeController = TextEditingController(text: widget.meta?.nome ?? '');
    frequencia = widget.meta?.frequencia ?? 'Todo dia';
  }

  @override
  void dispose() {
    nomeController.dispose();
    super.dispose();
  }

  void salvar() {
    final nome = nomeController.text.trim();
    final erro = widget.meta == null
        ? estado.adicionarMeta(nome, frequencia)
        : estado.editarMeta(widget.meta!, nome, frequencia);
    if (erro != null) {
      mostrarAviso(context, erro);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.meta == null ? 'Nova meta' : 'Editar meta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome da meta',
                hintText: 'Ex.: Fazer 1 exercício de Excel',
              ),
            ),
            const SizedBox(height: 24),
            const Text('Frequência'),
            DropdownButton<String>(
              value: frequencia,
              isExpanded: true,
              items: ['Todo dia', 'Dias úteis', 'Fim de semana']
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (valor) => setState(() => frequencia = valor!),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cada dia em que você cumprir esta meta vale 1 moeda de prata.',
              style: TextStyle(color: Colors.black54),
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

class TreinamentosTab extends StatelessWidget {
  const TreinamentosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        final obrigatorios =
            estado.treinamentos.where((t) => t.obrigatorio).toList();
        final opcionais =
            estado.treinamentos.where((t) => !t.obrigatorio).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Obrigatórios',
                style: TextStyle(color: laranja, fontWeight: FontWeight.w500)),
            Card(
              child: Column(
                children: [for (final t in obrigatorios) itemLista(context, t)],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Opcionais',
                style: TextStyle(fontWeight: FontWeight.w500)),
            Card(
              child: Column(
                children: [for (final t in opcionais) itemLista(context, t)],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget itemLista(BuildContext context, Treinamento t) {
    if (!t.inscrito) {
      return ListTile(
        title: Text(t.nome),
        subtitle: Text('${t.horas} h · vale 1 ouro'),
        trailing: OutlinedButton(
          child: const Text('INSCREVER-SE'),
          onPressed: () {
            estado.inscrever(t);
            mostrarAviso(context, 'Inscrição feita: ${t.nome}');
          },
        ),
      );
    }

    return ListTile(
      title: Text(t.nome,
          style: TextStyle(color: t.concluido ? verde : null)),
      isThreeLine: true,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              '${t.porcentagem}% concluído · ${t.horas} h · ${t.concluido ? "1 ouro recebido" : "vale 1 ouro"}'),
          if (t.prazo != null && !t.concluido)
            Text(t.textoPrazo,
                style: const TextStyle(
                    color: laranja, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: t.modulosFeitos / t.modulos.length,
            color: t.concluido ? verde : azul,
          ),
        ],
      ),
      trailing: t.concluido
          ? const Icon(Icons.check, color: verde)
          : const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetalhePage(t)),
        );
      },
    );
  }
}

class DetalhePage extends StatelessWidget {
  final Treinamento t;

  const DetalhePage(this.t, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.tituloCurto),
            if (t.subtituloNome != null)
              Text(t.subtituloNome!,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: estado,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (t.obrigatorio)
                Text('Obrigatório · ${t.textoPrazo}',
                    style: const TextStyle(
                        color: laranja, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                  '${t.porcentagem}% concluído · ${t.horas} h · ${t.modulosFeitos} de ${t.modulos.length} módulos'),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: t.modulosFeitos / t.modulos.length,
              ),
              const SizedBox(height: 16),
              const Text('Módulos', style: tituloSecao),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < t.modulos.length; i++)
                      CheckboxListTile(
                        value: t.modulos[i].feito,
                        title: Text('${i + 1}. ${t.modulos[i].nome}'),
                        // o último módulo é a avaliação final: não se marca à mão
                        onChanged: (t.concluido || i == t.modulos.length - 1)
                            ? null
                            : (_) => estado.alternarModulo(t, i),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (t.concluido || !t.liberaAvaliacao)
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AvaliacaoPage(t)),
                        );
                      },
                child: const Text('FAZER AVALIAÇÃO FINAL'),
              ),
              if (!t.liberaAvaliacao && !t.concluido)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Conclua os módulos anteriores para liberar a avaliação final.',
                      style: TextStyle(color: Colors.black54)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AvaliacaoPage extends StatefulWidget {
  final Treinamento t;

  const AvaliacaoPage(this.t, {super.key});

  @override
  State<AvaliacaoPage> createState() => _AvaliacaoPageState();
}

class _AvaliacaoPageState extends State<AvaliacaoPage> {
  late List<int?> respostas;
  double? nota; // só preenchida quando a pessoa foi reprovada

  @override
  void initState() {
    super.initState();
    respostas = List<int?>.filled(widget.t.perguntas.length, null);
  }

  void enviar() {
    final t = widget.t;

    var acertos = 0;
    for (var i = 0; i < t.perguntas.length; i++) {
      if (respostas[i] == t.perguntas[i].correta) acertos++;
    }
    final resultado = acertos / t.perguntas.length * 10;

    if (resultado >= 7) {
      estado.concluir(t, resultado);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ConcluidoPage(t)),
      );
    } else {
      setState(() => nota = resultado);
    }
  }

  void refazer() {
    setState(() {
      respostas = List<int?>.filled(widget.t.perguntas.length, null);
      nota = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

    return Scaffold(
      appBar: AppBar(title: const Text('Avaliação final')),
      body: nota != null ? resultadoReprovado() : perguntas(t),
    );
  }

  Widget perguntas(Treinamento t) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(t.nome, style: tituloSecao),
        const SizedBox(height: 4),
        const Text('Acerte pelo menos nota 7 para concluir e ganhar 1 ouro.'),
        const SizedBox(height: 12),
        for (var i = 0; i < t.perguntas.length; i++)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Text('${i + 1}. ${t.perguntas[i].enunciado}',
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  for (var j = 0; j < t.perguntas[i].opcoes.length; j++)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        respostas[i] == j
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: azul,
                      ),
                      title: Text(t.perguntas[i].opcoes[j]),
                      onTap: () => setState(() => respostas[i] = j),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: respostas.contains(null) ? null : enviar,
          child: const Text('ENVIAR RESPOSTAS'),
        ),
      ],
    );
  }

  Widget resultadoReprovado() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cancel, color: laranja, size: 80),
          const SizedBox(height: 16),
          Text('Sua nota: ${formatarNota(nota!)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Você precisa de 7 ou mais para concluir. Tente de novo!',
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: refazer,
            child: const Text('REFAZER AVALIAÇÃO'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('VOLTAR AO TREINAMENTO'),
          ),
        ],
      ),
    );
  }
}

class ConcluidoPage extends StatelessWidget {
  final Treinamento t;

  const ConcluidoPage(this.t, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Treinamento concluído')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: verde, size: 80),
            const SizedBox(height: 16),
            Text('Parabéns, ${estado.usuario.primeiroNome}!',
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Text('Você concluiu ${t.nome}.', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Chip(
              avatar: Icon(Icons.circle, color: ouroCor),
              label: Text('+1 moeda de ouro'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Nota'),
                    trailing: Text(
                        t.nota == null ? '-' : formatarNota(t.nota!),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    title: const Text('Módulos'),
                    trailing: Text('${t.modulos.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    title: const Text('Horas'),
                    trailing: Text('${t.horas} h',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () =>
                  mostrarAviso(context, 'Certificado baixado: ${t.nome}'),
              child: const Text('CERTIFICADO DE CONCLUSÃO'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.popUntil(context, (rota) => rota.isFirst),
              child: const Text('VOLTAR AO INÍCIO'),
            ),
          ],
        ),
      ),
    );
  }
}

class RecompensasTab extends StatelessWidget {
  const RecompensasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: estado,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Moedas(),
            const SizedBox(height: 16),
            const Text('Como ganhar mais moedas', style: tituloSecao),
            const SizedBox(height: 4),
            const Text('• 1 prata por meta de estudo cumprida, todo dia.\n'
                '• A cada 7 dias seguidos, +5 prata de bônus.\n'
                '• 1 ouro por treinamento concluído.'),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  for (final r in estado.recompensas) itemLista(context, r),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'As recompensas são cadastradas pelo RH, que confirma cada pedido.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        );
      },
    );
  }

  Widget itemLista(BuildContext context, Recompensa r) {
    final saldo = r.ouro ? estado.ouro : estado.prata;
    final falta = r.preco - saldo;
    final moeda = r.ouro ? 'ouro' : 'prata';
    final pendente = estado.temPedidoPendente(r);
    final podeResgatar = !pendente && falta <= 0;

    String subtitulo;
    if (pendente) {
      subtitulo = 'Pedido enviado ao RH';
    } else if (falta > 0) {
      subtitulo = '${r.preco} $moeda · faltam $falta';
    } else {
      subtitulo = '${r.preco} $moeda';
    }

    return ListTile(
      title: Text(r.nome),
      subtitle: Text(subtitulo),
      trailing: ElevatedButton(
        onPressed: podeResgatar
            ? () {
                estado.resgatar(r);
                mostrarAviso(context, 'Pedido enviado: ${r.nome}');
              }
            : null,
        child: Text(pendente ? 'PEDIDO' : 'RESGATAR'),
      ),
    );
  }
}

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: ListenableBuilder(
        listenable: estado,
        builder: (context, _) {
          final concluidos =
              estado.treinamentos.where((t) => t.concluido).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ListTile(
                leading: CircleAvatar(child: Text(estado.usuario.nome[0])),
                title: Text(estado.usuario.nome),
                subtitle: Text(estado.usuario.cargo),
              ),
              const SizedBox(height: 8),
              const Text('Estatísticas do mês', style: tituloSecao),
              Card(
                child: Column(
                  children: [
                    linha('Dias seguidos estudando', '${estado.ofensiva} dias'),
                    linha('Recorde de dias seguidos', '${estado.recorde} dias'),
                    linha('Horas de estudo', '${estado.horasEstudo} h'),
                    linha('Metas cumpridas', '${estado.metasCumpridas}'),
                    linha('Treinamentos concluídos', '${concluidos.length}'),
                    linha('Moedas',
                        '${estado.prata} prata · ${estado.ouro} ouro'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Certificados', style: tituloSecao),
              Card(
                child: concluidos.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Nenhum certificado ainda.'),
                      )
                    : Column(
                        children: [
                          for (final t in concluidos)
                            ListTile(
                              title: Text(t.nome),
                              subtitle: t.concluidoEm == null
                                  ? null
                                  : Text('Concluído em ${mesAno(t.concluidoEm!)}'),
                              trailing: TextButton(
                                child: const Text('BAIXAR'),
                                onPressed: () => mostrarAviso(
                                    context, 'Certificado baixado: ${t.nome}'),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  estado.sair();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (rota) => false);
                },
                child: const Text('SAIR'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget linha(String nome, String valor) {
    return ListTile(
      title: Text(nome),
      trailing:
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

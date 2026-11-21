# Constância

App de metas de estudo e treinamentos da empresa, com moedas e recompensas.

Equipe: Paulo (gestão), Kauan (UI/UX) e Hudson (código).

## Como rodar
1. `flutter pub get`
2. `flutter run`

Na tela de login dá para entrar como colaborador ou como RH. O login não confere e-mail nem senha (é só para a demonstração).

## Arquivos
- `lib/main.dart`: abre o app, carrega os dados salvos, define as rotas e a barra de baixo.
- `lib/tema.dart`: cores e tema do guia.
- `lib/modelos.dart`: classes Usuario, Meta, Modulo, Pergunta, Treinamento, Recompensa e Pedido (com toJson/fromJson).
- `lib/estado.dart`: dados de exemplo, regras das moedas e salvar/carregar no celular.
- `lib/telas.dart`: telas do colaborador (início, nova meta, treinamentos, detalhe, avaliação, concluído, recompensas e perfil).
- `lib/telas_rh.dart`: login e painel do RH (pedidos, recompensas e treinamentos).
- `test/widget_test.dart`: teste que abre o app e entra como colaborador.

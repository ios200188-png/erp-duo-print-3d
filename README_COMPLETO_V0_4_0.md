# ERP Duo Print 3D — Founders Edition 0.4.0

## Módulos funcionais

- Dashboard
- Clientes
- Filamentos
- Impressoras
- Projetos
- Orçamentos
- Produção
- Financeiro
- Configurações de custos
- Identidade visual da Duo Print 3D

## Produção

- criação de ordem de produção;
- seleção de projeto e impressora;
- quantidade planejada e produzida;
- prioridade;
- data prevista;
- status: Planejada, Imprimindo, Pausada, Finalizada e Cancelada;
- progresso visual;
- ordens abertas no Dashboard.

## Financeiro

- receitas e despesas;
- contas pendentes e pagas;
- vencimento;
- categorias;
- caixa atual;
- a receber;
- a pagar;
- despesas pagas;
- indicadores no Dashboard.

## Instalação limpa

1. Faça backup do projeto.
2. Apague:
   - `lib`
   - `lib_2`
   - `lib_old`
   - `lib_old2`
3. Copie deste pacote:
   - `lib`
   - `assets`
   - `android`
   - `pubspec.yaml`
4. Apague `test/widget_test.dart`, caso exista.
5. Execute:

```cmd
flutter clean
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter analyze
flutter run
```

## Banco

As novas tabelas são criadas automaticamente ao abrir o app:

- `production_orders`
- `financial_entries`

Não é necessário apagar os cadastros existentes. Caso o app pare na logo por causa de um banco antigo de testes, desinstale o app e execute `flutter run` novamente.

## Git

```cmd
git add .
git commit -m "feat: adiciona producao e financeiro v0.4.0"
git push
```

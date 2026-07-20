# ERP Duo Print 3D — Founders Edition 0.5.0

## Fluxo completo implementado

Orçamento
→ Aprovação
→ Ordem de produção automática
→ Produção finalizada
→ Faturamento
→ PDF para o cliente
→ Conta a receber
→ Pagamento
→ Caixa

## Aprovação do orçamento

Na lista de orçamentos, toque em **Aprovar**.

O sistema:
- muda o orçamento para `Aprovado`;
- cria uma ordem de produção automaticamente;
- envia a quantidade e o projeto para Produção.

## Finalização da produção

Ao alterar uma ordem para `Finalizada`:
- a quantidade produzida é concluída;
- o orçamento passa para `Produzido`;
- o pedido aparece em `Faturamento`.

## Faturamento

Informe:
- forma de pagamento;
- vencimento;
- observações.

Ao emitir:
- uma fatura é criada;
- o orçamento passa para `Faturado`;
- uma conta a receber é criada no Financeiro.

## PDF

O PDF contém:
- logo e dados da Duo Print 3D;
- CNPJ/CPF, endereço, cidade, WhatsApp e e-mail;
- dados do cliente;
- produto;
- quantidade;
- valor;
- forma de pagamento;
- vencimento;
- observações.

O PDF pode ser enviado pelo compartilhamento do Android, incluindo WhatsApp.

> O documento é uma fatura comercial e não substitui nota fiscal.

## Configuração inicial

Abra:
`Ajustes → Parâmetros de custos`

Preencha também os dados da empresa que serão exibidos no PDF.

## Instalação

1. Faça backup.
2. Apague `lib`, `lib_2`, `lib_old` e `lib_old2`.
3. Copie:
   - `lib`
   - `assets`
   - `android`
   - `pubspec.yaml`
4. Execute:

```cmd
flutter clean
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter analyze
flutter run
```

## Teste recomendado

1. Crie um orçamento.
2. Salve.
3. Aprove.
4. Abra Produção.
5. Marque a ordem como Finalizada.
6. Abra Faturamento.
7. Emita a fatura.
8. Abra o menu da fatura e selecione Enviar PDF.
9. Marque como pago.
10. Confira o caixa no Dashboard.

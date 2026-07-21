# Orçamento com múltiplos produtos e desconto

Esta versão adiciona:

- vários produtos/serviços no mesmo orçamento;
- quantidade e preço unitário por item;
- desconto percentual ou em valor (R$);
- subtotal, desconto e total líquido;
- PDF com todos os itens;
- uma ordem de produção para cada item ao aprovar o orçamento;
- compatibilidade automática com orçamentos antigos.

## Atualização

Execute:

```bash
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter run
```

Na primeira abertura, a tabela `quote_items` e as novas colunas de desconto são criadas automaticamente.

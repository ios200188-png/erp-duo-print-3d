# ERP Duo Print 3D — Correção 0.5.3

## Correção do fluxo Produção → Faturamento

Ao finalizar uma ordem vinculada a um orçamento aprovado, o aplicativo agora:

- muda o orçamento para `Produzido`;
- atualiza imediatamente a lista de orçamentos;
- limpa o cache da lista de faturamento;
- atualiza o contador `A faturar`;
- faz o pedido aparecer em Faturamento sem reiniciar o app.

## Regra importante

Somente ordens criadas automaticamente ao aprovar um orçamento possuem vínculo com o cliente, valor e produto necessários para faturamento.

Uma ordem criada manualmente em Produção não aparece automaticamente no Faturamento.

## Teste

1. Crie um orçamento.
2. Salve.
3. Clique em Aprovar.
4. Abra Produção.
5. Finalize a ordem criada automaticamente.
6. Abra Faturamento.
7. O pedido deverá aparecer em Prontos para faturar.

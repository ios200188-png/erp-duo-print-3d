# ERP Duo Print 3D — Versão 0.6.0 Gestão Profissional

## Dashboard Premium

- faturamento do mês;
- lucro do mês;
- caixa atual;
- contas a receber;
- contas a pagar;
- produção aberta;
- ordens imprimindo;
- pedidos aguardando faturamento;
- pedidos do mês;
- ticket médio;
- estoque baixo;
- financeiro vencido;
- despesas do mês;
- agenda do dia.

## Produção Kanban

A produção agora possui quatro colunas:

- Planejada
- Imprimindo
- Pausada
- Finalizada

Cada cartão mostra:

- projeto;
- impressora;
- prioridade;
- quantidade;
- progresso;
- observações.

O status pode ser alterado pelo menu do cartão.

## Agenda Inteligente

A agenda reúne automaticamente:

- entregas dos próximos 30 dias;
- contas a receber;
- contas a pagar;
- manutenção de impressoras;
- estoque baixo.

## Instalação limpa

1. Faça backup do projeto.
2. Apague:
   - `lib`
   - `lib_2`
   - `lib_old`
   - `lib_old2`
3. Copie do pacote:
   - `lib`
   - `assets`
   - `android`
   - `pubspec.yaml`
4. Execute:

```cmd
flutter clean
flutter pub get
flutter analyze
flutter run
```

## Observação sobre entregas

A estrutura do banco já possui o campo `delivery_date` nos orçamentos. A tela para definir a data diretamente no orçamento será expandida na versão 0.6.1.

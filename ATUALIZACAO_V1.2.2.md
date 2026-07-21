# ERP Duo Print 3D v1.2.2

Esta atualização reúne em um único projeto:

- correção do overflow no campo "Tipo de desconto" do orçamento;
- correção de caracteres incompatíveis nos PDFs de orçamento e faturamento;
- novo campo "Observação padrão para orçamento e faturamento" em Configurações;
- carregamento automático da observação padrão ao criar orçamento;
- carregamento automático da observação padrão ao emitir faturamento;
- migração automática da coluna `default_observation` no banco local existente.

## Atualização

Execute:

```cmd
flutter clean
flutter pub get
dart format lib
flutter analyze
flutter run
```

A observação pode ser alterada em cada orçamento ou faturamento sem modificar o texto padrão salvo nas configurações.

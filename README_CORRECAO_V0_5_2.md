# ERP Duo Print 3D — Correção 0.5.2

Correções no serviço de PDF:

- removido `const` dos estilos que usam `PdfColor.fromHex`;
- adicionado `const` aos três estilos formados apenas por valores constantes;
- versão atualizada para 0.5.2.

## Instalação

Copie `lib` e `pubspec.yaml` sobre o projeto atual e execute:

```cmd
flutter clean
flutter pub get
flutter analyze
flutter run
```

# ERP Duo Print 3D — Correção 0.4.2

Correção dos dois avisos restantes de `BuildContext`:

- `finance_form_page.dart`
- `production_form_page.dart`

Como essas telas usam `ConsumerState`, a verificação correta é:

```dart
if (!mounted) return;
context.go('/rota');
```

## Instalação

Copie `lib` e `pubspec.yaml` sobre o projeto e execute:

```cmd
flutter clean
flutter pub get
flutter analyze
flutter run
```

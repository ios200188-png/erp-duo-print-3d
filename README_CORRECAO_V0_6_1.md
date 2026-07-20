# ERP Duo Print 3D — Correção 0.6.1

Correção dos erros:

- `Variable` não definido em `AgendaRepository`
- `Variable` não definido em `DashboardRepository`

Foi adicionado:

```dart
import 'package:drift/drift.dart';
```

nos arquivos:

- `lib/features/agenda/data/agenda_repository.dart`
- `lib/features/dashboard/data/dashboard_repository.dart`

Depois de copiar os arquivos, execute:

```cmd
flutter clean
flutter pub get
flutter analyze
flutter run
```

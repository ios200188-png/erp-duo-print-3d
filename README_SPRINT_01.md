# ERP DUO PRINT 3D — Sprint 01A

Esta entrega substitui a pasta `lib` e o arquivo `pubspec.yaml` do projeto atual.

## Instalação no Windows

1. Faça uma cópia de segurança da pasta atual.
2. Extraia este ZIP.
3. Copie `lib` e `pubspec.yaml` para a raiz do seu projeto Flutter.
4. Apague `test/widget_test.dart` caso ele tenha sido recriado pelo Flutter.
5. Execute:

```cmd
flutter clean
flutter pub get
flutter analyze
flutter run
```

## Implementado

- Material Design 3 em tema escuro;
- identidade visual inicial da Duo Print 3D;
- Riverpod;
- GoRouter;
- navegação inferior;
- Dashboard;
- módulo inicial de clientes;
- módulo inicial de configurações;
- organização por `core`, `features` e `shared`.

## Próxima etapa

Sprint 01B:
- banco local com Drift/SQLite;
- cadastro, edição e exclusão de clientes;
- validação de formulários;
- dados reais alimentando o Dashboard.

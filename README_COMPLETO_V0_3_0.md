# ERP DUO PRINT 3D — Versão Completa 0.3.0

Este pacote contém todos os arquivos da versão atual em uma única entrega.

## Módulos incluídos

- Dashboard
- Clientes
- Filamentos
- Impressoras
- Projetos
- Configurações do negócio
- Motor de custos
- Orçamentos salvos
- SQLite local
- Riverpod
- GoRouter
- Material Design 3

## Instalação limpa recomendada

1. Feche o Flutter e o editor.
2. Faça backup da pasta atual.
3. Apague estas pastas antigas, caso existam:
   - lib
   - lib_2
   - lib_old
   - lib_old2
4. Copie deste pacote:
   - lib
   - pubspec.yaml
5. Apague `test/widget_test.dart`, caso exista.
6. Execute:

```cmd
flutter clean
flutter pub get
flutter analyze
flutter run
```

## Se o aplicativo parar na logo

Desinstale a versão de teste do celular e execute novamente:

```cmd
flutter run
```

Isso recria o banco local com todas as tabelas.

## Fluxo de teste

1. Cadastre um cliente.
2. Cadastre um filamento.
3. Cadastre uma impressora.
4. Cadastre um projeto.
5. Abra Ajustes > Parâmetros de custos.
6. Salve os valores.
7. Abra Orçamentos > Novo orçamento.
8. Selecione cliente, projeto e filamento.
9. Calcule e salve.
10. Confira o orçamento na lista e no Dashboard.

## Git

```cmd
git add .
git commit -m "feat: entrega completa erp duo print 3d v0.3.0"
git push
```

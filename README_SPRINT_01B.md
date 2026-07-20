# ERP DUO PRINT 3D — Sprint 01B

## Entrega

- banco SQLite local usando Drift;
- cadastro de clientes;
- edição;
- exclusão com confirmação;
- pesquisa;
- validação;
- total de clientes no Dashboard;
- funcionamento offline.

## Instalação

1. Feche o aplicativo e o editor.
2. Faça uma cópia de segurança do projeto.
3. Apague a pasta `lib` atual.
4. Copie para a raiz do projeto:
   - `lib`
   - `pubspec.yaml`
5. Apague `test/widget_test.dart`, caso exista.
6. Execute:

```cmd
flutter clean
flutter pub get
flutter analyze
flutter run
```

## Git

```cmd
git add .
git commit -m "feat: adiciona banco local e CRUD de clientes"
git push
```

## Teste sugerido

1. Abra Clientes.
2. Cadastre dois clientes.
3. Pesquise por nome.
4. Edite um cadastro.
5. Exclua um cadastro.
6. Volte ao Dashboard e confira o total.

# ERP DUO PRINT 3D — Sprint 02

## Implementado

- CRUD de Filamentos;
- cálculo automático do custo por grama;
- alerta de estoque mínimo;
- CRUD de Impressoras;
- controle de horas e próxima manutenção;
- CRUD de Projetos;
- peso, tempo, material, infill, camada, bico e preço;
- Dashboard integrado;
- menu de módulos;
- banco SQLite atualizado;
- funcionamento offline.

## Instalação

1. Faça backup do projeto.
2. Apague somente a pasta `lib`.
3. Copie deste pacote:
   - `lib`
   - `pubspec.yaml`
4. Execute:

```cmd
flutter clean
flutter pub get
flutter analyze
flutter run
```

## Testes

1. Cadastre um filamento PLA Preto com 1000 g e R$ 89,90.
2. Cadastre uma impressora Bambu A1.
3. Cadastre um projeto com peso e tempo de impressão.
4. Confira os totais no Dashboard.
5. Reduza o peso restante do filamento abaixo do estoque mínimo e confira o alerta.

## Git

```cmd
git add .
git commit -m "feat: adiciona filamentos impressoras e projetos"
git push
```

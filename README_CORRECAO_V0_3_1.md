# ERP Duo Print 3D — Correção 0.3.1

Correções:
- textos com `R\$` ajustados em Filamentos, Impressoras e Projetos;
- import não utilizado removido;
- avisos de underscores desnecessários reduzidos;
- uso de `BuildContext` após operação assíncrona corrigido;
- versão atualizada para 0.3.1.

## Instalação recomendada

1. Faça backup.
2. Apague as pastas `lib`, `lib_2`, `lib_old` e `lib_old2`, caso existam.
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

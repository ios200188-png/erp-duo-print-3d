# ERP Duo Print 3D — Correção 0.4.1

Correções:
- imports não utilizados removidos;
- uso de BuildContext após operações assíncronas corrigido;
- versão atualizada para 0.4.1.

## Instalação

1. Faça backup do projeto.
2. Apague `lib`, `lib_2`, `lib_old` e `lib_old2`, caso existam.
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

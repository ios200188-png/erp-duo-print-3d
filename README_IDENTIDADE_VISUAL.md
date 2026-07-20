# Identidade visual — ERP Duo Print 3D

## Arquivos incluídos

- `assets/branding/app_icon.png`: ícone principal Android.
- `assets/branding/adaptive_foreground.png`: camada frontal do ícone adaptativo.
- `assets/branding/adaptive_background.png`: fundo azul da marca.
- `assets/branding/splash_logo.png`: logo usada na abertura.
- `assets/branding/logo_duo_print_3d.png`: logo para telas internas.
- `pubspec.yaml`: dependências e configurações prontas.
- `android/app/src/main/AndroidManifest.xml`: nome do aplicativo ajustado.

## Paleta da marca

- Azul principal: `#1260DC`
- Azul escuro: `#0B3F9E`
- Preto: `#111111`
- Fundo escuro do ERP: `#0D0D12`
- Branco: `#FFFFFF`

## Instalação

1. Faça backup do projeto.
2. Copie `assets`, `pubspec.yaml` e `android` sobre o projeto atual.
3. Confirme a substituição dos arquivos.
4. Execute:

```cmd
flutter clean
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
flutter analyze
flutter run
```

## Se o ícone antigo continuar aparecendo

Desinstale o aplicativo do celular e rode novamente:

```cmd
flutter run
```

Alguns launchers Android mantêm o ícone antigo em cache.

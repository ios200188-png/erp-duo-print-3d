# ERP Duo Print 3D — Orçamento em PDF 0.5.4

## Novas opções

Na lista de Orçamentos, abra o menu de três pontos:

- Imprimir orçamento
- Enviar PDF
- Aprovar
- Faturar, quando produzido

## Conteúdo do orçamento

- logo da Duo Print 3D;
- dados da empresa;
- dados do cliente;
- produto e versão;
- material;
- quantidade;
- valor total;
- data de emissão;
- validade de 15 dias;
- observações.

## Impressão

A opção `Imprimir orçamento` abre a tela de impressão do Android.

A opção `Enviar PDF` abre o compartilhamento do Android para WhatsApp, e-mail, Drive e outros aplicativos.

## Configuração

Preencha os dados da empresa em:

`Ajustes → Parâmetros de custos`

## Instalação

Copie `lib` e `pubspec.yaml` sobre o projeto atual:

```cmd
flutter clean
flutter pub get
flutter analyze
flutter run
```

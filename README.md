# ERP Duo Print 3D — Founders Edition

Primeira base funcional do aplicativo Android em Flutter.

## Incluído
- Dashboard inicial premium em tema escuro;
- cadastro básico de clientes em memória;
- estoque inicial de filamentos;
- motor real de cálculo de orçamento;
- custos de material, energia, mão de obra, máquina, embalagem e falhas;
- preços econômico, ideal e premium com arredondamento comercial;
- tela de configurações do negócio.

## Como executar
1. Instale Flutter e Android Studio.
2. Abra esta pasta em um terminal.
3. Execute `flutter create . --platforms=android` para gerar a pasta Android nativa.
4. Execute `flutter pub get`.
5. Conecte o celular com depuração USB ou abra um emulador.
6. Execute `flutter run`.
7. Para o APK: `flutter build apk --release`.

## Próxima evolução técnica
- persistência SQLite;
- edição das configurações;
- projetos, pedidos e ordens de produção;
- geração de PDF e compartilhamento;
- financeiro e dashboard com dados reais.

# ERP Duo Print 3D Cloud v1.1.0

## 1. Preparar o Supabase

1. Abra o projeto Supabase.
2. Acesse **SQL Editor**.
3. Copie todo o conteúdo de `supabase/cloud_setup.sql`.
4. Clique em **Run**.
5. Em **Authentication > Providers > Email**, mantenha Email habilitado.
6. Para testes rápidos, você pode desabilitar temporariamente a confirmação de e-mail. Em produção, mantenha a confirmação habilitada.

## 2. Executar o aplicativo

As configurações padrão já apontam para o projeto informado. Para não manter a chave no código, você também pode compilar assim:

```cmd
flutter run --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=SUA_CHAVE_PUBLICAVEL
```

APK:

```cmd
flutter build apk --release --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=SUA_CHAVE_PUBLICAVEL
```

## 3. Primeiro uso

1. Abra o aplicativo.
2. Toque em **Criar minha conta administradora**.
3. Cadastre e-mail e senha.
4. Confirme o e-mail, se essa opção estiver ativa no Supabase.
5. Entre no aplicativo.

## 4. Levar os dados para outro aparelho

No aparelho principal:

1. Abra **Ajustes > Nuvem e sincronização**.
2. Toque em **Enviar dados deste aparelho**.

No celular ou tablet:

1. Entre com a mesma conta.
2. Abra **Ajustes > Nuvem e sincronização**.
3. Toque em **Baixar dados para este aparelho**.
4. Feche e abra o aplicativo novamente.

## Limitação desta etapa

A v1.1.0 usa sincronização manual por snapshot. Não edite dados simultaneamente em dois aparelhos. A sincronização por registro e em tempo real será a próxima evolução.

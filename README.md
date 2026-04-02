# adcp-gcloud-deploy

## 概要
このプロジェクトは、Ad Context Protocol (AdCP) のサーバーを Google Cloud Run にデプロイするためのリポジトリです。自動化された CI/CD パイプラインを構築し、PostgreSQL データベースのバックアップ機能を提供します。

## 背景
このプロジェクトは、広告コンテキストプロトコルの実装を対象としており、活発に更新される `adcontextprotocol/adcp` リポジトリを元にしています。開発者が迅速に環境を構築し、テストを行えるようにするために設計されました。Google Cloudのサービスを利用することで、高可用性と効率的なリソース管理が可能です。

## 必要条件
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install) のインストール
- Docker のインストール
- GitHub アカウント

## 環境変数の設定
リポジトリのルートに `.env`ファイルを作成し、次の環境変数を設定してください。

```
GCP_PROJECT_ID=your-gcp-project-id
GCP_SA_KEY=your-service-account-key-in-json-format
```

## セットアップ
Google Cloud 環境の設定を行うためのスクリプトを実行します。

1. `setup.sh` スクリプトを作成し、以下の内容を記述します。
   
   ```bash
   #!/bin/bash
   
   # Google Cloud SDKのインストールを確認
   if ! command -v gcloud &> /dev/null; then
       echo "Google Cloud SDKがインストールされていません。インストールしてください。"
       exit 1
   fi
   
   # プロジェクトの設定
   gcloud config set project $GCP_PROJECT_ID
   
   # サービスアカウントの認証
   echo $GCP_SA_KEY > ${HOME}/gcp-key.json
   gcloud auth activate-service-account --key-file=${HOME}/gcp-key.json
   
   echo "Google Cloudのセットアップが完了しました。"
   ```

2. スクリプトを実行して Google Cloud の設定を行います。
   ```bash
   bash setup.sh
   ```

## デプロイ
GitHub Actionsを使用して、自動的にデプロイが行われます。メインブランチにプッシュすると、最新の変更が Google Cloud Run にデプロイされます。

## 注意事項
- サービスアカウントには、Google Cloud Run および Cloud Build へのアクセス権が必要です。
- 環境変数やキーの管理に注意し、セキュリティを確保してください。

## 貢献
このプロジェクトへの貢献を歓迎します。問題や提案があれば、お気軽にお知らせください。
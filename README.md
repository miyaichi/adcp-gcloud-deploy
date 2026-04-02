# adcp-gcloud-deploy

Google Cloud Run へ Ad Context Protocol (AdCP) サーバーをデプロイするための自動化リポジトリ

[![Deploy to Cloud Run](https://github.com/miyaichi/adcp-gcloud-deploy/actions/workflows/deploy.yml/badge.svg)](https://github.com/miyaichi/adcp-gcloud-deploy/actions/workflows/deploy.yml)

## 概要

このプロジェクトは、[Ad Context Protocol (AdCP)](https://github.com/adcontextprotocol/adcp) のサーバーを Google Cloud Run にデプロイするためのリポジトリです。自動化された CI/CD パイプラインを構築し、PostgreSQL データベースのバックアップ機能を提供します。

### AdCP とは

AdCP は AI エージェントが広告プラットフォーム間でインベントリ発見、メディア購入、クリエイティブ構築、オーディエンス管理を行うためのオープン標準です。MCP (Model Context Protocol) と A2A (Agent-to-Agent) プロトコル上で動作します。

**主要機能**:
- **Media Buy**: インベントリ発見、キャンペーン作成、配信レポート
- **Creative**: チャネル横断の広告クリエイティブ管理
- **Signals**: オーディエンス・ターゲティングデータ活性化
- **Accounts**: 商用アイデンティティ・請求管理
- **Governance**: ブランド適合性・コンテンツ基準
- **Brand**: ブランドアイデンティティ発見・解決
- **Sponsored Intelligence**: 会話型ブランド体験

## アーキテクチャ

```
GitHub Repository (main branch)
    ↓ (push trigger)
GitHub Actions
    ↓
Google Cloud Build
    ↓
Container Registry (Docker Image)
    ↓
Cloud Run (AdCP Server)
    ↓
Cloud SQL (PostgreSQL)
```

## 必要条件

### ローカル開発
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [Node.js 20+](https://nodejs.org/) (オプション)

### Google Cloud
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- Google Cloud プロジェクト
- 有効な請求先アカウント

### GitHub
- GitHub アカウント
- リポジトリへの Write 権限

## セットアップ

### 1. リポジトリのクローン

```bash
git clone https://github.com/miyaichi/adcp-gcloud-deploy.git
cd adcp-gcloud-deploy
```

### 2. 環境変数の設定

`.env.example` をコピーして `.env` を作成し、実際の値を設定します：

```bash
cp .env.example .env
```

`.env` ファイルを編集：

```bash
# Google Cloud Project Configuration
GCP_PROJECT_ID=your-actual-project-id
GCP_REGION=asia-northeast1

# Cloud SQL Configuration
CLOUD_SQL_INSTANCE_NAME=adcp-postgres
CLOUD_SQL_DATABASE_NAME=adcp
CLOUD_SQL_USER=adcp_user
CLOUD_SQL_PASSWORD=your-secure-password-here
```

### 3. Google Cloud の初期設定

セットアップスクリプトを実行して、必要な GCP リソースを自動作成します：

```bash
bash scripts/setup.sh
```

このスクリプトは以下を実行します：
- ✅ 必要な Google Cloud API の有効化
- ✅ Cloud SQL インスタンスの作成
- ✅ データベースとユーザーの作成
- ✅ サービスアカウントの認証

### 4. GitHub Secrets の設定

GitHub リポジトリの Settings → Secrets and variables → Actions で以下のシークレットを追加：

| シークレット名 | 説明 |
|--------------|------|
| `GCP_PROJECT_ID` | Google Cloud プロジェクト ID |
| `GCP_SA_KEY` | サービスアカウントキー（JSON形式） |

**サービスアカウントキーの作成方法**:

```bash
# サービスアカウント作成
gcloud iam service-accounts create adcp-deployer \
    --display-name="AdCP Deployer"

# 必要な権限を付与
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:adcp-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/run.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:adcp-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
    --member="serviceAccount:adcp-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.admin"

# キーを作成してダウンロード
gcloud iam service-accounts keys create key.json \
    --iam-account=adcp-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com

# key.json の内容を GCP_SA_KEY シークレットに設定
```

## ローカル開発

Docker Compose を使用してローカル環境で AdCP サーバーを起動：

```bash
docker-compose up
```

サーバーは `http://localhost:3000` でアクセス可能になります。

**ヘルスチェック**:
```bash
curl http://localhost:3000/health
```

## デプロイ

### 自動デプロイ（推奨）

`main` ブランチへのプッシュで自動的に Cloud Run にデプロイされます：

```bash
git add .
git commit -m "Deploy AdCP server"
git push origin main
```

GitHub Actions が自動的に：
1. Docker イメージをビルド
2. Container Registry へプッシュ
3. Cloud Run へデプロイ

デプロイ状況は [Actions タブ](https://github.com/miyaichi/adcp-gcloud-deploy/actions) で確認できます。

### 手動デプロイ

```bash
# Cloud Build でビルド・デプロイ
gcloud builds submit --config cloudbuild.yaml
```

## データベースバックアップ

定期的なバックアップを実行：

```bash
bash scripts/backup-db.sh
```

バックアップは以下に保存されます：
- ローカル: `./backups/adcp_backup_YYYYMMDD_HHMMSS.sql`
- Cloud Storage: `gs://YOUR_PROJECT_ID-adcp-backups/`

**自動バックアップ**: Cloud SQL は毎日 03:00 (JST) に自動バックアップを実行します。

## モニタリング

### Cloud Run メトリクス

[Cloud Console](https://console.cloud.google.com/run) でメトリクスを確認：
- リクエスト数
- レイテンシ
- エラー率
- インスタンス数

### ログ

```bash
# 最新のログを表示
gcloud run services logs read adcp-server --region=asia-northeast1 --limit=50

# リアルタイムログ
gcloud run services logs tail adcp-server --region=asia-northeast1
```

## トラブルシューティング

### デプロイが失敗する

1. GitHub Actions のログを確認
2. Cloud Build のログを確認：
   ```bash
   gcloud builds list --limit=5
   gcloud builds log BUILD_ID
   ```

### データベース接続エラー

1. Cloud SQL インスタンスが起動しているか確認：
   ```bash
   gcloud sql instances describe adcp-postgres
   ```

2. Cloud Run が Cloud SQL に接続できるか確認：
   ```bash
   gcloud run services describe adcp-server --region=asia-northeast1
   ```

### ローカル環境で動かない

1. Docker が起動しているか確認
2. コンテナログを確認：
   ```bash
   docker-compose logs adcp-server
   ```

## リソースのクリーンアップ

プロジェクトを削除する場合：

```bash
# Cloud Run サービスを削除
gcloud run services delete adcp-server --region=asia-northeast1

# Cloud SQL インスタンスを削除
gcloud sql instances delete adcp-postgres

# Container Registry のイメージを削除
gcloud container images list
gcloud container images delete gcr.io/YOUR_PROJECT_ID/adcp-server:latest
```

## コスト見積もり

**月額概算**（asia-northeast1 リージョン）:
- Cloud Run: ¥0～¥5,000（使用量による）
- Cloud SQL (db-f1-micro): ¥2,000～¥3,000
- Container Registry: ¥0～¥500

**注意**: 実際のコストは使用量により変動します。[料金計算ツール](https://cloud.google.com/products/calculator)で詳細を確認してください。

## プロジェクト構成

```
adcp-gcloud-deploy/
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions CI/CD
├── scripts/
│   ├── setup.sh                # 初回セットアップ
│   └── backup-db.sh            # データベースバックアップ
├── .env.example                # 環境変数テンプレート
├── .gitignore                  # Git除外設定
├── Dockerfile                  # AdCP Server コンテナ定義
├── docker-compose.yml          # ローカル開発環境
├── cloudbuild.yaml             # Cloud Build 設定
├── LICENSE                     # ライセンス
└── README.md                   # このファイル
```

## 技術スタック

- **Runtime**: Node.js 20 (Alpine)
- **Web Framework**: Express
- **Database**: PostgreSQL 15
- **Container**: Docker
- **Hosting**: Google Cloud Run
- **CI/CD**: GitHub Actions + Cloud Build
- **Monitoring**: Cloud Logging + Cloud Monitoring

## セキュリティ

- ✅ 非ルートユーザーでコンテナ実行
- ✅ 機密情報は Secret Manager で管理
- ✅ HTTPS 強制（Cloud Run デフォルト）
- ✅ Cloud SQL は VPC 経由で接続
- ✅ 定期的な自動バックアップ

## 貢献

このプロジェクトへの貢献を歓迎します。Issue や Pull Request をお気軽にお送りください。

## 関連リンク

- [AdCP 公式ドキュメント](https://docs.adcontextprotocol.org)
- [AdCP GitHub リポジトリ](https://github.com/adcontextprotocol/adcp)
- [Google Cloud Run ドキュメント](https://cloud.google.com/run/docs)
- [Cloud SQL ドキュメント](https://cloud.google.com/sql/docs)

## ライセンス

このプロジェクトは Apache 2.0 ライセンスの下で公開されています。詳細は [LICENSE](LICENSE) ファイルを参照してください。

---

**作成者**: Yoshihiko Miyaichi  
**最終更新**: 2026-04-02

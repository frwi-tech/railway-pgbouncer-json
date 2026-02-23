# railway-pgbouncer-json

Railway 向け PGBouncer Docker イメージ。JSON 構造化ログを stdout に出力します。

## 問題

Railway はコンテナの `stderr` 出力を全て「error」レベルとして扱います。PGBouncer はデフォルトで全ログを `stderr` に出力するため、通常の `LOG` レベルのメッセージも Railway 上では赤いエラーログとして表示されてしまいます。

## 解決策

PGBouncer の stderr 出力を awk ベースのログパーサーでパースし、JSON 形式で stdout に出力します。Railway はこの JSON の `level` フィールドを読み取り、正しいログレベルで表示します。

### ログレベルマッピング

| PGBouncer | JSON `level` | Railway 表示 |
|-----------|-------------|-------------|
| `LOG`     | `info`      | 通常        |
| `DEBUG`   | `debug`     | 通常        |
| `WARNING` | `warn`      | 警告        |
| `ERROR`   | `error`     | エラー      |
| `FATAL`   | `fatal`     | エラー      |
| `PANIC`   | `fatal`     | エラー      |

### 出力例

PGBouncer の元のログ:
```
2026-02-23 10:23:48.621 UTC [1] LOG C-0x55bcf8a48570: railway/postgres@100.64.0.8:44240 login attempt: db=railway user=postgres tls=no replication=no
```

変換後の JSON:
```json
{"level":"info","timestamp":"2026-02-23T10:23:48.621Z","pid":"1","message":"C-0x55bcf8a48570: railway/postgres@100.64.0.8:44240 login attempt: db=railway user=postgres tls=no replication=no"}
```

## Railway でのデプロイ

1. このリポジトリを Railway のサービスとしてデプロイ
2. 環境変数を設定（`railwayapp/pgbouncer` と同じ環境変数がそのまま使えます）

### 必須環境変数

| 変数名 | 説明 |
|--------|------|
| `DATABASE_URL` | PostgreSQL 接続 URL |

### オプション環境変数

`railwayapp/pgbouncer`（`edoburu/docker-pgbouncer`）と同じ環境変数に対応しています:

| 変数名 | デフォルト | 説明 |
|--------|-----------|------|
| `POOL_MODE` | `session` | プーリングモード (`session`, `transaction`, `statement`) |
| `MAX_CLIENT_CONN` | `100` | 最大クライアント接続数 |
| `DEFAULT_POOL_SIZE` | `20` | デフォルトプールサイズ |
| `MIN_POOL_SIZE` | `0` | 最小プールサイズ |
| `RESERVE_POOL_SIZE` | `0` | リザーブプールサイズ |
| `LISTEN_PORT` | `5432` | リッスンポート |
| `AUTH_TYPE` | `md5` | 認証タイプ |
| `ADMIN_USERS` | `postgres` | 管理ユーザー |
| `LOG_CONNECTIONS` | - | 接続ログ |
| `LOG_DISCONNECTIONS` | - | 切断ログ |
| `LOG_STATS` | - | 統計ログ |

その他の環境変数は [edoburu/docker-pgbouncer](https://github.com/edoburu/docker-pgbouncer) を参照してください。

## ビルド

```bash
docker build -t railway-pgbouncer-json .
```

## ベース

- PGBouncer 1.25.1
- Alpine 3.22
- 元の構成: [edoburu/docker-pgbouncer](https://github.com/edoburu/docker-pgbouncer)

## ライセンス

MIT

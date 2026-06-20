# mackerel-micro-daemon

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: FreeBSD](https://img.shields.io/badge/Platform-FreeBSD-red.svg)](https://www.freebsd.org/)

**mackerel-micro-daemon** は、[Mackerel](https://ja.mackerel.io/) への監視メトリクス送信を行う、FreeBSD 専用の超軽量非公式エージェントです。

外部 CPAN モジュール・curl・jq は不要。`perl5` と FreeBSD に標準搭載の `openssl` のみで動作します。

---

## ⚠️ 注意事項 / Disclaimer

> This project was developed with AI assistance (Google Gemini, Claude Sonnet).
>
> **Use at your own risk.**
> このソフトウェアは現状のまま（AS IS）提供されます。動作・安全性・データの正確性について、作者はいかなる保証も行いません。

- **非公式ツールです。** このプロジェクトは [Mackerel](https://ja.mackerel.io/)（株式会社はてな様）の公式ツールではありません。株式会社はてな様および Mackerel 開発チーム様とは一切関係がありません。
- **Mackerel API の仕様変更により予告なく動作しなくなる可能性があります。** 本ツールは公開 API を独自に呼び出しており、Mackerel サーバ側の仕様変更・エンドポイント廃止・認証方式の変更等があった場合、使用できなくなることがあります。
- **HTTP 通信は `openssl s_client` による手組み実装です。** TLS 証明書の厳格な検証・タイムアウト制御・リトライ処理は最小限であり、本番環境での利用は自己責任の上でご判断ください。
- **API キーの管理は利用者の責任です。** 設定ファイル (`mackerel-micro.conf`) には Mackerel API キーが平文で記載されます。ファイルのパーミッション (`chmod 0600`) や公開リポジトリへのコミット防止 (`.gitignore`) は利用者自身が適切に管理してください。
- **本プロジェクトはサポートを提供しません。** Issue や Pull Request は歓迎しますが、対応を保証するものではありません。

---

## 特徴

- **最低限の依存** — `perl5` と FreeBSD 標準の `openssl` のみ。外部 CPAN モジュール・curl・jq は不要
- **軽量** — 単一の `.pl` ファイル、メモリフットプリント最小
- **自動登録** — ホスト ID ファイルがなければ Mackerel API に自動で新規登録
- **乗り換え対応** — 既存の `mackerel-agent` の ID ファイル (`/var/db/mackerel-agent/id`) をそのまま引き継ぎ可能
- **FreeBSD ネイティブ** — `sysrc` / `service` / `rc.d` に完全対応

## 収集するメトリクス

| カテゴリ | メトリクス |
|---|---|
| CPU | user / nice / system / idle (%) |
| メモリ | total / used / free / active / inactive |
| ロードアベレージ | loadavg1 / loadavg5 / loadavg15 |
| ネットワーク | rxBytes.delta / txBytes.delta (インターフェースごと) |
| ファイルシステム | size / used (マウントポイントごと) |
| ディスク I/O | reads.delta / writes.delta (デバイスごと) |

---

## 動作要件

- FreeBSD 14.x 系以上を推奨
  - 9.x / 10.x（EoL）での動作確認済み。ただし各スクリプトの修正および openssl の追加インストール等が必須
  - 11.x ～ 13.x は動作未検証ですが、理論的には動くと思われます。
- Perl 5.16 以降（`pkg install perl5` で導入）
- OpenSSL（FreeBSD 標準搭載、`openssl s_client` を使用）

---

## インストール

```sh
git clone https://github.com/neun/mackerel-micro-daemon.git
cd mackerel-micro-daemon
sudo sh install.sh
```

インストーラが以下を自動で行います:

1. `/usr/local/sbin/mackerel-micro-daemon` にスクリプトを配置
2. `/usr/local/etc/rc.d/mackerel_micro` に rc.d スクリプトを配置
3. `/usr/local/etc/mackerel-micro/mackerel-micro.conf` に設定ファイルを生成
4. `sysrc mackerel_micro_enable=YES` を実行

---

## 設定

```sh
vi /usr/local/etc/mackerel-micro/mackerel-micro.conf
```

```sh
# 必須: Mackerel の API キー
MACKEREL_API_KEY=your_api_key_here

# 任意: ホスト ID ファイルのパス (デフォルト: /var/db/mackerel-agent/id)
#MACKEREL_ID_FILE=/var/db/mackerel-agent/id
```

API キーは [Mackerel の組織設定ページ](https://mackerel.io/orgs/<YOUR-ORG-NAME>?tab=apikeys) から取得できます。

### 設定値の優先順位

```
環境変数 > 設定ファイル
```

`systemd` 互換の `EnvironmentFile=` や `export MACKEREL_API_KEY=...` でも渡せます。

---

## 起動・停止

```sh
# 起動
sudo service mackerel_micro start

# 停止
sudo service mackerel_micro stop

# 状態確認
sudo service mackerel_micro status

# ログ確認 (syslog 経由で /var/log/messages に出力)
grep mackerel-micro /var/log/messages
```

### 自動起動の有効化 / 無効化

```sh
# 有効化 (install.sh 実行済みなら不要)
sudo sysrc mackerel_micro_enable=YES

# 無効化
sudo sysrc mackerel_micro_enable=NO
```

---

## 既存の mackerel-agent からの乗り換え

既存の `mackerel-agent` が生成した `/var/db/mackerel-agent/id` をそのまま使用するため、**Mackerel 上のホストが重複せず引き継ぎ**できます。

```sh
# 既存エージェントを停止
sudo service mackerel-agent stop
sudo sysrc mackerel_agent_enable=NO

# mackerel-micro-daemon を起動
sudo service mackerel_micro start
```

---

## アンインストール

```sh
sudo sh uninstall.sh
```

設定ファイル・ホスト ID・ログは自動削除されません。手動で削除してください。

---

## ファイル構成

```
/usr/local/sbin/mackerel-micro-daemon        # メインスクリプト
/usr/local/etc/rc.d/mackerel_micro           # rc.d サービス定義
/usr/local/etc/mackerel-micro/
  mackerel-micro.conf                        # 設定ファイル (要作成)
  mackerel-micro.conf.sample                 # 設定サンプル
/var/db/mackerel-agent/id                    # ホスト ID (自動生成)
/var/log/messages                            # ログ (syslogd 管理、tag: mackerel-micro)
/var/run/mackerel_micro.pid                  # PID ファイル
```

---

## ライセンス

[MIT License](LICENSE)

Copyright (c) 2026 neun

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
- **乗り換え対応** — 既存の `mackerel-agent` の ID ファイル (`/var/lib/mackerel-agent/id`) をそのまま引き継ぎ可能
- **FreeBSD ネイティブ** — `sysrc` / `service` / `rc.d` に完全対応

## 収集するメトリクス

| カテゴリ | メトリクス |
|---|---|
| CPU | user / nice / system / idle (%) |
| メモリ | total / used / free / active / inactive / swap_total / swap_free |
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
% git clone https://github.com/neun/mackerel-micro-daemon.git
% cd mackerel-micro-daemon
% su -m
# sh install.sh
```

インストーラが以下を自動で行います:

1. `/usr/local/sbin/mackerel-micro-daemon` にスクリプトを配置
2. `/usr/local/etc/rc.d/mackerel_micro` に rc.d スクリプトを配置
3. `/usr/local/etc/mackerel-micro/mackerel-micro.conf` に設定ファイルを生成
4. `sysrc mackerel_micro_enable=YES` を実行

---

## 設定

```sh
% su -
# vi /usr/local/etc/mackerel-micro/mackerel-micro.conf
```
### 設定ファイルの中身について
```sh
# 必須: Mackerel の API キー
MACKEREL_API_KEY=your_api_key_here

# 任意: ホスト ID ファイルのパス (デフォルト: /var/lib/mackerel-agent/id)
#MACKEREL_ID_FILE=/var/lib/mackerel-agent/id
```
API キーは [Mackerel の組織設定ページ](https://mackerel.io/orgs/<YOUR-ORG-NAME>?tab=apikeys) から取得できます。


```sh
# =============================================================================
# [任意] 収集除外フィルター
# デフォルトはすべて除外なし。必要な項目だけコメントを外して設定してください。
# 複数指定はカンマ区切り。前後のスペースは自動的に除去されます。
# =============================================================================

# ネットワークインターフェースの除外
# 指定したインターフェースの rx/tx メトリクスを収集しません。
# 例: ループバック・仮想インターフェース・未使用NIC など
#IGNORE_INTERFACES=lo0, gif0, plip0

# ディスクデバイスの除外 (I/O メトリクス対象)
# iostat が返すデバイス名で指定します。
# 例: CD-ROM・メモリディスク・未使用デバイス など
#IGNORE_DISKS=cd0, md0

# マウントポイントの除外 (ファイルシステム使用量メトリクス対象)
# df が返すマウントポイントのパスで指定します。
#IGNORE_FILESYSTEMS=/tmp, /var/run

# ファイルシステム種別の除外
# mount コマンドが返す fstype 名で指定します。
# 注意: devfs / procfs / tmpfs 等はコード側でデフォルト除外済みです。
# 例: ZFS データセットや FAT/exFAT メディアを除外したい場合など
#IGNORE_FS_TYPES=msdosfs, cd9660, nullfs
```
Mackerelに送信したくない各項目を設定できます。


### 設定値の優先順位

```
環境変数 > 設定ファイル
```

設定ファイルの代わりに環境変数で渡すことも可能です
(sh系: `export MACKEREL_API_KEY=...` / csh・tcsh系: `setenv MACKEREL_API_KEY ...`)
これは同じシェルセッションから手動で `service mackerel_micro start` した場合のみ有効です。
起動時 (rc.d 経由の自動起動) には適用されないため、通常は設定ファイルへの記載を推奨します。

---

## 起動・停止

### 起動

```sh
# service mackerel_micro start
```

### 停止

```sh
# service mackerel_micro stop
```

### 状態確認
```sh
# service mackerel_micro status
```

### ログ確認 (syslog 経由で /var/log/messages に出力)
```sh
# grep mackerel-micro /var/log/messages
```

### 自動起動の有効化 / 無効化

#### 有効化 (install.sh 実行済みなら不要)

```sh
# sysrc mackerel_micro_enable=YES
```

#### 無効化
```sh
# sysrc mackerel_micro_enable=NO
```

---

## 既存の mackerel-agent からの乗り換え

既存の `mackerel-agent` が生成した `/var/lib/mackerel-agent/id` をそのまま使用するため、**Mackerel 上のホストが重複せず引き継ぎ**できます。

### 既存エージェントを停止
```sh
# service mackerel-agent stop
# sysrc mackerel_agent_enable=NO
```

### mackerel-micro-daemon を起動
```sh
# service mackerel_micro start
```

---

## アンインストール

```sh
# sh uninstall.sh
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
/var/lib/mackerel-agent/id                    # ホスト ID (自動生成)
/var/log/messages                            # ログ (syslogd 管理、tag: mackerel-micro)
/var/run/mackerel_micro.pid                  # PID ファイル
```

---

## ライセンス

[MIT License](LICENSE)

Copyright (c) 2026 neun

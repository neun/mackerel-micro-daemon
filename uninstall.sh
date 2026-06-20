#!/bin/sh
# =============================================================================
# uninstall.sh - mackerel-micro-daemon アンインストーラ (FreeBSD)
# =============================================================================
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { printf "${GREEN}[INFO]${RESET}  %s\n" "$*"; }
warn()    { printf "${YELLOW}[WARN]${RESET}  %s\n" "$*"; }
section() { printf "\n${BOLD}==> %s${RESET}\n" "$*"; }

if [ "$(id -u)" -ne 0 ]; then
    printf "${RED}[ERROR]${RESET} root で実行してください。\n" >&2; exit 1
fi

section "サービスの停止"
if service mackerel_micro status >/dev/null 2>&1; then
    info "mackerel_micro を停止中..."
    service mackerel_micro stop || true
fi

section "起動設定の削除 (sysrc)"
sysrc -x mackerel_micro_enable 2>/dev/null && info "mackerel_micro_enable を rc.conf から削除しました。" || true

section "ファイルの削除"
for f in \
    /usr/local/sbin/mackerel-micro-daemon \
    /usr/local/etc/rc.d/mackerel_micro \
    /var/run/mackerel_micro.pid
do
    if [ -f "$f" ]; then
        rm -f "$f" && info "削除: $f"
    fi
done

warn "以下のファイルは手動で削除してください (データ保護のため自動削除しません):"
warn "  設定ファイル : /usr/local/etc/mackerel-micro/mackerel-micro.conf"
warn "  ホスト ID    : /var/lib/mackerel-agent/id  (他のagentと共用の場合は特に注意)"
warn "  ログ         : /var/log/messages 内 (syslog経由、grep mackerel-micro で検索可能)"

printf "\n${GREEN}${BOLD}アンインストール完了。${RESET}\n"

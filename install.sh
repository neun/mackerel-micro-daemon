#!/bin/sh
# =============================================================================
# install.sh - mackerel-micro-daemon インストーラ (FreeBSD)
# =============================================================================
set -e

# --- カラー出力 ---
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; RESET='\033[0m'
info()    { printf "${GREEN}[INFO]${RESET}  %s\n" "$*"; }
warn()    { printf "${YELLOW}[WARN]${RESET}  %s\n" "$*"; }
error()   { printf "${RED}[ERROR]${RESET} %s\n" "$*" >&2; exit 1; }
section() { printf "\n${BOLD}==> %s${RESET}\n" "$*"; }

# --- root チェック ---
if [ "$(id -u)" -ne 0 ]; then
    error "このスクリプトは root で実行してください。: sudo sh install.sh"
fi

# --- OS チェック ---
if [ "$(uname -s)" != "FreeBSD" ]; then
    error "このスクリプトは FreeBSD 専用です。"
fi

# --- Perl チェック ---
if ! command -v perl >/dev/null 2>&1; then
    error "perl が見つかりません。インストールしてください: pkg install perl5"
fi

# --- openssl チェック ---
if ! command -v openssl >/dev/null 2>&1; then
    error "openssl が見つかりません。インストールしてください: pkg install openssl"
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SBIN_DIR="/usr/local/sbin"
RC_DIR="/usr/local/etc/rc.d"
CONF_DIR="/usr/local/etc/mackerel-micro"
CONF_SAMPLE="${CONF_DIR}/mackerel-micro.conf.sample"
CONF_FILE="${CONF_DIR}/mackerel-micro.conf"

# =============================================================================
section "ファイルのインストール"
# =============================================================================

info "デーモンスクリプトを ${SBIN_DIR}/mackerel-micro-daemon にインストール"
install -m 0755 "${SCRIPT_DIR}/files/usr/local/sbin/mackerel-micro-daemon" \
    "${SBIN_DIR}/mackerel-micro-daemon"

info "rc.d スクリプトを ${RC_DIR}/mackerel_micro にインストール"
install -m 0755 "${SCRIPT_DIR}/files/usr/local/etc/rc.d/mackerel_micro" \
    "${RC_DIR}/mackerel_micro"

info "設定ディレクトリを作成: ${CONF_DIR}"
install -d -m 0755 "${CONF_DIR}"

info "設定サンプルを ${CONF_SAMPLE} にインストール"
install -m 0644 "${SCRIPT_DIR}/files/usr/local/etc/mackerel-micro/mackerel-micro.conf.sample" \
    "${CONF_SAMPLE}"

# =============================================================================
section "設定ファイルのセットアップ"
# =============================================================================

if [ -f "${CONF_FILE}" ]; then
    warn "設定ファイルが既に存在します: ${CONF_FILE}"
    warn "上書きをスキップします。手動で確認してください。"
else
    info "設定ファイルをサンプルからコピー: ${CONF_FILE}"
    cp "${CONF_SAMPLE}" "${CONF_FILE}"
    chmod 0600 "${CONF_FILE}"

    printf "\n${YELLOW}%s${RESET}\n" "------------------------------------------------------------"
    printf "${BOLD}次のステップ: API キーを設定ファイルに記入してください。${RESET}\n"
    printf "  vi %s\n" "${CONF_FILE}"
    printf "  → MACKEREL_API_KEY=<あなたのAPIキー> を設定\n"
    printf "${YELLOW}%s${RESET}\n\n" "------------------------------------------------------------"
fi

# =============================================================================
section "起動設定 (sysrc)"
# =============================================================================

info "sysrc で mackerel_micro_enable=YES を設定中..."
sysrc mackerel_micro_enable=YES

# =============================================================================
section "インストール完了"
# =============================================================================

printf "\n${GREEN}${BOLD}インストールが完了しました！${RESET}\n\n"
printf "次のステップ:\n"
printf "  1. API キーを設定ファイルに記入:\n"
printf "       vi %s\n" "${CONF_FILE}"
printf "  2. サービスを起動:\n"
printf "       service mackerel_micro start\n"
printf "  3. 状態の確認:\n"
printf "       service mackerel_micro status\n"
printf "  4. ログの確認 (syslog 経由で /var/log/messages に出力されます):\n"
printf "       grep mackerel-micro /var/log/messages\n\n"

#!/bin/bash
# 设置 SSL 证书自动续期（Cloudflare 环境）
# 用法: bash setup-renewal.sh [Cloudflare DNS API Token]
set -e

CF_TOKEN="${1:-}"
PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)

echo "=== 设置证书自动续期 ==="
echo ""

# 检查 certbot 是否安装
if ! command -v certbot &> /dev/null; then
    echo "[!] 未找到 certbot，请先安装"
    exit 1
fi

# 检查现有 cron 任务
if crontab -l 2>/dev/null | grep -q "certbot renew"; then
    echo "[*] 证书续期任务已存在"
    crontab -l | grep "certbot renew"
    echo ""
    echo "如需重新设置，请先删除旧任务: crontab -e"
    exit 0
fi

# 根据是否提供 CF Token 选择不同的续期方式
if [ -n "$CF_TOKEN" ]; then
    # DNS-01 续期
    CF_CRED_FILE="$PROJECT_DIR/nginx/.cf-credentials"
    cat > "$CF_CRED_FILE" <<EOF
dns_cloudflare_api_token = $CF_TOKEN
EOF
    chmod 600 "$CF_CRED_FILE"

    RENEW_CMD="certbot renew --dns-cloudflare --dns-cloudflare-credentials $CF_CRED_FILE --quiet"
    echo "[*] 使用 DNS-01 模式自动续期"
else
    # HTTP-01 续期（需要确保 80 端口可用）
    RENEW_CMD="certbot renew --webroot --webroot-path $PROJECT_DIR/nginx/certbot-webroot --quiet"
    echo "[*] 使用 HTTP-01 模式自动续期"
fi

# 添加 cron 任务：每周日凌晨 2:30 续期并重载 nginx
(crontab -l 2>/dev/null; echo "30 2 * * 0 $RENEW_CMD && docker compose -f $PROJECT_DIR/docker-compose.production.yml exec nginx nginx -s reload") | crontab -

echo "[✓] 已添加证书自动续期任务"
echo ""
echo "续期计划: 每周日 02:30 检查，证书过期前 30 天自动续期"
echo ""
echo "当前 cron 任务:"
crontab -l | grep certbot

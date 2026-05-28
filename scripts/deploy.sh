#!/bin/bash
# FlecBlog 生产环境部署脚本（Cloudflare CDN 环境）
# 用法: bash deploy.sh <your_email@example.com> [Cloudflare DNS API Token]
set -e

DOMAIN="winterwait.com"
ADMIN_DOMAIN="admin.winterwait.com"
API_DOMAIN="api.winterwait.com"
EMAIL="${1:-}"
CF_TOKEN="${2:-}"

if [ -z "$EMAIL" ]; then
    echo "用法: bash deploy.sh <your_email@example.com> [CF_DNS_TOKEN]"
    echo ""
    echo "  your_email@example.com  - Let's Encrypt 通知邮箱"
    echo "  CF_DNS_TOKEN            - Cloudflare DNS API Token（可选）"
    echo "                           提供后使用 DNS-01 验证，无需暴露 80 端口"
    exit 1
fi

# 检查 .env 文件
if [ ! -f .env ]; then
    echo "[!] 未找到 .env 文件"
    echo "请复制 .env.production 为 .env 并填写配置:"
    echo ""
    echo "  cp .env.production .env"
    echo "  vim .env"
    exit 1
fi

echo "=== FlecBlog 生产部署 (Cloudflare CDN) ==="
echo "域名: $DOMAIN"
echo "邮箱: $EMAIL"
echo ""

# Step 1: 安装依赖
echo "--- Step 1: 安装依赖 ---"

# 安装 certbot
if ! command -v certbot &> /dev/null; then
    echo "[*] 正在安装 Certbot..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y certbot
    elif command -v yum &> /dev/null; then
        sudo yum install -y epel-release && sudo yum install -y certbot
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y certbot
    else
        echo "[!] 无法自动安装 certbot，请手动安装后重试"
        exit 1
    fi
fi

# 安装 Cloudflare DNS 插件（如果提供了 API Token）
if [ -n "$CF_TOKEN" ]; then
    echo "[*] 安装 Cloudflare DNS 插件..."
    pip3 install certbot-dns-cloudflare
fi

# Step 2: 申请 SSL 证书
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
if [ -f "$CERT_PATH" ]; then
    echo "[*] 证书已存在，跳过申请"
else
    echo "--- Step 2: 申请 SSL 证书 ---"

    DOMAINS="-d $DOMAIN -d www.$DOMAIN -d $ADMIN_DOMAIN -d $API_DOMAIN"

    if [ -n "$CF_TOKEN" ]; then
        # DNS-01 验证（推荐，不需要 80 端口空闲）
        echo "[*] 使用 Cloudflare DNS-01 验证..."
        CF_CRED_FILE=$(mktemp)
        cat > "$CF_CRED_FILE" <<EOF
dns_cloudflare_api_token = $CF_TOKEN
EOF
        chmod 600 "$CF_CRED_FILE"

        sudo certbot certonly --dns-cloudflare \
            --dns-cloudflare-credentials "$CF_CRED_FILE" \
            --email "$EMAIL" \
            --agree-tos \
            --no-eff-email \
            $DOMAINS

        rm -f "$CF_CRED_FILE"
    else
        # HTTP-01 验证（需要 Cloudflare SSL 设为 Flexible/Full，非 Strict）
        echo "[*] 使用 HTTP-01 验证..."
        echo "    请确保 Cloudflare SSL 模式不是 Full (Strict)"
        echo "    （证书申请完成后可改为 Full (Strict)）"
        sudo certbot certonly --standalone \
            --email "$EMAIL" \
            --agree-tos \
            --no-eff-email \
            $DOMAINS
    fi

    echo "[✓] 证书申请成功"
fi

# Step 3: 启动 Docker 服务
echo ""
echo "--- Step 3: 启动服务 ---"
docker compose -f docker-compose.production.yml up -d

# Step 4: 等待服务就绪
echo "[*] 等待服务启动..."
sleep 5

# Step 5: 检查状态
echo ""
echo "--- 服务状态 ---"
docker compose -f docker-compose.production.yml ps

echo ""
echo "=== 部署完成 ==="
echo "博客:   https://$DOMAIN"
echo "后台:   https://$ADMIN_DOMAIN"
echo "API:    https://$API_DOMAIN/swagger/index.html"
echo ""
echo "--- Cloudflare 建议设置 ---"
echo "  SSL/TLS 模式: Full (Strict)"
echo "  Always Use HTTPS: 开启"
echo "  自动 HTTPS 重写: 开启"
echo ""
echo "--- 证书续期 ---"
echo "运行以下命令设置自动续期:"
echo "  sudo bash scripts/setup-renewal.sh"

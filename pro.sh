#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_VERSION="8.0-Pro"
SCRIPT_NAME="yx-server-tools"
BACKUP_DIR="/backup/${SCRIPT_NAME}"
LOG_DIR="/var/log/${SCRIPT_NAME}"
INSTALL_LOG="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
DIALOG_TITLE="服务器工具安装管理 Pro版 v$SCRIPT_VERSION"
AUTO_RECOVERY=false

KEY_SALT="yx-pro-salt-$(date +%m)"
CORRECT_HASH="e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"

validate_license() {
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}        服务器工具安装管理 Pro版          ${NC}"
    echo -e "${PURPLE}              版本: $SCRIPT_VERSION           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    local input_key=""
    echo -e "${YELLOW}请输入授权密钥: ${NC}"
    read -s input_key
    echo ""
    
    local input_hash=$(echo -n "${KEY_SALT}${input_key}" | sha256sum | awk '{print $1}')
    
    if [ "$input_hash" = "$CORRECT_HASH" ]; then
        echo -e "${GREEN}✅ 密钥验证成功！${NC}"
        echo -e "${BLUE}欢迎使用 Pro 版本！${NC}"
        echo ""
        sleep 2
        return 0
    else
        echo -e "${RED}❌ 密钥验证失败！${NC}"
        exit 1
    fi
}

init_log_system() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    touch "$INSTALL_LOG" 2>/dev/null
    exec > >(tee -a "$INSTALL_LOG") 2>&1
}

log() {
    local msg="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[${timestamp}] ✓ $msg${NC}"
    echo "[${timestamp}] INFO: $msg" >> "$INSTALL_LOG"
}

warn() {
    local msg="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[${timestamp}] ⚠  $msg${NC}"
    echo "[${timestamp}] WARN: $msg" >> "$INSTALL_LOG"
}

error() {
    local msg="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[${timestamp}] ✗ $msg${NC}"
    echo "[${timestamp}] ERROR: $msg" >> "$INSTALL_LOG"
}

info() {
    local msg="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}] ℹ  $msg${NC}"
    echo "[${timestamp}] INFO: $msg" >> "$INSTALL_LOG"
}

success() {
    local msg="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[${timestamp}] ✅ $msg${NC}"
    echo "[${timestamp}] SUCCESS: $msg" >> "$INSTALL_LOG"
}

show_separator() {
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
}

check_status() {
    local return_code=$?
    local success_msg="$1"
    local error_msg="$2"
    
    if [ $return_code -eq 0 ]; then
        if [ -n "$success_msg" ]; then
            log "$success_msg"
        fi
        return 0
    else
        if [ -n "$error_msg" ]; then
            error "$error_msg"
        fi
        return $return_code
    fi
}

check_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then
        echo -e "${YELLOW}正在安装dialog工具...${NC}"
        apt-get update -y >/dev/null 2>&1
        apt-get install -y dialog >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "${RED}错误：无法安装dialog工具${NC}"
            exit 1
        fi
        log "dialog工具安装成功"
    fi
}

show_gui() {
    local title="$1"
    shift
    local old_stty=$(stty -g)
    dialog --backtitle "$DIALOG_TITLE" --title "$title" "$@" 2>&1 >/dev/tty
    local result=$?
    stty $old_stty
    echo $result
}

show_gui_menu() {
    local title="$1"
    local height="$2"
    local width="$3"
    local menu_height="$4"
    shift 4
    
    local old_stty=$(stty -g)
    local output
    output=$(dialog --backtitle "$DIALOG_TITLE" --title "$title" \
                    --menu "" \
                    $height $width $menu_height \
                    "$@" 2>&1 >/dev/tty)
    local result=$?
    stty $old_stty
    
    if [ $result -eq 0 ]; then
        echo "$output"
    else
        echo ""
    fi
    return $result
}

show_gui_msgbox() {
    local title="$1"
    local msg="$2"
    local height="$3"
    local width="$4"
    
    local old_stty=$(stty -g)
    dialog --backtitle "$DIALOG_TITLE" --title "$title" \
           --msgbox "$msg" $height $width 2>&1 >/dev/tty
    local result=$?
    stty $old_stty
    return $result
}

show_gui_yesno() {
    local title="$1"
    local msg="$2"
    local height="$3"
    local width="$4"
    
    local old_stty=$(stty -g)
    dialog --backtitle "$DIALOG_TITLE" --title "$title" \
           --yesno "$msg" $height $width 2>&1 >/dev/tty
    local result=$?
    stty $old_stty
    return $result
}

show_gui_checklist() {
    local title="$1"
    local height="$2"
    local width="$3"
    local menu_height="$4"
    shift 4
    
    local old_stty=$(stty -g)
    local output
    output=$(dialog --backtitle "$DIALOG_TITLE" --title "$title" \
                    --checklist "" \
                    $height $width $menu_height \
                    "$@" 2>&1 >/dev/tty)
    local result=$?
    stty $old_stty
    
    if [ $result -eq 0 ]; then
        echo "$output"
    else
        echo ""
    fi
    return $result
}

exit_to_terminal() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}正在退出GUI界面，进入终端模式${NC}"
    echo -e "${YELLOW}操作完成后会自动返回GUI界面${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
}

return_to_gui() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}操作完成！按回车键返回GUI界面...${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    read -p ""
}

check_network() {
    info "检查网络连接..."
    
    local test_urls=(
        "https://github.com"
        "https://download.docker.com"
        "https://resource.fit2cloud.com"
    )
    
    for url in "${test_urls[@]}"; do
        if ! curl -s --connect-timeout 10 --head "$url" >/dev/null 2>&1; then
            warn "无法访问: $url"
        fi
    done
    log "网络检查完成"
}

check_disk_space() {
    local min_space=${1:-5}
    
    info "检查磁盘空间..."
    
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//' 2>/dev/null || echo "0")
    
    if [ "$free_space" -lt "$min_space" ]; then
        error "磁盘空间不足！当前剩余: ${free_space}GB，需要至少: ${min_space}GB"
        return 1
    fi
    
    log "磁盘空间充足: ${free_space}GB ✓"
    return 0
}

check_service_status() {
    local service_name="$1"
    local display_name="${2:-$service_name}"
    
    if systemctl list-unit-files | grep -q "$service_name.service" 2>/dev/null; then
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            echo -e "  ${GREEN}✓ ${display_name}: 正在运行${NC}"
            return 0
        else
            echo -e "  ${YELLOW}⚠ ${display_name}: 已安装但未运行${NC}"
            return 1
        fi
    else
        echo -e "  ${BLUE}ℹ ${display_name}: 未安装${NC}"
        return 2
    fi
}

start_service() {
    local service_name="$1"
    local display_name="${2:-$service_name}"
    
    info "启动 ${display_name} 服务..."
    if systemctl start "$service_name" 2>/dev/null; then
        sleep 2
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            success "${display_name} 服务启动成功"
            return 0
        else
            error "${display_name} 服务启动失败"
            return 1
        fi
    else
        error "无法启动 ${display_name} 服务"
        return 1
    fi
}

restart_service() {
    local service_name="$1"
    local display_name="${2:-$service_name}"
    
    info "重启 ${display_name} 服务..."
    if systemctl restart "$service_name" 2>/dev/null; then
        sleep 2
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            success "${display_name} 服务重启成功"
            return 0
        else
            error "${display_name} 服务重启失败"
            return 1
        fi
    else
        error "无法重启 ${display_name} 服务"
        return 1
    fi
}

check_docker_installed() {
    if command -v docker &>/dev/null && systemctl is-active --quiet docker 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

check_1panel_installed() {
    if systemctl list-unit-files | grep -q "1panel" 2>/dev/null || command -v 1pctl &>/dev/null || [ -f "/usr/local/bin/1panel" ]; then
        return 0
    else
        return 1
    fi
}

server_tools_menu() {
    while true; do
        choice=$(show_gui_menu "服务器工具安装" 20 70 12 \
                  "1" "安装Docker及容器工具" \
                  "2" "安装Web服务器" \
                  "3" "安装数据库" \
                  "4" "安装编程语言环境" \
                  "5" "安装开发工具" \
                  "6" "安装监控工具" \
                  "7" "安装安全工具" \
                  "8" "安装网络工具" \
                  "9" "安装系统工具" \
                  "10" "安装控制面板" \
                  "11" "一键安装常用工具包" \
                  "12" "返回主菜单")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) docker_tools_menu ;;
            2) web_server_menu ;;
            3) database_menu ;;
            4) programming_lang_menu ;;
            5) dev_tools_menu ;;
            6) monitoring_tools_menu ;;
            7) security_tools_menu ;;
            8) network_tools_menu ;;
            9) system_tools_menu ;;
            10) control_panel_menu ;;
            11) install_common_tools_package ;;
            12) return ;;
        esac
    done
}

docker_tools_menu() {
    while true; do
        choice=$(show_gui_menu "Docker及容器工具" 15 60 7 \
                  "1" "安装Docker CE" \
                  "2" "安装Docker Compose" \
                  "3" "安装Portainer" \
                  "4" "安装Lazydocker" \
                  "5" "安装ctop" \
                  "6" "清理Docker" \
                  "7" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_docker_ce ;;
            2) install_docker_compose ;;
            3) install_portainer ;;
            4) install_lazydocker ;;
            5) install_ctop ;;
            6) cleanup_docker ;;
            7) return ;;
        esac
    done
}

install_docker_ce() {
    if check_docker_installed; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "未知版本")
        if ! show_gui_yesno "Docker状态" "Docker已经安装：\n版本: $docker_version\n\n是否重新安装？" 10 50; then
            return
        fi
    fi
    
    if ! show_gui_yesno "安装Docker CE" "将安装Docker容器引擎\n\n安装后会自动配置镜像加速器\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "开始安装Docker CE..."
    
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
    apt-get update
    apt-get install -y ca-certificates curl gnupg lsb-release
    
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
EOF
    
    systemctl restart docker
    systemctl enable docker
    
    if docker run --rm hello-world &>/dev/null; then
        success "✅ Docker CE安装成功！"
    else
        error "❌ Docker CE安装失败！"
    fi
    
    return_to_gui
}

install_docker_compose() {
    if command -v docker-compose &>/dev/null; then
        local compose_version=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "未知版本")
        if ! show_gui_yesno "Docker Compose状态" "Docker Compose已经安装：\n版本: $compose_version\n\n是否重新安装？" 10 50; then
            return
        fi
    fi
    
    if ! show_gui_yesno "安装Docker Compose" "将安装Docker Compose工具\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Docker Compose..."
    
    local compose_version="v2.24.5"
    curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    if docker-compose --version &>/dev/null; then
        success "✅ Docker Compose安装成功！"
    else
        error "❌ Docker Compose安装失败！"
    fi
    
    return_to_gui
}

install_portainer() {
    if ! check_docker_installed; then
        show_gui_msgbox "错误" "请先安装Docker！" 8 40
        return
    fi
    
    if ! show_gui_yesno "安装Portainer" "将安装Portainer容器管理面板\n\n默认端口: 9000\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Portainer..."
    
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
    
    sleep 3
    
    if docker ps | grep -q portainer; then
        success "✅ Portainer安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}访问地址: http://${ip_address}:9000${NC}"
    else
        error "❌ Portainer安装失败！"
    fi
    
    return_to_gui
}

install_lazydocker() {
    if ! command -v docker &>/dev/null; then
        show_gui_msgbox "错误" "请先安装Docker！" 8 40
        return
    fi
    
    if ! show_gui_yesno "安装Lazydocker" "将安装Lazydocker终端Docker管理工具\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Lazydocker..."
    
    curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep "browser_download_url.*Linux_x86_64.tar.gz" | cut -d : -f 2,3 | tr -d \" | wget -qi -
    tar xzf lazydocker*.tar.gz
    mv lazydocker /usr/local/bin/
    rm -f lazydocker*.tar.gz
    
    if command -v lazydocker &>/dev/null; then
        success "✅ Lazydocker安装成功！"
        echo -e "${GREEN}使用方法: lazydocker${NC}"
    else
        error "❌ Lazydocker安装失败！"
    fi
    
    return_to_gui
}

install_ctop() {
    if ! show_gui_yesno "安装ctop" "将安装ctop容器监控工具\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装ctop..."
    
    wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
    chmod +x /usr/local/bin/ctop
    
    if command -v ctop &>/dev/null; then
        success "✅ ctop安装成功！"
        echo -e "${GREEN}使用方法: ctop${NC}"
    else
        error "❌ ctop安装失败！"
    fi
    
    return_to_gui
}

cleanup_docker() {
    if ! show_gui_yesno "清理Docker" "将清理所有Docker资源\n包括容器、镜像、卷等\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "清理Docker资源..."
    
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker rm $(docker ps -aq) 2>/dev/null || true
    docker rmi $(docker images -q) 2>/dev/null || true
    docker volume rm $(docker volume ls -q) 2>/dev/null || true
    docker system prune -a -f
    
    success "✅ Docker清理完成！"
    
    return_to_gui
}

web_server_menu() {
    while true; do
        choice=$(show_gui_menu "Web服务器安装" 15 60 6 \
                  "1" "安装Nginx" \
                  "2" "安装Apache2" \
                  "3" "安装Caddy" \
                  "4" "安装OpenLiteSpeed" \
                  "5" "安装Traefik" \
                  "6" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_nginx ;;
            2) install_apache2 ;;
            3) install_caddy ;;
            4) install_openlitespeed ;;
            5) install_traefik ;;
            6) return ;;
        esac
    done
}

install_nginx() {
    if ! show_gui_yesno "安装Nginx" "将安装Nginx Web服务器\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Nginx..."
    
    apt-get update
    apt-get install -y nginx
    
    mkdir -p /var/www/html
    echo "<h1>Welcome to Nginx Server</h1>" > /var/www/html/index.html
    
    systemctl restart nginx
    systemctl enable nginx
    
    if systemctl is-active --quiet nginx; then
        success "✅ Nginx安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}访问地址: http://${ip_address}${NC}"
    else
        error "❌ Nginx安装失败！"
    fi
    
    return_to_gui
}

install_apache2() {
    if ! show_gui_yesno "安装Apache2" "将安装Apache2 Web服务器\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Apache2..."
    
    apt-get update
    apt-get install -y apache2
    
    mkdir -p /var/www/html
    echo "<h1>Welcome to Apache2 Server</h1>" > /var/www/html/index.html
    
    systemctl restart apache2
    systemctl enable apache2
    
    if systemctl is-active --quiet apache2; then
        success "✅ Apache2安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}访问地址: http://${ip_address}${NC}"
    else
        error "❌ Apache2安装失败！"
    fi
    
    return_to_gui
}

install_caddy() {
    if ! show_gui_yesno "安装Caddy" "将安装Caddy Web服务器\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Caddy..."
    
    apt-get install -y debian-keyring debian-archive-keyring apt-transport-https curl
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    apt-get update
    apt-get install -y caddy
    
    systemctl restart caddy
    systemctl enable caddy
    
    if systemctl is-active --quiet caddy; then
        success "✅ Caddy安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}访问地址: http://${ip_address}${NC}"
    else
        error "❌ Caddy安装失败！"
    fi
    
    return_to_gui
}

install_openlitespeed() {
    if ! show_gui_yesno "安装OpenLiteSpeed" "将安装OpenLiteSpeed Web服务器\n\n默认端口: 8088\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "安装OpenLiteSpeed..."
    
    wget -O - https://repo.litespeed.sh | bash
    apt-get install -y openlitespeed
    
    systemctl restart lsws
    systemctl enable lsws
    
    if systemctl is-active --quiet lsws; then
        success "✅ OpenLiteSpeed安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}访问地址: http://${ip_address}:8088${NC}"
        echo -e "${GREEN}管理面板: http://${ip_address}:7080${NC}"
    else
        error "❌ OpenLiteSpeed安装失败！"
    fi
    
    return_to_gui
}

install_traefik() {
    if ! check_docker_installed; then
        show_gui_msgbox "错误" "请先安装Docker！" 8 40
        return
    fi
    
    if ! show_gui_yesno "安装Traefik" "将安装Traefik反向代理\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Traefik..."
    
    mkdir -p /etc/traefik
    cat > /etc/traefik/traefik.yml << EOF
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
EOF
    
    docker run -d \
      --name traefik \
      --restart always \
      -p 80:80 \
      -p 443:443 \
      -p 8080:8080 \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /etc/traefik/traefik.yml:/traefik.yml \
      traefik:v2.10
    
    sleep 3
    
    if docker ps | grep -q traefik; then
        success "✅ Traefik安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}管理面板: http://${ip_address}:8080${NC}"
    else
        error "❌ Traefik安装失败！"
    fi
    
    return_to_gui
}

database_menu() {
    while true; do
        choice=$(show_gui_menu "数据库安装" 15 60 7 \
                  "1" "安装MySQL" \
                  "2" "安装MariaDB" \
                  "3" "安装PostgreSQL" \
                  "4" "安装Redis" \
                  "5" "安装MongoDB" \
                  "6" "安装SQLite" \
                  "7" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_mysql ;;
            2) install_mariadb ;;
            3) install_postgresql ;;
            4) install_redis ;;
            5) install_mongodb ;;
            6) install_sqlite ;;
            7) return ;;
        esac
    done
}

install_mysql() {
    if ! show_gui_yesno "安装MySQL" "将安装MySQL数据库\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装MySQL..."
    
    apt-get update
    apt-get install -y mysql-server
    
    systemctl restart mysql
    systemctl enable mysql
    
    if systemctl is-active --quiet mysql; then
        success "✅ MySQL安装成功！"
        
        echo -e "${YELLOW}运行MySQL安全配置...${NC}"
        mysql_secure_installation <<EOF
y
y
y
y
y
EOF
        
        log "MySQL安全配置完成"
    else
        error "❌ MySQL安装失败！"
    fi
    
    return_to_gui
}

install_mariadb() {
    if ! show_gui_yesno "安装MariaDB" "将安装MariaDB数据库\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装MariaDB..."
    
    apt-get update
    apt-get install -y mariadb-server
    
    systemctl restart mariadb
    systemctl enable mariadb
    
    if systemctl is-active --quiet mariadb; then
        success "✅ MariaDB安装成功！"
        
        echo -e "${YELLOW}运行MariaDB安全配置...${NC}"
        mysql_secure_installation <<EOF
y
y
y
y
y
EOF
        
        log "MariaDB安全配置完成"
    else
        error "❌ MariaDB安装失败！"
    fi
    
    return_to_gui
}

install_postgresql() {
    if ! show_gui_yesno "安装PostgreSQL" "将安装PostgreSQL数据库\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装PostgreSQL..."
    
    apt-get update
    apt-get install -y postgresql postgresql-contrib
    
    systemctl restart postgresql
    systemctl enable postgresql
    
    if systemctl is-active --quiet postgresql; then
        success "✅ PostgreSQL安装成功！"
    else
        error "❌ PostgreSQL安装失败！"
    fi
    
    return_to_gui
}

install_redis() {
    if ! show_gui_yesno "安装Redis" "将安装Redis缓存数据库\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Redis..."
    
    apt-get update
    apt-get install -y redis-server
    
    sed -i 's/bind 127.0.0.1 ::1/bind 0.0.0.0/' /etc/redis/redis.conf 2>/dev/null || true
    
    systemctl restart redis-server
    systemctl enable redis-server
    
    if systemctl is-active --quiet redis-server; then
        success "✅ Redis安装成功！"
    else
        error "❌ Redis安装失败！"
    fi
    
    return_to_gui
}

install_mongodb() {
    if ! show_gui_yesno "安装MongoDB" "将安装MongoDB数据库\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装MongoDB..."
    
    wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/mongodb.gpg >/dev/null
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    
    apt-get update
    apt-get install -y mongodb-org
    
    systemctl start mongod
    systemctl enable mongod
    
    if systemctl is-active --quiet mongod; then
        success "✅ MongoDB安装成功！"
    else
        error "❌ MongoDB安装失败！"
    fi
    
    return_to_gui
}

install_sqlite() {
    if ! show_gui_yesno "安装SQLite" "将安装SQLite数据库\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装SQLite..."
    
    apt-get update
    apt-get install -y sqlite3 libsqlite3-dev
    
    local sqlite_version=$(sqlite3 --version 2>/dev/null | head -n1 | awk '{print $1}' || echo "未知")
    
    if command -v sqlite3 &>/dev/null; then
        success "✅ SQLite安装成功！"
        echo -e "${GREEN}版本: $sqlite_version${NC}"
    else
        error "❌ SQLite安装失败！"
    fi
    
    return_to_gui
}

programming_lang_menu() {
    while true; do
        choice=$(show_gui_menu "编程语言环境" 15 60 7 \
                  "1" "安装Python 3" \
                  "2" "安装Node.js" \
                  "3" "安装Java" \
                  "4" "安装PHP" \
                  "5" "安装Go" \
                  "6" "安装Ruby" \
                  "7" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_python3 ;;
            2) install_nodejs ;;
            3) install_java ;;
            4) install_php ;;
            5) install_golang ;;
            6) install_ruby ;;
            7) return ;;
        esac
    done
}

install_python3() {
    if ! show_gui_yesno "安装Python 3" "将安装Python 3及常用包\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Python 3..."
    
    apt-get update
    apt-get install -y python3 python3-pip python3-venv python3-dev
    
    pip3 install --upgrade pip
    pip3 install virtualenv flask django numpy pandas requests beautifulsoup4 scrapy 2>/dev/null || true
    
    local python_version=$(python3 --version 2>/dev/null || echo "未知")
    
    if command -v python3 &>/dev/null; then
        success "✅ Python 3安装成功！"
        echo -e "${GREEN}版本: $python_version${NC}"
    else
        error "❌ Python 3安装失败！"
    fi
    
    return_to_gui
}

install_nodejs() {
    if ! show_gui_yesno "安装Node.js" "将安装Node.js及npm\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Node.js..."
    
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    
    npm install -g npm yarn pm2 nrm
    
    local node_version=$(node --version 2>/dev/null || echo "未知")
    local npm_version=$(npm --version 2>/dev/null || echo "未知")
    
    if command -v node &>/dev/null; then
        success "✅ Node.js安装成功！"
        echo -e "${GREEN}Node.js版本: $node_version${NC}"
        echo -e "${GREEN}npm版本: $npm_version${NC}"
    else
        error "❌ Node.js安装失败！"
    fi
    
    return_to_gui
}

install_java() {
    if ! show_gui_yesno "安装Java" "将安装Java运行环境\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Java..."
    
    apt-get update
    apt-get install -y default-jdk default-jre
    
    local java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 2>/dev/null || echo "未知")
    
    if command -v java &>/dev/null; then
        success "✅ Java安装成功！"
        echo -e "${GREEN}版本: $java_version${NC}"
    else
        error "❌ Java安装失败！"
    fi
    
    return_to_gui
}

install_php() {
    if ! show_gui_yesno "安装PHP" "将安装PHP及常用扩展\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装PHP..."
    
    apt-get update
    apt-get install -y php php-cli php-fpm php-mysql php-pgsql php-sqlite3 php-curl php-gd php-mbstring php-xml php-zip php-bcmath php-json php-redis php-memcached
    
    local php_version=$(php --version 2>/dev/null | head -n1 | awk '{print $2}' || echo "未知")
    
    if command -v php &>/dev/null; then
        success "✅ PHP安装成功！"
        echo -e "${GREEN}版本: $php_version${NC}"
    else
        error "❌ PHP安装失败！"
    fi
    
    return_to_gui
}

install_golang() {
    if ! show_gui_yesno "安装Go语言" "将安装Go语言环境\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Go语言..."
    
    wget https://golang.org/dl/go1.21.0.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
    rm -f go1.21.0.linux-amd64.tar.gz
    
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo 'export GOPATH=$HOME/go' >> ~/.bashrc
    source ~/.bashrc
    
    local go_version=$(go version 2>/dev/null | awk '{print $3}' || echo "未知")
    
    if command -v go &>/dev/null; then
        success "✅ Go语言安装成功！"
        echo -e "${GREEN}版本: $go_version${NC}"
    else
        error "❌ Go语言安装失败！"
    fi
    
    return_to_gui
}

install_ruby() {
    if ! show_gui_yesno "安装Ruby" "将安装Ruby语言环境\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Ruby..."
    
    apt-get update
    apt-get install -y ruby-full
    
    local ruby_version=$(ruby --version 2>/dev/null | awk '{print $2}' || echo "未知")
    
    if command -v ruby &>/dev/null; then
        success "✅ Ruby安装成功！"
        echo -e "${GREEN}版本: $ruby_version${NC}"
    else
        error "❌ Ruby安装失败！"
    fi
    
    return_to_gui
}

dev_tools_menu() {
    while true; do
        choice=$(show_gui_menu "开发工具" 15 60 7 \
                  "1" "安装Git" \
                  "2" "安装VSCode Server" \
                  "3" "安装Vim增强版" \
                  "4" "安装Tmux" \
                  "5" "安装代码编辑器" \
                  "6" "安装构建工具" \
                  "7" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_git ;;
            2) install_vscode_server ;;
            3) install_vim_enhanced ;;
            4) install_tmux ;;
            5) install_code_editors ;;
            6) install_build_tools ;;
            7) return ;;
        esac
    done
}

install_git() {
    if ! show_gui_yesno "安装Git" "将安装Git版本控制工具\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Git..."
    
    apt-get update
    apt-get install -y git
    
    local git_version=$(git --version 2>/dev/null | awk '{print $3}' || echo "未知")
    
    if command -v git &>/dev/null; then
        success "✅ Git安装成功！"
        echo -e "${GREEN}版本: $git_version${NC}"
    else
        error "❌ Git安装失败！"
    fi
    
    return_to_gui
}

install_vscode_server() {
    if ! show_gui_yesno "安装VSCode Server" "将安装VS Code网页版\n\n默认端口: 8080\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "安装VSCode Server..."
    
    curl -fsSL https://code-server.dev/install.sh | sh
    
    mkdir -p ~/.config/code-server
    cat > ~/.config/code-server/config.yaml << EOF
bind-addr: 0.0.0.0:8080
auth: password
password: vscode123
cert: false
EOF
    
    systemctl --user enable --now code-server
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    if systemctl --user is-active --quiet code-server; then
        success "✅ VSCode Server安装成功！"
        echo -e "${GREEN}访问地址: http://${ip_address}:8080${NC}"
        echo -e "${GREEN}密码: vscode123${NC}"
    else
        error "❌ VSCode Server安装失败！"
    fi
    
    return_to_gui
}

install_vim_enhanced() {
    if ! show_gui_yesno "安装Vim增强版" "将安装增强版Vim编辑器\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Vim增强版..."
    
    apt-get update
    apt-get install -y vim vim-gtk3 vim-addon-manager vim-scripts
    
    cat > ~/.vimrc << EOF
syntax on
set number
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set cursorline
set showmatch
set incsearch
set hlsearch
EOF
    
    if command -v vim &>/dev/null; then
        success "✅ Vim增强版安装成功！"
    else
        error "❌ Vim安装失败！"
    fi
    
    return_to_gui
}

install_tmux() {
    if ! show_gui_yesno "安装Tmux" "将安装终端复用工具Tmux\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Tmux..."
    
    apt-get update
    apt-get install -y tmux
    
    cat > ~/.tmux.conf << EOF
set -g mouse on
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on
EOF
    
    if command -v tmux &>/dev/null; then
        success "✅ Tmux安装成功！"
    else
        error "❌ Tmux安装失败！"
    fi
    
    return_to_gui
}

install_code_editors() {
    while true; do
        choice=$(show_gui_menu "代码编辑器" 12 60 5 \
                  "1" "安装Nano" \
                  "2" "安装Micro" \
                  "3" "安装Emacs" \
                  "4" "安装Neovim" \
                  "5" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_nano ;;
            2) install_micro ;;
            3) install_emacs ;;
            4) install_neovim ;;
            5) return ;;
        esac
    done
}

install_nano() {
    info "安装Nano编辑器..."
    apt-get install -y nano
    success "✅ Nano安装成功！"
    return_to_gui
}

install_micro() {
    info "安装Micro编辑器..."
    curl -fsSL https://getmic.ro | bash
    mv micro /usr/local/bin/
    success "✅ Micro安装成功！"
    return_to_gui
}

install_emacs() {
    info "安装Emacs编辑器..."
    apt-get install -y emacs-nox
    success "✅ Emacs安装成功！"
    return_to_gui
}

install_neovim() {
    info "安装Neovim编辑器..."
    apt-get install -y neovim
    success "✅ Neovim安装成功！"
    return_to_gui
}

install_build_tools() {
    info "安装构建工具..."
    apt-get install -y build-essential cmake make gcc g++ autoconf automake libtool pkg-config
    success "✅ 构建工具安装成功！"
    return_to_gui
}

monitoring_tools_menu() {
    while true; do
        choice=$(show_gui_menu "监控工具" 15 60 7 \
                  "1" "安装htop" \
                  "2" "安装Glances" \
                  "3" "安装Netdata" \
                  "4" "安装Prometheus" \
                  "5" "安装Grafana" \
                  "6" "安装Node Exporter" \
                  "7" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_htop ;;
            2) install_glances ;;
            3) install_netdata ;;
            4) install_prometheus ;;
            5) install_grafana ;;
            6) install_node_exporter ;;
            7) return ;;
        esac
    done
}

install_htop() {
    info "安装htop..."
    apt-get install -y htop
    success "✅ htop安装成功！"
    return_to_gui
}

install_glances() {
    info "安装Glances..."
    apt-get install -y glances
    success "✅ Glances安装成功！"
    return_to_gui
}

install_netdata() {
    if ! show_gui_yesno "安装Netdata" "将安装Netdata监控工具\n\n默认端口: 19999\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Netdata..."
    
    wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh
    sh /tmp/netdata-kickstart.sh --non-interactive
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    if systemctl is-active --quiet netdata; then
        success "✅ Netdata安装成功！"
        echo -e "${GREEN}访问地址: http://${ip_address}:19999${NC}"
    else
        error "❌ Netdata安装失败！"
    fi
    
    return_to_gui
}

install_prometheus() {
    if ! show_gui_yesno "安装Prometheus" "将安装Prometheus监控系统\n\n默认端口: 9090\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Prometheus..."
    
    useradd --no-create-home --shell /bin/false prometheus
    mkdir -p /etc/prometheus /var/lib/prometheus
    
    wget https://github.com/prometheus/prometheus/releases/download/v2.47.0/prometheus-2.47.0.linux-amd64.tar.gz
    tar xvf prometheus-2.47.0.linux-amd64.tar.gz
    mv prometheus-2.47.0.linux-amd64/prometheus /usr/local/bin/
    mv prometheus-2.47.0.linux-amd64/promtool /usr/local/bin/
    mv prometheus-2.47.0.linux-amd64/prometheus.yml /etc/prometheus/
    mv prometheus-2.47.0.linux-amd64/console* /etc/prometheus/
    
    rm -rf prometheus-2.47.0.linux-amd64*
    
    cat > /etc/systemd/system/prometheus.service << EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF
    
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
    
    systemctl daemon-reload
    systemctl start prometheus
    systemctl enable prometheus
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    if systemctl is-active --quiet prometheus; then
        success "✅ Prometheus安装成功！"
        echo -e "${GREEN}访问地址: http://${ip_address}:9090${NC}"
    else
        error "❌ Prometheus安装失败！"
    fi
    
    return_to_gui
}

install_grafana() {
    if ! show_gui_yesno "安装Grafana" "将安装Grafana可视化工具\n\n默认端口: 3000\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Grafana..."
    
    apt-get install -y software-properties-common wget
    wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
    echo "deb https://packages.grafana.com/oss/deb stable main" | tee /etc/apt/sources.list.d/grafana.list
    apt-get update
    apt-get install -y grafana
    
    systemctl start grafana-server
    systemctl enable grafana-server
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    if systemctl is-active --quiet grafana-server; then
        success "✅ Grafana安装成功！"
        echo -e "${GREEN}访问地址: http://${ip_address}:3000${NC}"
        echo -e "${GREEN}用户名: admin${NC}"
        echo -e "${GREEN}密码: admin${NC}"
    else
        error "❌ Grafana安装失败！"
    fi
    
    return_to_gui
}

install_node_exporter() {
    if ! show_gui_yesno "安装Node Exporter" "将安装Node Exporter监控代理\n\n默认端口: 9100\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Node Exporter..."
    
    useradd --no-create-home --shell /bin/false node_exporter
    wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz
    tar xvf node_exporter-1.6.1.linux-amd64.tar.gz
    mv node_exporter-1.6.1.linux-amd64/node_exporter /usr/local/bin/
    rm -rf node_exporter-1.6.1.linux-amd64*
    
    cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl start node_exporter
    systemctl enable node_exporter
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    if systemctl is-active --quiet node_exporter; then
        success "✅ Node Exporter安装成功！"
        echo -e "${GREEN}访问地址: http://${ip_address}:9100/metrics${NC}"
    else
        error "❌ Node Exporter安装失败！"
    fi
    
    return_to_gui
}

security_tools_menu() {
    while true; do
        choice=$(show_gui_menu "安全工具" 15 60 7 \
                  "1" "安装Fail2ban" \
                  "2" "安装UFW防火墙" \
                  "3" "安装ClamAV杀毒" \
                  "4" "安装Rkhunter" \
                  "5" "安装Lynis" \
                  "6" "安装Tripwire" \
                  "7" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_fail2ban ;;
            2) install_ufw ;;
            3) install_clamav ;;
            4) install_rkhunter ;;
            5) install_lynis ;;
            6) install_tripwire ;;
            7) return ;;
        esac
    done
}

install_fail2ban() {
    info "安装Fail2ban..."
    apt-get install -y fail2ban
    systemctl start fail2ban
    systemctl enable fail2ban
    success "✅ Fail2ban安装成功！"
    return_to_gui
}

install_ufw() {
    info "安装UFW防火墙..."
    apt-get install -y ufw
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw allow https
    success "✅ UFW防火墙安装成功！"
    return_to_gui
}

install_clamav() {
    info "安装ClamAV杀毒软件..."
    apt-get install -y clamav clamav-daemon
    freshclam
    systemctl start clamav-daemon
    systemctl enable clamav-daemon
    success "✅ ClamAV安装成功！"
    return_to_gui
}

install_rkhunter() {
    info "安装Rkhunter..."
    apt-get install -y rkhunter
    rkhunter --update
    rkhunter --propupd
    success "✅ Rkhunter安装成功！"
    return_to_gui
}

install_lynis() {
    info "安装Lynis..."
    apt-get install -y lynis
    success "✅ Lynis安装成功！"
    return_to_gui
}

install_tripwire() {
    info "安装Tripwire..."
    apt-get install -y tripwire
    success "✅ Tripwire安装成功！"
    return_to_gui
}

network_tools_menu() {
    while true; do
        choice=$(show_gui_menu "网络工具" 15 60 7 \
                  "1" "安装iftop" \
                  "2" "安装nload" \
                  "3" "安装nethogs" \
                  "4" "安装iperf3" \
                  "5" "安装tcpdump" \
                  "6" "安装nmap" \
                  "7" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_iftop ;;
            2) install_nload ;;
            3) install_nethogs ;;
            4) install_iperf3 ;;
            5) install_tcpdump ;;
            6) install_nmap ;;
            7) return ;;
        esac
    done
}

install_iftop() {
    info "安装iftop..."
    apt-get install -y iftop
    success "✅ iftop安装成功！"
    return_to_gui
}

install_nload() {
    info "安装nload..."
    apt-get install -y nload
    success "✅ nload安装成功！"
    return_to_gui
}

install_nethogs() {
    info "安装nethogs..."
    apt-get install -y nethogs
    success "✅ nethogs安装成功！"
    return_to_gui
}

install_iperf3() {
    info "安装iperf3..."
    apt-get install -y iperf3
    success "✅ iperf3安装成功！"
    return_to_gui
}

install_tcpdump() {
    info "安装tcpdump..."
    apt-get install -y tcpdump
    success "✅ tcpdump安装成功！"
    return_to_gui
}

install_nmap() {
    info "安装nmap..."
    apt-get install -y nmap
    success "✅ nmap安装成功！"
    return_to_gui
}

system_tools_menu() {
    while true; do
        choice=$(show_gui_menu "系统工具" 15 60 7 \
                  "1" "安装系统监控工具" \
                  "2" "安装备份工具" \
                  "3" "安装日志分析工具" \
                  "4" "安装性能测试工具" \
                  "5" "安装压缩工具" \
                  "6" "安装文件管理工具" \
                  "7" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_system_monitor_tools ;;
            2) install_backup_tools ;;
            3) install_log_analysis_tools ;;
            4) install_perf_tools ;;
            5) install_compress_tools ;;
            6) install_file_management_tools ;;
            7) return ;;
        esac
    done
}

install_system_monitor_tools() {
    info "安装系统监控工具..."
    apt-get install -y atop iotop dstat sysstat glances screen
    success "✅ 系统监控工具安装成功！"
    return_to_gui
}

install_backup_tools() {
    info "安装备份工具..."
    apt-get install -y rsync duplicity rclone borgbackup
    success "✅ 备份工具安装成功！"
    return_to_gui
}

install_log_analysis_tools() {
    info "安装日志分析工具..."
    apt-get install -y logwatch logrotate multitail
    success "✅ 日志分析工具安装成功！"
    return_to_gui
}

install_perf_tools() {
    info "安装性能测试工具..."
    apt-get install -y stress stress-ng sysbench
    success "✅ 性能测试工具安装成功！"
    return_to_gui
}

install_compress_tools() {
    info "安装压缩工具..."
    apt-get install -y zip unzip rar unrar p7zip-full
    success "✅ 压缩工具安装成功！"
    return_to_gui
}

install_file_management_tools() {
    info "安装文件管理工具..."
    apt-get install -y tree ncdu mc ranger
    success "✅ 文件管理工具安装成功！"
    return_to_gui
}

control_panel_menu() {
    while true; do
        choice=$(show_gui_menu "控制面板安装" 18 70 9 \
                  "1" "安装1Panel" \
                  "2" "安装宝塔面板" \
                  "3" "安装Cockpit" \
                  "4" "安装Webmin" \
                  "5" "安装Ajenti" \
                  "6" "安装VestaCP" \
                  "7" "安装CyberPanel" \
                  "8" "安装HestiaCP" \
                  "9" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_1panel ;;
            2) install_baota ;;
            3) install_cockpit ;;
            4) install_webmin ;;
            5) install_ajenti ;;
            6) install_vestacp ;;
            7) install_cyberpanel ;;
            8) install_hestiacp ;;
            9) return ;;
        esac
    done
}

install_1panel() {
    if check_1panel_installed; then
        if ! show_gui_yesno "1Panel状态" "1Panel面板已经安装！\n\n是否重新安装？" 10 50; then
            return
        fi
    fi
    
    if ! show_gui_yesno "安装1Panel" "将安装1Panel面板\n\n重要提示：\n1. 安装过程中需要手动确认（输入 y）\n2. 需要设置面板访问密码\n3. 默认访问地址: https://服务器IP:9090\n\n是否继续？" 12 60; then
        return
    fi
    
    exit_to_terminal
    
    info "开始安装1Panel面板..."
    
    curl -fsSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh
    chmod +x quick_start.sh
    ./quick_start.sh
    
    sleep 5
    
    if check_1panel_installed; then
        success "✅ 1Panel面板安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}访问地址: https://${ip_address}:9090${NC}"
        echo -e "${GREEN}用户名: admin${NC}"
    else
        error "❌ 1Panel安装失败！"
    fi
    
    return_to_gui
}

install_baota() {
    if [ -f "/etc/init.d/bt" ]; then
        if ! show_gui_yesno "宝塔状态" "宝塔面板已经安装！\n\n是否重新安装？" 10 50; then
            return
        fi
    fi
    
    if ! show_gui_yesno "安装宝塔" "将安装宝塔面板\n\n重要提示：\n1. 安装过程需要5-10分钟\n2. 安装过程中需要确认（输入 y）\n3. 请保存显示的登录信息\n\n是否继续？" 12 60; then
        return
    fi
    
    exit_to_terminal
    
    info "开始安装宝塔面板..."
    
    if command -v curl &>/dev/null; then
        curl -fsSL https://download.bt.cn/install/install_panel.sh -o install_panel.sh
    else
        wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh
    fi
    
    bash install_panel.sh
    
    sleep 5
    
    if [ -f "/etc/init.d/bt" ]; then
        success "✅ 宝塔面板安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null)
        echo -e "${GREEN}访问地址: http://${ip_address}:8888${NC}"
    else
        error "❌ 宝塔面板安装失败！"
    fi
    
    return_to_gui
}

install_cockpit() {
    if ! show_gui_yesno "安装Cockpit" "将安装Cockpit服务器管理面板\n\n默认端口: 9090\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Cockpit..."
    
    apt-get update
    apt-get install -y cockpit cockpit-docker cockpit-networkmanager cockpit-storaged
    
    systemctl start cockpit
    systemctl enable cockpit
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    if systemctl is-active --quiet cockpit; then
        success "✅ Cockpit安装成功！"
        echo -e "${GREEN}访问地址: https://${ip_address}:9090${NC}"
    else
        error "❌ Cockpit安装失败！"
    fi
    
    return_to_gui
}

install_webmin() {
    if ! show_gui_yesno "安装Webmin" "将安装Webmin管理面板\n\n默认端口: 10000\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Webmin..."
    
    wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -
    echo "deb http://download.webmin.com/download/repository sarge contrib" | tee /etc/apt/sources.list.d/webmin.list
    apt-get update
    apt-get install -y webmin
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    if systemctl is-active --quiet webmin; then
        success "✅ Webmin安装成功！"
        echo -e "${GREEN}访问地址: https://${ip_address}:10000${NC}"
    else
        error "❌ Webmin安装失败！"
    fi
    
    return_to_gui
}

install_ajenti() {
    if ! show_gui_yesno "安装Ajenti" "将安装Ajenti管理面板\n\n默认端口: 8000\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "安装Ajenti..."
    
    wget -qO- https://raw.github.com/ajenti/ajenti/master/scripts/install-ubuntu.sh | bash
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    if systemctl is-active --quiet ajenti; then
        success "✅ Ajenti安装成功！"
        echo -e "${GREEN}访问地址: https://${ip_address}:8000${NC}"
    else
        error "❌ Ajenti安装失败！"
    fi
    
    return_to_gui
}

install_vestacp() {
    if ! show_gui_yesno "安装VestaCP" "将安装Vesta控制面板\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装VestaCP..."
    
    curl -O http://vestacp.com/pub/vst-install.sh
    bash vst-install.sh --nginx yes --apache yes --phpfpm yes --named yes --remi yes --vsftpd yes --proftpd yes --iptables yes --fail2ban yes --quota no --exim yes --dovecot yes --spamassassin yes --clamav yes --softaculous yes --mysql yes --postgresql no --hostname $(hostname) --email admin@$(hostname) --password admin123
    
    if [ -f "/usr/local/vesta/bin/v-list-sys-users" ]; then
        success "✅ VestaCP安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}访问地址: https://${ip_address}:8083${NC}"
        echo -e "${GREEN}用户名: admin${NC}"
        echo -e "${GREEN}密码: admin123${NC}"
    else
        error "❌ VestaCP安装失败！"
    fi
    
    return_to_gui
}

install_cyberpanel() {
    if ! show_gui_yesno "安装CyberPanel" "将安装CyberPanel控制面板\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装CyberPanel..."
    
    sh <(curl https://cyberpanel.net/install.sh || wget -O - https://cyberpanel.net/install.sh)
    
    if [ -f "/usr/local/CyberCP/CyberCP/settings.py" ]; then
        success "✅ CyberPanel安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}访问地址: https://${ip_address}:8090${NC}"
    else
        error "❌ CyberPanel安装失败！"
    fi
    
    return_to_gui
}

install_hestiacp() {
    if ! show_gui_yesno "安装HestiaCP" "将安装Hestia控制面板\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    
    info "安装HestiaCP..."
    
    wget https://raw.githubusercontent.com/hestiacp/hestiacp/release/install/hst-install.sh
    bash hst-install.sh --apache yes --phpfpm yes --multiphp yes --vsftpd yes --proftpd yes --named yes --exim yes --dovecot yes --sieve no --clamav yes --spamassassin yes --iptables yes --fail2ban yes --quota no --api yes --interactive no --email admin@$(hostname) --password admin123 --hostname $(hostname)
    
    if [ -f "/usr/local/hestia/bin/v-list-users" ]; then
        success "✅ HestiaCP安装成功！"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}访问地址: https://${ip_address}:8083${NC}"
        echo -e "${GREEN}用户名: admin${NC}"
        echo -e "${GREEN}密码: admin123${NC}"
    else
        error "❌ HestiaCP安装失败！"
    fi
    
    return_to_gui
}

install_common_tools_package() {
    if ! show_gui_yesno "安装常用工具包" "将安装常用服务器工具包\n\n包括：\n1. 系统工具\n2. 网络工具\n3. 监控工具\n4. 开发工具\n\n是否继续？" 12 60; then
        return
    fi
    
    exit_to_terminal
    
    info "开始安装常用工具包..."
    
    apt-get update
    
    local packages=(
        # 系统工具
        curl wget vim git net-tools htop ufw chrony
        screen tmux tree ncdu rsync jq bc pv
        
        # 网络工具
        iftop nload nethogs iperf3 tcpdump nmap netcat
        dnsutils telnet traceroute mtr
        
        # 监控工具
        glances atop iotop dstat sysstat
        
        # 开发工具
        build-essential cmake make gcc g++ python3-pip
        nodejs npm default-jdk
        
        # 安全工具
        fail2ban rkhunter lynis
        
        # 数据库工具
        mysql-client postgresql-client redis-tools
        mongodb-clients sqlite3
        
        # 压缩工具
        zip unzip rar unrar p7zip-full
        
        # 其他工具
        software-properties-common apt-transport-https ca-certificates
        gnupg lsb-release
    )
    
    apt-get install -y "${packages[@]}"
    
    success "✅ 常用工具包安装成功！"
    
    return_to_gui
}

system_optimization_menu() {
    while true; do
        choice=$(show_gui_menu "系统优化配置" 20 70 10 \
                  "1" "更新软件包列表" \
                  "2" "升级现有软件包" \
                  "3" "清理系统垃圾" \
                  "4" "设置时区和时间同步" \
                  "5" "配置SSH安全加固" \
                  "6" "优化内核参数" \
                  "7" "配置资源限制" \
                  "8" "配置防火墙" \
                  "9" "一键优化所有项目" \
                  "10" "返回主菜单")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) update_packages ;;
            2) upgrade_packages ;;
            3) cleanup_system ;;
            4) setup_timezone ;;
            5) configure_ssh ;;
            6) optimize_kernel ;;
            7) configure_resources ;;
            8) configure_firewall ;;
            9) full_optimization ;;
            10) return ;;
        esac
    done
}

update_packages() {
    if ! show_gui_yesno "更新软件包" "将更新系统软件包列表\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "更新软件包列表..."
    apt-get update -y
    check_status "软件包列表更新完成" "更新失败"
    return_to_gui
}

upgrade_packages() {
    if ! show_gui_yesno "升级软件包" "将升级现有软件包\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "升级现有软件包..."
    apt-get upgrade -y
    check_status "软件包升级完成" "升级失败"
    return_to_gui
}

cleanup_system() {
    if ! show_gui_yesno "清理系统垃圾" "将清理系统缓存和临时文件\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "清理系统垃圾..."
    apt-get autoremove -y
    apt-get clean
    apt-get autoclean
    rm -rf /tmp/*
    journalctl --vacuum-time=3d
    success "✅ 系统清理完成！"
    return_to_gui
}

setup_timezone() {
    if ! show_gui_yesno "设置时区" "将设置时区为上海并配置时间同步\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "设置时区为上海..."
    timedatectl set-timezone Asia/Shanghai
    check_status "时区设置成功" "时区设置失败"
    
    info "配置时间同步服务..."
    systemctl stop systemd-timesyncd 2>/dev/null || true
    systemctl disable systemd-timesyncd 2>/dev/null || true
    systemctl enable chronyd
    systemctl restart chronyd
    check_status "时间同步配置完成" "时间同步配置失败"
    
    return_to_gui
}

configure_ssh() {
    if ! show_gui_yesno "SSH安全加固" "将配置SSH安全加固设置\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "配置SSH安全加固..."
    if [ -f "/etc/ssh/sshd_config" ]; then
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config 2>/dev/null || true
        
        systemctl restart sshd
        check_status "SSH安全加固完成" "SSH配置失败"
    fi
    
    return_to_gui
}

optimize_kernel() {
    if ! show_gui_yesno "内核优化" "将优化内核参数\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "优化内核参数..."
    
    cat >> /etc/sysctl.conf << 'EOF'
# 网络优化
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.default_qdisc = fq
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30

# 系统优化
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
EOF
    
    sysctl -p 2>/dev/null
    check_status "内核参数已应用" "内核参数应用失败"
    return_to_gui
}

configure_resources() {
    if ! show_gui_yesno "资源限制" "将配置系统资源限制\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "配置资源限制..."
    
    cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
root soft nofile 65536
root hard nofile 65536
EOF
    
    log "资源限制配置完成"
    return_to_gui
}

configure_firewall() {
    if ! show_gui_yesno "防火墙配置" "将配置防火墙设置\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "配置防火墙..."
    echo "1. 启用UFW防火墙（推荐）"
    echo "2. 禁用UFW防火墙"
    echo "3. 保持当前状态"
    
    read -p "请选择 (1-3): " fw_choice
    case $fw_choice in
        1)
            ufw --force enable
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow 22/tcp
            ufw allow 80/tcp
            ufw allow 443/tcp
            log "UFW防火墙已启用并配置规则"
            ;;
        2)
            ufw --force disable
            log "UFW防火墙已禁用"
            ;;
        *)
            log "保持防火墙当前状态"
            ;;
    esac
    
    return_to_gui
}

full_optimization() {
    if ! show_gui_yesno "一键优化" "将执行所有系统优化操作\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "开始系统一键优化..."
    
    info "更新软件包列表..."
    apt-get update -y
    apt-get upgrade -y
    
    info "清理系统垃圾..."
    apt-get autoremove -y
    apt-get clean
    apt-get autoclean
    
    info "设置时区为上海..."
    timedatectl set-timezone Asia/Shanghai
    systemctl enable chronyd
    systemctl restart chronyd
    
    info "配置SSH安全..."
    if [ -f "/etc/ssh/sshd_config" ]; then
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config 2>/dev/null || true
        systemctl restart sshd
    fi
    
    info "优化内核参数..."
    cat >> /etc/sysctl.conf << 'EOF'
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.default_qdisc = fq
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF
    sysctl -p 2>/dev/null
    
    info "配置防火墙..."
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw allow https
    
    info "配置资源限制..."
    cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 65536
* hard nofile 65536
root soft nofile 65536
root hard nofile 65536
EOF
    
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}          系统一键优化完成！${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    
    return_to_gui
}

service_manager_menu() {
    while true; do
        choice=$(show_gui_menu "服务管理器" 15 60 6 \
                  "1" "检查所有服务状态" \
                  "2" "恢复所有停止的服务" \
                  "3" "重启所有服务" \
                  "4" "设置自动恢复模式" \
                  "5" "查看服务日志" \
                  "6" "返回主菜单")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) check_all_services ;;
            2) recover_all_services ;;
            3) restart_all_services ;;
            4) set_auto_recovery_mode ;;
            5) view_service_logs ;;
            6) return ;;
        esac
    done
}

check_all_services() {
    exit_to_terminal
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}               服务状态报告                  ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BLUE}系统信息：${NC}"
    echo "  系统: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
    echo "  时间: $(date)"
    echo "  运行时间: $(uptime -p 2>/dev/null || uptime)"
    echo ""
    
    echo -e "${BLUE}核心服务：${NC}"
    check_service_status "ssh" "SSH服务"
    check_service_status "chronyd" "时间同步"
    check_service_status "ufw" "防火墙"
    check_service_status "docker" "Docker"
    echo ""
    
    echo -e "${BLUE}面板服务：${NC}"
    if check_1panel_installed; then
        check_service_status "1panel" "1Panel"
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        if /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
            echo -e "  ${GREEN}✓ 宝塔面板: 正在运行${NC}"
        else
            echo -e "  ${YELLOW}⚠ 宝塔面板: 已安装但未运行${NC}"
        fi
    fi
    
    if systemctl list-unit-files | grep -q "cockpit" 2>/dev/null; then
        check_service_status "cockpit" "Cockpit"
    fi
    
    if systemctl list-unit-files | grep -q "webmin" 2>/dev/null; then
        check_service_status "webmin" "Webmin"
    fi
    echo ""
    
    echo -e "${GREEN}检查完成！${NC}"
    
    return_to_gui
}

recover_all_services() {
    if ! show_gui_yesno "恢复服务" "确定要恢复所有停止的服务吗？" 8 40; then
        log "取消服务恢复"
        return
    fi
    
    exit_to_terminal
    warn "开始恢复所有服务..."
    
    local system_services=("ssh" "chronyd" "ufw" "docker")
    for service in "${system_services[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service" 2>/dev/null && ! systemctl is-active --quiet "$service" 2>/dev/null; then
            start_service "$service"
        fi
    done
    
    if check_1panel_installed && ! systemctl is-active --quiet 1panel 2>/dev/null; then
        start_service "1panel" "1Panel"
    fi
    
    if [ -f "/etc/init.d/bt" ] && ! /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
        info "启动宝塔面板..."
        /etc/init.d/bt start 2>/dev/null
        if /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
            success "宝塔面板启动成功"
        else
            error "宝塔面板启动失败"
        fi
    fi
    
    if systemctl list-unit-files | grep -q "cockpit" 2>/dev/null && ! systemctl is-active --quiet cockpit 2>/dev/null; then
        start_service "cockpit" "Cockpit"
    fi
    
    if systemctl list-unit-files | grep -q "webmin" 2>/dev/null && ! systemctl is-active --quiet webmin 2>/dev/null; then
        start_service "webmin" "Webmin"
    fi
    
    success "所有服务恢复完成"
    return_to_gui
}

restart_all_services() {
    if ! show_gui_yesno "重启服务" "⚠ 警告：这将重启所有服务，可能导致短暂的服务中断\n\n确定要重启所有服务吗？" 10 50; then
        log "取消服务重启"
        return
    fi
    
    exit_to_terminal
    warn "开始重启所有服务..."
    
    local system_services=("ssh" "chronyd" "docker")
    for service in "${system_services[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service" 2>/dev/null; then
            restart_service "$service"
        fi
    done
    
    if check_1panel_installed; then
        restart_service "1panel" "1Panel"
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        info "重启宝塔面板..."
        /etc/init.d/bt restart 2>/dev/null
        sleep 3
        if /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
            success "宝塔面板重启成功"
        else
            error "宝塔面板重启失败"
        fi
    fi
    
    if systemctl list-unit-files | grep -q "cockpit" 2>/dev/null; then
        restart_service "cockpit" "Cockpit"
    fi
    
    if systemctl list-unit-files | grep -q "webmin" 2>/dev/null; then
        restart_service "webmin" "Webmin"
    fi
    
    success "所有服务重启完成"
    return_to_gui
}

set_auto_recovery_mode() {
    while true; do
        choice=$(show_gui_menu "自动恢复模式设置" 15 60 5 \
                  "1" "启用自动恢复模式" \
                  "2" "禁用自动恢复模式" \
                  "3" "创建开机自启动脚本" \
                  "4" "删除开机自启动脚本" \
                  "5" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1)
                AUTO_RECOVERY=true
                show_gui_msgbox "提示" "已启用自动恢复模式" 8 40
                ;;
            2)
                AUTO_RECOVERY=false
                show_gui_msgbox "提示" "已禁用自动恢复模式" 8 40
                ;;
            3)
                create_autostart_script
                ;;
            4)
                remove_autostart_script
                ;;
            5)
                return
                ;;
        esac
    done
}

create_autostart_script() {
    if ! show_gui_yesno "创建自启动脚本" "将创建开机自启动脚本，系统启动时自动恢复服务。\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    info "创建开机自启动脚本..."
    
    local service_file="/etc/systemd/system/yx-server-tools-recovery.service"
    local recovery_script="/usr/local/bin/yx-server-tools-recovery.sh"
    
    if [ -f "$service_file" ]; then
        echo -e "${YELLOW}检测到已存在的自启动服务，将覆盖...${NC}"
    fi
    
    cat > "$recovery_script" << 'EOF'
#!/bin/bash
# 服务器工具自动恢复脚本
# 在系统启动时自动恢复服务

LOG_FILE="/var/log/yx-server-tools/recovery.log"

mkdir -p /var/log/yx-server-tools 2>/dev/null

echo "==========================================" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S'): 开始自动恢复服务" >> "$LOG_FILE"
echo "==========================================" >> "$LOG_FILE"

echo "$(date '+%Y-%m-%d %H:%M:%S'): 等待网络就绪..." >> "$LOG_FILE"
sleep 15

services=("docker" "ssh" "chronyd" "ufw" "1panel" "cockpit" "webmin")
for service in "${services[@]}"; do
    echo "$(date '+%Y-%m-%d %H:%M:%S'): 检查${service}服务..." >> "$LOG_FILE"
    if systemctl list-unit-files | grep -q "${service}.service" 2>/dev/null; then
        if ! systemctl is-active --quiet "$service" 2>/dev/null; then
            echo "$(date '+%Y-%m-%d %H:%M:%S'): 启动${service}服务..." >> "$LOG_FILE"
            systemctl start "$service" >> "$LOG_FILE" 2>&1
            sleep 2
        fi
    fi
done

echo "$(date '+%Y-%m-%d %H:%M:%S'): 自动恢复服务完成" >> "$LOG_FILE"
echo "==========================================" >> "$LOG_FILE"
EOF
    
    chmod +x "$recovery_script"
    
    cat > "$service_file" << EOF
[Unit]
Description=服务器工具自动恢复服务
After=network.target docker.service
Wants=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash ${recovery_script}
RemainAfterExit=yes
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    
    chmod 644 "$service_file"
    
    systemctl daemon-reload
    systemctl enable yx-server-tools-recovery.service 2>/dev/null
    systemctl start yx-server-tools-recovery.service 2>/dev/null
    
    success "开机自启动脚本创建成功"
    return_to_gui
}

remove_autostart_script() {
    if ! show_gui_yesno "删除自启动脚本" "确定要删除开机自启动脚本吗？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "删除开机自启动脚本..."
    
    local service_file="/etc/systemd/system/yx-server-tools-recovery.service"
    local recovery_script="/usr/local/bin/yx-server-tools-recovery.sh"
    
    systemctl stop yx-server-tools-recovery.service 2>/dev/null
    systemctl disable yx-server-tools-recovery.service 2>/dev/null
    systemctl daemon-reload
    
    rm -f "$service_file" 2>/dev/null
    rm -f "$recovery_script" 2>/dev/null
    
    success "开机自启动脚本已删除"
    return_to_gui
}

view_service_logs() {
    while true; do
        choice=$(show_gui_menu "查看服务日志" 12 60 5 \
                  "1" "查看Docker日志" \
                  "2" "查看系统日志" \
                  "3" "查看恢复日志" \
                  "4" "查看安装日志" \
                  "5" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1)
                exit_to_terminal
                echo -e "${CYAN}Docker日志：${NC}"
                journalctl -u docker -n 30 --no-pager 2>/dev/null || echo "Docker日志不可用"
                return_to_gui
                ;;
            2)
                exit_to_terminal
                echo -e "${CYAN}系统日志：${NC}"
                dmesg | tail -30 2>/dev/null || echo "系统日志不可用"
                return_to_gui
                ;;
            3)
                exit_to_terminal
                echo -e "${CYAN}恢复日志：${NC}"
                if [ -f "/var/log/yx-server-tools/recovery.log" ]; then
                    tail -30 "/var/log/yx-server-tools/recovery.log"
                else
                    echo "恢复日志文件不存在"
                fi
                return_to_gui
                ;;
            4)
                exit_to_terminal
                echo -e "${CYAN}安装日志：${NC}"
                if [ -f "$INSTALL_LOG" ]; then
                    tail -30 "$INSTALL_LOG"
                else
                    echo "安装日志文件不存在"
                fi
                return_to_gui
                ;;
            5)
                return
                ;;
        esac
    done
}

system_check_menu() {
    exit_to_terminal
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}       系统完整性检查报告${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BLUE}1. 系统信息：${NC}"
    echo "   OS: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
    echo "   内核: $(uname -r)"
    echo "   架构: $(uname -m)"
    
    echo ""
    echo -e "${BLUE}2. 资源使用：${NC}"
    echo -n "   内存: "
    free -h | awk 'NR==2{print $4 " / " $2}' 2>/dev/null || echo "未知"
    echo -n "   磁盘: "
    df -h / | awk 'NR==2{print $4 " / " $2}' 2>/dev/null || echo "未知"
    
    echo ""
    echo -e "${BLUE}3. 服务状态：${NC}"
    
    if check_docker_installed; then
        echo "   ✓ Docker: 已安装且运行正常"
    else
        echo "   ✗ Docker: 未安装或未运行"
    fi
    
    if check_1panel_installed; then
        echo "   ✓ 1Panel: 已安装"
        if systemctl is-active --quiet 1panel 2>/dev/null; then
            echo "       服务状态: 运行中"
        else
            echo "       服务状态: 未运行"
        fi
    else
        echo "   ✗ 1Panel: 未安装"
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        echo "   ✓ 宝塔: 已安装"
        if /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
            echo "       服务状态: 运行中"
        else
            echo "       服务状态: 未运行"
        fi
    else
        echo "   ✗ 宝塔: 未安装"
    fi
    
    echo ""
    echo -e "${BLUE}4. 网络状态：${NC}"
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "未知")
    echo "   IP地址: $ip_address"
    
    echo ""
    show_separator
    echo -e "${GREEN}检查完成！${NC}"
    
    return_to_gui
}

uninstall_menu() {
    while true; do
        choice=$(show_gui_menu "卸载工具" 15 60 7 \
                  "1" "卸载Docker" \
                  "2" "卸载1Panel面板" \
                  "3" "卸载宝塔面板" \
                  "4" "卸载其他面板" \
                  "5" "清理所有安装" \
                  "6" "清理临时文件" \
                  "7" "返回主菜单")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) uninstall_docker ;;
            2) uninstall_1panel ;;
            3) uninstall_baota ;;
            4) uninstall_other_panels ;;
            5) cleanup_all ;;
            6) cleanup_temp_files ;;
            7) return ;;
        esac
    done
}

uninstall_docker() {
    if ! show_gui_yesno "卸载Docker" "确定要卸载Docker吗？" 8 40; then
        return
    fi
    
    exit_to_terminal
    warn "开始卸载Docker..."
    
    info "停止Docker服务..."
    systemctl stop docker 2>/dev/null
    systemctl stop containerd 2>/dev/null
    
    info "卸载Docker软件包..."
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
    apt-get purge -y docker-ce docker-ce-cli containerd.io 2>/dev/null
    
    info "清理Docker数据..."
    rm -rf /var/lib/docker 2>/dev/null
    rm -rf /var/lib/containerd 2>/dev/null
    rm -rf /etc/docker 2>/dev/null
    
    success "Docker卸载完成"
    return_to_gui
}

uninstall_1panel() {
    if ! check_1panel_installed; then
        show_gui_msgbox "提示" "1Panel面板未安装" 8 40
        return
    fi
    
    if ! show_gui_yesno "卸载1Panel" "确定要卸载1Panel面板吗？" 8 40; then
        return
    fi
    
    exit_to_terminal
    warn "开始卸载1Panel面板..."
    
    info "停止1Panel服务..."
    systemctl stop 1panel 2>/dev/null || true
    systemctl disable 1panel 2>/dev/null || true
    
    rm -rf /opt/1panel 2>/dev/null
    rm -rf /usr/local/bin/1panel 2>/dev/null
    rm -rf /usr/local/bin/1pctl 2>/dev/null
    rm -f /etc/systemd/system/1panel.service 2>/dev/null
    
    success "1Panel面板卸载完成"
    return_to_gui
}

uninstall_baota() {
    if [ ! -f "/etc/init.d/bt" ]; then
        show_gui_msgbox "提示" "宝塔面板未安装" 8 40
        return
    fi
    
    if ! show_gui_yesno "卸载宝塔" "确定要卸载宝塔面板吗？" 8 40; then
        return
    fi
    
    exit_to_terminal
    warn "开始卸载宝塔面板..."
    
    info "停止宝塔面板..."
    /etc/init.d/bt stop 2>/dev/null || true
    
    rm -rf /www/server/panel 2>/dev/null
    rm -f /etc/init.d/bt 2>/dev/null
    
    success "宝塔面板卸载完成"
    return_to_gui
}

uninstall_other_panels() {
    while true; do
        choice=$(show_gui_menu "卸载其他面板" 12 60 5 \
                  "1" "卸载Cockpit" \
                  "2" "卸载Webmin" \
                  "3" "卸载Ajenti" \
                  "4" "卸载VestaCP" \
                  "5" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) uninstall_cockpit ;;
            2) uninstall_webmin ;;
            3) uninstall_ajenti ;;
            4) uninstall_vestacp ;;
            5) return ;;
        esac
    done
}

uninstall_cockpit() {
    info "卸载Cockpit..."
    apt-get remove -y cockpit cockpit-*
    success "Cockpit卸载完成"
    return_to_gui
}

uninstall_webmin() {
    info "卸载Webmin..."
    apt-get remove -y webmin
    rm -f /etc/apt/sources.list.d/webmin.list
    success "Webmin卸载完成"
    return_to_gui
}

uninstall_ajenti() {
    info "卸载Ajenti..."
    apt-get remove -y ajenti
    success "Ajenti卸载完成"
    return_to_gui
}

uninstall_vestacp() {
    info "卸载VestaCP..."
    rm -f /usr/local/vesta/uninstall.sh
    /usr/local/vesta/uninstall.sh
    success "VestaCP卸载完成"
    return_to_gui
}

cleanup_all() {
    if ! show_gui_yesno "清理所有安装" "⚠ 警告：这将卸载所有通过本脚本安装的软件\n包括：\n1. Docker\n2. 所有控制面板\n3. 各种工具\n\n确定要清理所有安装吗？" 12 60; then
        return
    fi
    
    exit_to_terminal
    warn "开始清理所有安装..."
    
    if check_1panel_installed; then
        warn "卸载1Panel面板..."
        systemctl stop 1panel 2>/dev/null
        rm -rf /opt/1panel 2>/dev/null
        rm -rf /usr/local/bin/1panel 2>/dev/null
        rm -f /etc/systemd/system/1panel.service 2>/dev/null
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        warn "卸载宝塔面板..."
        /etc/init.d/bt stop 2>/dev/null
        rm -rf /www/server/panel 2>/dev/null
        rm -f /etc/init.d/bt 2>/dev/null
    fi
    
    if check_docker_installed; then
        warn "卸载Docker..."
        systemctl stop docker 2>/dev/null
        apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
        rm -rf /var/lib/docker 2>/dev/null
        rm -rf /etc/docker 2>/dev/null
    fi
    
    info "清理临时文件..."
    rm -f quick_start.sh 2>/dev/null
    rm -f install_panel.sh 2>/dev/null
    find "$LOG_DIR" -type f -name "*.log" -mtime +7 -delete 2>/dev/null
    
    success "所有安装清理完成"
    return_to_gui
}

cleanup_temp_files() {
    if ! show_gui_yesno "清理临时文件" "确定要清理临时文件吗？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "清理临时文件..."
    
    rm -f quick_start.sh 2>/dev/null
    rm -f install_panel.sh 2>/dev/null
    find "$LOG_DIR" -type f -name "*.log" -mtime +7 -delete 2>/dev/null
    
    log "临时文件清理完成"
    return_to_gui
}

main_menu() {
    while true; do
        choice=$(show_gui_menu "主菜单 Pro版 v$SCRIPT_VERSION" 20 70 10 \
                  "1" "服务器工具安装" \
                  "2" "系统优化配置" \
                  "3" "服务管理器" \
                  "4" "系统状态检查" \
                  "5" "卸载工具" \
                  "6" "关于本程序" \
                  "0" "退出程序")
        
        if [ -z "$choice" ]; then
            exit_program
            continue
        fi
        
        case $choice in
            1) server_tools_menu ;;
            2) system_optimization_menu ;;
            3) service_manager_menu ;;
            4) system_check_menu ;;
            5) uninstall_menu ;;
            6) show_about ;;
            0) exit_program ;;
        esac
    done
}

show_about() {
    exit_to_terminal
    
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║        服务器工具安装管理 Pro版 v$SCRIPT_VERSION         ║"
    echo "║               专业服务器管理工具集                       ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${CYAN}功能特性：${NC}"
    echo "  • Docker及容器工具管理"
    echo "  • Web服务器安装配置"
    echo "  • 数据库环境部署"
    echo "  • 编程语言环境搭建"
    echo "  • 开发工具集成"
    echo "  • 监控工具安装"
    echo "  • 安全工具配置"
    echo "  • 网络工具集合"
    echo "  • 系统工具管理"
    echo "  • 多种控制面板支持"
    echo ""
    
    echo -e "${CYAN}支持的面板：${NC}"
    echo "  • 1Panel"
    echo "  • 宝塔面板"
    echo "  • Cockpit"
    echo "  • Webmin"
    echo "  • Ajenti"
    echo "  • VestaCP"
    echo "  • CyberPanel"
    echo "  • HestiaCP"
    echo ""
    
    echo -e "${CYAN}系统要求：${NC}"
    echo "  • Ubuntu 20.04/22.04/24.04"
    echo "  • 推荐2GB以上内存"
    echo "  • 至少10GB可用磁盘空间"
    echo ""
    
    echo -e "${YELLOW}安装日志: $INSTALL_LOG${NC}"
    echo ""
    
    read -p "按回车键返回主菜单... "
    
    return_to_gui
}

exit_program() {
    if show_gui_yesno "退出程序" "确定要退出吗？" 8 40; then
        clear
        echo -e "${GREEN}感谢使用服务器工具安装管理 Pro版！${NC}"
        echo -e "${YELLOW}日志文件: $INSTALL_LOG${NC}"
        exit 0
    fi
}

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log "使用root权限运行"
        return 0
    fi
    
    info "检测到非root用户，尝试使用sudo..."
    
    if ! command -v sudo &>/dev/null; then
        error "未找到sudo命令，请以root用户运行此脚本"
        echo -e "${YELLOW}可以使用以下方式：${NC}"
        echo "1. sudo bash $0"
        echo "2. su - root"
        echo "3. 切换到root用户"
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}需要sudo权限来运行此脚本${NC}"
        echo "请输入密码继续..."
        sudo echo "sudo权限检查通过" || {
            error "sudo权限验证失败"
            exit 1
        }
    fi
    
    warn "重新以sudo权限运行脚本..."
    exec sudo bash "$0" "$@"
}

check_ubuntu_version() {
    if [ ! -f "/etc/os-release" ]; then
        error "无法检测操作系统"
        exit 1
    fi
    
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "本脚本仅适用于Ubuntu系统！"
        echo -e "${YELLOW}检测到的系统：${NC}"
        grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2
        exit 1
    fi
    
    local version=$(grep "VERSION_ID" /etc/os-release | cut -d'"' -f2)
    log "检测到 Ubuntu $version 系统 ✓"
}

check_required_tools() {
    info "检查必要工具..."
    
    local tools=("curl" "wget" "grep" "awk" "sed" "cut" "systemctl")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        warn "缺少必要工具: ${missing[*]}"
        info "自动安装缺失工具..."
        
        apt-get update -y >/dev/null 2>&1
        for tool in "${missing[@]}"; do
            case $tool in
                "curl") apt-get install -y curl >/dev/null 2>&1 ;;
                "wget") apt-get install -y wget >/dev/null 2>&1 ;;
                *) apt-get install -y "$tool" >/dev/null 2>&1 ;;
            esac
            check_status "已安装 $tool" "安装 $tool 失败"
        done
    else
        log "所有必要工具已安装 ✓"
    fi
}

confirm_execution() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║        服务器工具安装管理 Pro版 v$SCRIPT_VERSION         ║"
    echo "║               专业服务器管理工具集                       ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    echo -e "${CYAN}系统信息：${NC}"
    echo "  OS: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
    echo "  内核: $(uname -r)"
    echo "  架构: $(uname -m)"
    echo ""
    
    echo -e "${YELLOW}⚠  警告：本脚本将修改系统配置并安装软件${NC}"
    echo -e "${YELLOW}请确保您已经备份重要数据${NC}"
    echo ""
    echo -e "${CYAN}日志文件: ${INSTALL_LOG}${NC}"
    echo -e "${CYAN}备份目录: ${BACKUP_DIR}${NC}"
    echo ""
    
    check_disk_space
    check_network
    
    read -p "按回车键进入主菜单，或按 Ctrl+C 退出... "
}

main() {
    validate_license
    init_log_system
    check_sudo "$@"
    check_required_tools
    check_dialog
    check_ubuntu_version
    confirm_execution
    
    local start_time=$(date +%s)
    log "脚本开始执行 (v$SCRIPT_VERSION)"
    
    main_menu
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log "脚本执行完成，总耗时: ${duration}秒"
}

trap 'error "脚本被中断"; echo -e "${YELLOW}日志文件: ${INSTALL_LOG}${NC}"; exit 1' INT TERM

main "$@"

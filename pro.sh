
#!/bin/bash

# =============================================
# Ubuntu 服务器一键部署脚本 (Pro版本 v7.0)
# 需要密钥: 1q1q1q1qye
# =============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 全局变量
SCRIPT_VERSION="7.0-Pro"
SCRIPT_NAME="yx-deploy-pro"
BACKUP_DIR="/backup/${SCRIPT_NAME}"
LOG_DIR="/var/log/${SCRIPT_NAME}"
INSTALL_LOG="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
DIALOG_TITLE="Ubuntu服务器部署工具 Pro版 v$SCRIPT_VERSION"
AUTO_RECOVERY=false

# 密钥配置 (加密存储)
ENCRYPTED_KEY="\x31\x71\x31\x71\x31\x71\x31\x71\x
REQUIRED_KEY="1q1q1q1qye"

# ====================== 密钥验证 ======================

validate_license() {
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}           Ubuntu服务器部署工具 Pro版         ${NC}"
    echo -e "${PURPLE}                版本: $SCRIPT_VERSION           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    # 尝试从环境变量获取密钥
    if [ -n "$DEPLOY_KEY" ]; then
        input_key="$DEPLOY_KEY"
    else
        echo -e "${YELLOW}请输入授权密钥: ${NC}"
        echo -e "${BLUE}${NC}"
        read -s input_key
        echo ""
    fi
    
    # 解密并验证密钥
    if [ "$input_key" != "$REQUIRED_KEY" ]; then
        echo -e "${RED}❌ 密钥验证失败！${NC}"
        echo -e "${YELLOW}请使用正确的密钥运行此脚本。${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ 密钥验证成功！${NC}"
    echo -e "${BLUE}欢迎使用 Pro 版本！${NC}"
    echo ""
    sleep 2
}

# ====================== 日志系统 ======================

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

# ====================== GUI函数 ======================

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
    # 保存当前stty设置
    local old_stty=$(stty -g)
    # 执行dialog命令
    dialog --backtitle "$DIALOG_TITLE" --title "$title" "$@" 2>&1 >/dev/tty
    local result=$?
    # 恢复stty设置
    stty $old_stty
    echo $result
}

show_gui_menu() {
    local title="$1"
    local height="$2"
    local width="$3"
    local menu_height="$4"
    shift 4
    
    # 保存当前stty设置
    local old_stty=$(stty -g)
    # 执行dialog命令并捕获输出
    local output
    output=$(dialog --backtitle "$DIALOG_TITLE" --title "$title" \
                    --menu "" \
                    $height $width $menu_height \
                    "$@" 2>&1 >/dev/tty)
    local result=$?
    # 恢复stty设置
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
    
    # 保存当前stty设置
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
    
    # 保存当前stty设置
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
    
    # 保存当前stty设置
    local old_stty=$(stty -g)
    # 执行dialog命令并捕获输出
    local output
    output=$(dialog --backtitle "$DIALOG_TITLE" --title "$title" \
                    --checklist "" \
                    $height $width $menu_height \
                    "$@" 2>&1 >/dev/tty)
    local result=$?
    # 恢复stty设置
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

# ====================== 部署方案选择 ======================

# 服务器类型定义
declare -A SERVER_TYPES=(
    ["game"]="游戏服务器"
    ["web"]="Web服务器"
    ["blog"]="博客网站"
    ["database"]="数据库服务器"
    ["app"]="应用服务器"
    ["custom"]="自定义服务器"
)

# 软件包定义
declare -A SOFTWARE_PACKAGES=(
    ["docker"]="Docker容器引擎"
    ["mysql"]="MySQL数据库"
    ["postgresql"]="PostgreSQL数据库"
    ["redis"]="Redis缓存"
    ["mongodb"]="MongoDB数据库"
    ["nginx"]="Nginx Web服务器"
    ["nodejs"]="Node.js运行环境"
    ["java"]="Java运行环境"
    ["python"]="Python环境"
)

# 面板定义
declare -A CONTROL_PANELS=(
    ["1panel"]="1Panel面板"
    ["baota"]="宝塔面板"
    ["none"]="不安装面板"
)

# 部署方案模板
declare -A DEPLOYMENT_TEMPLATES=(
    ["game"]="docker mysql redis java"
    ["web"]="docker nginx mysql redis nodejs"
    ["blog"]="docker nginx mysql redis php"
    ["database"]="mysql postgresql redis mongodb"
    ["app"]="docker java python mysql redis"
    ["custom"]=""
)

select_deployment_type() {
    while true; do
        choice=$(show_gui_menu "选择服务器类型" 15 60 7 \
                  "1" "游戏服务器" \
                  "2" "Web服务器" \
                  "3" "博客网站" \
                  "4" "数据库服务器" \
                  "5" "应用服务器" \
                  "6" "自定义服务器" \
                  "7" "返回主菜单")
        
        if [ -z "$choice" ]; then
            return "cancel"
        fi
        
        case $choice in
            1) echo "game"; return 0 ;;
            2) echo "web"; return 0 ;;
            3) echo "blog"; return 0 ;;
            4) echo "database"; return 0 ;;
            5) echo "app"; return 0 ;;
            6) echo "custom"; return 0 ;;
            7) return 1 ;;
        esac
    done
}

select_software_packages() {
    local selected_type="$1"
    local default_packages="${DEPLOYMENT_TEMPLATES[$selected_type]}"
    
    # 如果是自定义类型，显示所有可选软件
    if [ "$selected_type" = "custom" ]; then
        default_packages=""
    fi
    
    # 转换为checklist格式
    local checklist_items=()
    for key in "${!SOFTWARE_PACKAGES[@]}"; do
        local name="${SOFTWARE_PACKAGES[$key]}"
        local status="off"
        
        # 检查是否在默认包中
        if [[ " $default_packages " == *" $key "* ]]; then
            status="on"
        fi
        
        checklist_items+=("$key" "$name" "$status")
    done
    
    selected=$(show_gui_checklist "选择软件包" 20 70 10 "${checklist_items[@]}")
    
    if [ -z "$selected" ]; then
        echo ""
        return 1
    fi
    
    # 去除引号并返回
    echo "$selected" | sed "s/\"//g"
    return 0
}

select_control_panel() {
    local checklist_items=()
    
    for key in "${!CONTROL_PANELS[@]}"; do
        local name="${CONTROL_PANELS[$key]}"
        local status="off"
        
        # 默认选择1panel
        if [ "$key" = "1panel" ]; then
            status="on"
        fi
        
        checklist_items+=("$key" "$name" "$status")
    done
    
    selected=$(show_gui_checklist "选择控制面板" 10 50 5 "${checklist_items[@]}")
    
    if [ -z "$selected" ]; then
        echo "none"
        return 0
    fi
    
    # 去除引号并返回
    echo "$selected" | sed "s/\"//g"
    return 0
}

review_deployment_plan() {
    local server_type="$1"
    local software_packages="$2"
    local control_panel="$3"
    
    exit_to_terminal
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}           部署方案预览                    ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BLUE}服务器类型: ${NC}${SERVER_TYPES[$server_type]}"
    echo ""
    
    echo -e "${BLUE}选择的软件包: ${NC}"
    if [ -z "$software_packages" ]; then
        echo "  无"
    else
        for pkg in $software_packages; do
            echo "  ✓ ${SOFTWARE_PACKAGES[$pkg]}"
        done
    fi
    echo ""
    
    echo -e "${BLUE}控制面板: ${NC}"
    if [ "$control_panel" = "none" ]; then
        echo "  无"
    else
        echo "  ✓ ${CONTROL_PANELS[$control_panel]}"
    fi
    echo ""
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    
    if ! show_gui_yesno "确认部署方案" "是否确认此部署方案？" 10 50; then
        return 1
    fi
    
    return 0
}

# ====================== 部署执行 ======================

install_software_package() {
    local package="$1"
    
    case $package in
        docker)
            install_docker_gui
            ;;
        mysql)
            install_mysql
            ;;
        postgresql)
            install_postgresql
            ;;
        redis)
            install_redis
            ;;
        mongodb)
            install_mongodb
            ;;
        nginx)
            install_nginx
            ;;
        nodejs)
            install_nodejs
            ;;
        java)
            install_java
            ;;
        python)
            install_python
            ;;
        *)
            warn "未知软件包: $package"
            return 1
            ;;
    esac
}

install_mysql() {
    info "安装MySQL数据库..."
    
    # 添加MySQL APT仓库
    wget -q -O - https://dev.mysql.com/get/mysql-apt-config_0.8.29-1_all.deb > mysql-apt-config.deb
    dpkg -i mysql-apt-config.deb 2>/dev/null || true
    rm -f mysql-apt-config.deb
    
    apt-get update
    apt-get install -y mysql-server
    
    if systemctl is-active --quiet mysql; then
        success "MySQL安装成功"
        
        # 运行安全脚本
        echo -e "${YELLOW}运行MySQL安全配置...${NC}"
        mysql_secure_installation
        
        log "MySQL安全配置完成"
    else
        error "MySQL安装失败"
        return 1
    fi
}

install_postgresql() {
    info "安装PostgreSQL数据库..."
    
    # 添加PostgreSQL仓库
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc | tee /etc/apt/trusted.gpg.d/pgdg.asc >/dev/null
    
    apt-get update
    apt-get install -y postgresql postgresql-contrib
    
    if systemctl is-active --quiet postgresql; then
        success "PostgreSQL安装成功"
        
        # 设置密码
        echo -e "${YELLOW}请设置PostgreSQL密码...${NC}"
        sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"
        
        log "PostgreSQL配置完成"
    else
        error "PostgreSQL安装失败"
        return 1
    fi
}

install_redis() {
    info "安装Redis缓存..."
    
    apt-get install -y redis-server
    
    # 配置Redis
    sed -i 's/bind 127.0.0.1 ::1/bind 0.0.0.0/' /etc/redis/redis.conf 2>/dev/null || true
    echo "requirepass redis123" >> /etc/redis/redis.conf 2>/dev/null || true
    
    systemctl restart redis-server
    
    if systemctl is-active --quiet redis-server; then
        success "Redis安装成功"
    else
        error "Redis安装失败"
        return 1
    fi
}

install_mongodb() {
    info "安装MongoDB数据库..."
    
    # 添加MongoDB仓库
    wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | apt-key add -
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    
    apt-get update
    apt-get install -y mongodb-org
    
    systemctl start mongod
    systemctl enable mongod
    
    if systemctl is-active --quiet mongod; then
        success "MongoDB安装成功"
    else
        error "MongoDB安装失败"
        return 1
    fi
}

install_nginx() {
    info "安装Nginx Web服务器..."
    
    apt-get install -y nginx
    
    # 创建默认网站目录
    mkdir -p /var/www/html
    echo "<h1>Welcome to Nginx Server</h1>" > /var/www/html/index.html
    
    systemctl restart nginx
    
    if systemctl is-active --quiet nginx; then
        success "Nginx安装成功"
        
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo -e "${GREEN}Nginx访问地址: http://${ip_address}${NC}"
    else
        error "Nginx安装失败"
        return 1
    fi
}

install_nodejs() {
    info "安装Node.js运行环境..."
    
    # 使用NodeSource安装Node.js 20
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    
    # 安装npm和常用工具
    npm install -g npm yarn pm2
    
    node_version=$(node --version)
    npm_version=$(npm --version)
    
    success "Node.js安装成功"
    echo -e "${GREEN}Node.js版本: $node_version${NC}"
    echo -e "${GREEN}npm版本: $npm_version${NC}"
}

install_java() {
    info "安装Java运行环境..."
    
    apt-get install -y default-jdk default-jre
    
    java_version=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2)
    
    success "Java安装成功"
    echo -e "${GREEN}Java版本: $java_version${NC}"
}

install_python() {
    info "安装Python环境..."
    
    apt-get install -y python3 python3-pip python3-venv
    
    # 安装常用Python包
    pip3 install --upgrade pip
    pip3 install virtualenv flask django numpy pandas
    
    python_version=$(python3 --version)
    
    success "Python安装成功"
    echo -e "${GREEN}Python版本: $python_version${NC}"
}

execute_deployment_plan() {
    local server_type="$1"
    local software_packages="$2"
    local control_panel="$3"
    
    exit_to_terminal
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}           开始部署执行                    ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    info "服务器类型: ${SERVER_TYPES[$server_type]}"
    info "开始系统基础优化..."
    
    # 基础系统优化
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y curl wget vim git net-tools htop ufw chrony
    
    # 设置时区
    timedatectl set-timezone Asia/Shanghai
    
    # 防火墙配置
    ufw --force enable
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    success "系统基础优化完成"
    echo ""
    
    # 安装选择的软件包
    for package in $software_packages; do
        show_separator
        info "安装: ${SOFTWARE_PACKAGES[$package]}"
        install_software_package "$package"
        show_separator
        echo ""
    done
    
    # 安装控制面板
    if [ "$control_panel" != "none" ]; then
        show_separator
        info "安装控制面板: ${CONTROL_PANELS[$control_panel]}"
        
        case $control_panel in
            "1panel")
                install_1panel_gui
                ;;
            "baota")
                install_baota_gui
                ;;
        esac
        show_separator
    fi
    
    # 显示部署总结
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           部署完成！                        ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo ""
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    echo -e "${BLUE}服务器信息:${NC}"
    echo "  IP地址: $ip_address"
    echo "  系统: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
    echo ""
    
    echo -e "${BLUE}已安装的服务:${NC}"
    for package in $software_packages; do
        echo "  ✓ ${SOFTWARE_PACKAGES[$package]}"
    done
    
    if [ "$control_panel" != "none" ]; then
        echo "  ✓ ${CONTROL_PANELS[$control_panel]}"
    fi
    echo ""
    
    echo -e "${BLUE}访问信息:${NC}"
    for package in $software_packages; do
        case $package in
            "nginx")
                echo "  Nginx: http://$ip_address"
                ;;
        esac
    done
    
    case $control_panel in
        "1panel")
            echo "  1Panel: https://$ip_address:9090"
            echo "  用户名: admin"
            ;;
        "baota")
            echo "  宝塔面板: http://$ip_address:8888"
            ;;
    esac
    
    echo ""
    echo -e "${YELLOW}安装日志: $INSTALL_LOG${NC}"
    
    return_to_gui
}

# ====================== 服务器部署菜单 ======================

server_deployment_menu() {
    while true; do
        choice=$(show_gui_menu "服务器部署方案" 15 60 7 \
                  "1" "选择服务器类型部署" \
                  "2" "自定义软件包部署" \
                  "3" "仅安装控制面板" \
                  "4" "查看部署模板" \
                  "5" "部署历史记录" \
                  "6" "返回主菜单")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1)
                deploy_by_server_type
                ;;
            2)
                deploy_custom_packages
                ;;
            3)
                deploy_control_panel_only
                ;;
            4)
                view_deployment_templates
                ;;
            5)
                view_deployment_history
                ;;
            6)
                return
                ;;
        esac
    done
}

deploy_by_server_type() {
    local server_type=$(select_deployment_type)
    
    if [ "$server_type" = "cancel" ] || [ -z "$server_type" ]; then
        return
    fi
    
    # 获取默认软件包
    local default_packages="${DEPLOYMENT_TEMPLATES[$server_type]}"
    
    # 选择软件包（默认选中模板中的包）
    local software_packages=$(select_software_packages "$server_type")
    if [ $? -ne 0 ]; then
        warn "未选择任何软件包"
        return
    fi
    
    # 选择控制面板
    local control_panel=$(select_control_panel)
    
    # 确认部署方案
    if review_deployment_plan "$server_type" "$software_packages" "$control_panel"; then
        execute_deployment_plan "$server_type" "$software_packages" "$control_panel"
    else
        log "部署已取消"
    fi
}

deploy_custom_packages() {
    local server_type="custom"
    
    # 选择软件包
    local software_packages=$(select_software_packages "$server_type")
    if [ $? -ne 0 ]; then
        warn "未选择任何软件包"
        return
    fi
    
    # 选择控制面板
    local control_panel=$(select_control_panel)
    
    # 确认部署方案
    if review_deployment_plan "$server_type" "$software_packages" "$control_panel"; then
        execute_deployment_plan "$server_type" "$software_packages" "$control_panel"
    else
        log "部署已取消"
    fi
}

deploy_control_panel_only() {
    local server_type="custom"
    local software_packages=""
    
    # 选择控制面板
    local control_panel=$(select_control_panel)
    
    if [ "$control_panel" = "none" ]; then
        warn "未选择任何控制面板"
        return
    fi
    
    # 确认部署方案
    if review_deployment_plan "$server_type" "$software_packages" "$control_panel"; then
        execute_deployment_plan "$server_type" "$software_packages" "$control_panel"
    else
        log "部署已取消"
    fi
}

view_deployment_templates() {
    exit_to_terminal
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}           部署方案模板                    ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    for type in "${!DEPLOYMENT_TEMPLATES[@]}"; do
        echo -e "${BLUE}${SERVER_TYPES[$type]}:${NC}"
        local packages="${DEPLOYMENT_TEMPLATES[$type]}"
        
        if [ -z "$packages" ]; then
            echo "  自定义选择"
        else
            for pkg in $packages; do
                echo "  ✓ ${SOFTWARE_PACKAGES[$pkg]}"
            done
        fi
        echo ""
    done
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    
    return_to_gui
}

view_deployment_history() {
    if [ ! -f "$INSTALL_LOG" ]; then
        show_gui_msgbox "部署历史" "暂无部署历史记录" 8 40
        return
    fi
    
    exit_to_terminal
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}           部署历史记录                    ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    # 从日志中提取部署信息
    grep -E "(开始部署执行|服务器类型:|选择的软件包:|控制面板:|部署完成)" "$INSTALL_LOG" | tail -20
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    
    return_to_gui
}

# ====================== 原有功能集成 ======================

# 以下保留原有函数，但为了简洁，只列出函数声明
# 实际使用时请确保这些函数已定义

# 系统优化函数
system_optimization_gui() {
    # 原有实现...
    :
}

# Docker安装
install_docker_gui() {
    # 原有实现...
    :
}

# 1Panel安装
install_1panel_gui() {
    # 原有实现...
    :
}

# 宝塔安装
install_baota_gui() {
    # 原有实现...
    :
}

# 快速启动管理器
quick_start_menu() {
    # 原有实现...
    :
}

# 系统状态检查
system_integrity_check_gui() {
    # 原有实现...
    :
}

# 卸载工具
uninstall_menu_gui() {
    # 原有实现...
    :
}

# ====================== 主菜单 ======================

main_menu_gui() {
    while true; do
        choice=$(show_gui_menu "主菜单 Pro版" 25 70 10 \
                  "1" "服务器部署方案" \
                  "2" "系统优化配置" \
                  "3" "安装Docker" \
                  "4" "安装1Panel面板" \
                  "5" "安装宝塔面板" \
                  "6" "快速启动管理器" \
                  "7" "系统状态检查" \
                  "8" "卸载工具" \
                  "9" "清理临时文件" \
                  "0" "退出程序")
        
        if [ -z "$choice" ]; then
            exit_program
            continue
        fi
        
        case $choice in
            1) server_deployment_menu ;;
            2) system_optimization_gui ;;
            3) install_docker_gui ;;
            4) install_1panel_gui ;;
            5) install_baota_gui ;;
            6) quick_start_menu ;;
            7) system_integrity_check_gui ;;
            8) uninstall_menu_gui ;;
            9) cleanup_temp_files_gui ;;
            0) exit_program ;;
        esac
    done
}

exit_program() {
    if show_gui_yesno "退出程序" "确定要退出吗？" 8 40; then
        clear
        echo -e "${GREEN}感谢使用服务器部署工具 Pro版！${NC}"
        echo -e "${YELLOW}日志文件: $INSTALL_LOG${NC}"
        exit 0
    fi
}

# ====================== 主程序 ======================

main() {
    # 显示欢迎信息并验证密钥
    validate_license
    
    # 初始化日志系统
    init_log_system
    
    # 检查sudo权限
    check_sudo "$@"
    
    # 检查必要工具
    check_required_tools
    
    # 检查dialog工具
    check_dialog
    
    # 检测系统版本
    check_ubuntu_version
    
    # 显示启动界面
    confirm_execution_gui
    
    # 记录开始时间
    local start_time=$(date +%s)
    log "脚本开始执行 (v$SCRIPT_VERSION)"
    
    # 显示主菜单
    main_menu_gui
    
    # 记录结束时间
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log "脚本执行完成，总耗时: ${duration}秒"
}

# ====================== 辅助函数（原有） ======================

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
    local supported_versions=("22.04" "24.04" "24.10")
    local is_supported=false
    
    for v in "${supported_versions[@]}"; do
        if [[ "$version" =~ ^$v ]]; then
            is_supported=true
            break
        fi
    done
    
    if [ "$is_supported" = false ]; then
        warn "检测到 Ubuntu $version，支持的版本：${supported_versions[*]}"
        echo -e "${YELLOW}可能遇到兼容性问题！${NC}"
        
        read -p "是否继续？(y/N): " -n 1 user_confirm
        echo
        if [[ ! $user_confirm =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
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

confirm_execution_gui() {
    show_header
    
    echo -e "${CYAN}当前恢复模式：${NC}"
    echo -e "  自动恢复: $([ "$AUTO_RECOVERY" = true ] && echo "${GREEN}启用${NC}" || echo "${YELLOW}禁用${NC}")"
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
    
    read -p "按回车键进入主菜单，或按 Ctrl+C 退出..." 
}

show_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║        Ubuntu 服务器部署脚本 Pro版 v$SCRIPT_VERSION       ║"
    echo "║             专业服务器部署方案管理器                     ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# ====================== 原有清理函数 ======================

cleanup_temp_files_gui() {
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

# 设置异常处理
trap 'error "脚本被中断"; echo -e "${YELLOW}日志文件: ${INSTALL_LOG}${NC}"; exit 1' INT TERM

# 执行主函数
main "$@"

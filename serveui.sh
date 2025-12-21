#!/bin/bash

# =============================================
# Ubuntu 服务器部署脚本 - Dialog GUI版 v10.0
# 修复版 - 一键优化，安装时退出GUI
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
SCRIPT_VERSION="10.0"
SCRIPT_NAME="yx-deploy-gui"
BACKUP_DIR="/backup/${SCRIPT_NAME}"
LOG_DIR="/var/log/${SCRIPT_NAME}"
INSTALL_LOG="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
DIALOG_TITLE="Ubuntu服务器部署工具 v$SCRIPT_VERSION"

# ====================== 初始化 ======================

init_log_system() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    touch "$INSTALL_LOG" 2>/dev/null
    echo "=== 脚本开始执行 $(date) ===" >> "$INSTALL_LOG"
}

log() {
    local msg="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[${timestamp}] ✓ $msg${NC}" | tee -a "$INSTALL_LOG"
}

warn() {
    local msg="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${YELLOW}[${timestamp}] ⚠  $msg${NC}" | tee -a "$INSTALL_LOG"
}

error() {
    local msg="$1"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo -e "${RED}[${timestamp}] ✗ $msg${NC}" | tee -a "$INSTALL_LOG"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        clear
        echo -e "${RED}错误：请使用root权限运行此脚本${NC}"
        echo -e "${YELLOW}使用: sudo bash $0${NC}"
        exit 1
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

# ====================== GUI控制函数 ======================

show_gui() {
    local func="$1"
    local title="$2"
    shift 2
    dialog --backtitle "$DIALOG_TITLE" --title "$title" "$@"
}

exit_to_terminal() {
    clear
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}正在退出GUI界面，进入终端模式${NC}"
    echo -e "${YELLOW}安装完成后会自动返回GUI界面${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

return_to_gui() {
    echo ""
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}安装完成！按回车键返回GUI界面...${NC}"
    echo -e "${CYAN}========================================${NC}"
    read -p ""
}

# ====================== 主菜单 ======================

show_main_menu() {
    while true; do
        choice=$(show_gui "show_main_menu" "主菜单" \
                  --menu "\n请选择要执行的操作：" \
                  20 60 12 \
                  "1" "系统一键优化" \
                  "2" "安装Docker容器" \
                  "3" "安装1Panel面板" \
                  "4" "安装宝塔面板" \
                  "5" "安装Nginx服务器" \
                  "6" "安装Apache服务器" \
                  "7" "安装MySQL数据库" \
                  "8" "安装Redis缓存" \
                  "9" "服务管理" \
                  "10" "系统信息" \
                  "11" "查看日志" \
                  "0" "退出程序" \
                  3>&1 1>&2 2>&3)
        
        local exit_status=$?
        
        if [ $exit_status -ne 0 ]; then
            exit_program
            continue
        fi
        
        case $choice in
            1) system_optimization_gui ;;
            2) install_docker_gui ;;
            3) install_1panel_gui ;;
            4) install_baota_gui ;;
            5) install_nginx_gui ;;
            6) install_apache_gui ;;
            7) install_mysql_gui ;;
            8) install_redis_gui ;;
            9) service_management_menu ;;
            10) system_info_gui ;;
            11) show_log_gui ;;
            0) exit_program ;;
        esac
    done
}

# ====================== 系统一键优化 ======================

system_optimization_gui() {
    if ! show_gui "system_optimization" "系统一键优化" \
         --yesno "将执行以下一键优化操作：\n\n1. 更新软件包和升级系统\n2. 安装常用运维工具\n3. 配置阿里云镜像源\n4. 设置上海时区\n5. 优化内核参数\n6. 配置SSH安全\n7. 配置防火墙\n\n是否继续？" \
         15 60; then
        return
    fi
    
    # 退出GUI，在终端显示进度
    exit_to_terminal
    
    log "开始系统一键优化..."
    
    # 1. 更新系统
    echo -e "${BLUE}[1/7] 更新系统软件包...${NC}"
    apt-get update -y
    apt-get upgrade -y
    apt-get autoremove -y
    apt-get autoclean -y
    
    # 2. 安装常用工具
    echo -e "${BLUE}[2/7] 安装常用运维工具...${NC}"
    apt-get install -y curl wget vim git htop net-tools \
                       screen tmux zip unzip tree \
                       dnsutils telnet traceroute \
                       build-essential python3 python3-pip
    
    # 3. 配置阿里云镜像源
    echo -e "${BLUE}[3/7] 配置阿里云镜像源...${NC}"
    cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d)
    local ubuntu_version=$(lsb_release -cs 2>/dev/null || echo "jammy")
    local mirror_url="https://mirrors.aliyun.com/ubuntu/"
    
    cat > /etc/apt/sources.list << EOF
deb ${mirror_url} ${ubuntu_version} main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-security main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-updates main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-proposed main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-backports main restricted universe multiverse
EOF
    
    apt-get update -y
    
    # 4. 设置时区
    echo -e "${BLUE}[4/7] 设置时区和时间同步...${NC}"
    timedatectl set-timezone Asia/Shanghai
    systemctl enable chronyd
    systemctl restart chronyd
    
    # 5. 优化内核参数
    echo -e "${BLUE}[5/7] 优化内核参数...${NC}"
    cat >> /etc/sysctl.conf << 'EOF'

# 网络优化
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.default_qdisc = fq

# 系统优化
vm.swappiness = 10
vm.vfs_cache_pressure = 50
EOF
    sysctl -p
    
    # 6. SSH安全配置
    echo -e "${BLUE}[6/7] 配置SSH安全...${NC}"
    if [ -f "/etc/ssh/sshd_config" ]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
        sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
        systemctl restart sshd
    fi
    
    # 7. 防火墙配置
    echo -e "${BLUE}[7/7] 配置防火墙...${NC}"
    ufw --force enable >/dev/null 2>&1
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    ufw allow ssh >/dev/null 2>&1
    
    echo ""
    echo -e "${GREEN}✅ 系统一键优化完成！${NC}"
    echo -e "${YELLOW}建议重启服务器使所有优化生效${NC}"
    
    return_to_gui
}

# ====================== Docker安装 ======================

install_docker_gui() {
    # 检查是否已安装
    if command -v docker &>/dev/null; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "未知")
        if ! show_gui "docker_check" "Docker已安装" \
             --yesno "Docker已经安装：\n版本: $docker_version\n\n是否重新安装？" \
             10 60; then
            return
        fi
    fi
    
    if ! show_gui "docker_install" "安装Docker" \
         --yesno "将安装Docker容器引擎\n\n安装后会自动配置镜像加速器\n\n是否继续？" \
         10 60; then
        return
    fi
    
    exit_to_terminal
    
    log "开始安装Docker..."
    
    echo -e "${BLUE}安装Docker容器引擎...${NC}"
    echo ""
    
    # 卸载旧版本
    echo "1. 卸载旧版本..."
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
    
    # 安装依赖
    echo "2. 安装依赖包..."
    apt-get update -y
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # 添加Docker官方GPG密钥
    echo "3. 添加Docker官方GPG密钥..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # 添加Docker仓库
    echo "4. 添加Docker仓库..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # 安装Docker
    echo "5. 安装Docker..."
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # 启动Docker
    echo "6. 启动Docker服务..."
    systemctl start docker
    systemctl enable docker
    
    # 配置镜像加速器
    echo "7. 配置镜像加速器..."
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
EOF
    systemctl restart docker
    
    # 测试安装
    echo "8. 测试Docker安装..."
    if docker run --rm hello-world &>/dev/null; then
        echo -e "   ${GREEN}✅ Docker安装成功！${NC}"
        log "Docker安装成功"
    else
        echo -e "   ${YELLOW}⚠ Docker安装完成，但测试失败${NC}"
        warn "Docker测试失败"
    fi
    
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                 Docker安装完成！               ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    
    return_to_gui
}

# ====================== 面板安装 ======================

install_1panel_gui() {
    if systemctl list-unit-files | grep -q 1panel 2>/dev/null || [ -f "/usr/local/bin/1panel" ]; then
        if ! show_gui "1panel_check" "1Panel已安装" \
             --yesno "1Panel面板已经安装！\n\n是否重新安装？" \
             10 60; then
            return
        fi
    fi
    
    if ! show_gui "1panel_install" "安装1Panel" \
         --yesno "将安装1Panel服务器面板\n\n默认端口: 9090\n用户名: admin\n\n安装过程中需要设置密码\n\n是否继续？" \
         12 60; then
        return
    fi
    
    exit_to_terminal
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}开始安装1Panel面板${NC}"
    echo -e "${YELLOW}安装说明：${NC}"
    echo "1. 当提示 'Please enter y or n:' 时，请输入 y"
    echo "2. 设置面板密码（输入两次）"
    echo "3. 等待安装完成"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    log "开始安装1Panel..."
    
    # 下载安装脚本
    curl -fsSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o /tmp/quick_start.sh
    chmod +x /tmp/quick_start.sh
    
    # 运行安装脚本
    echo -e "${BLUE}正在安装1Panel，请按照提示操作...${NC}"
    echo ""
    /tmp/quick_start.sh
    
    # 清理临时文件
    rm -f /tmp/quick_start.sh
    
    # 检查安装结果
    sleep 3
    if systemctl list-unit-files | grep -q 1panel 2>/dev/null || [ -f "/usr/local/bin/1panel" ]; then
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo -e "${GREEN}               1Panel安装完成！               ${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}访问地址: https://${ip_address}:9090${NC}"
        echo -e "${YELLOW}用户名: admin${NC}"
        echo -e "${YELLOW}密码: 您刚才设置的密码${NC}"
        echo ""
        echo -e "${RED}⚠ 重要：请立即登录并修改默认密码！${NC}"
        
        log "1Panel安装完成"
    else
        echo ""
        error "1Panel安装失败！"
    fi
    
    return_to_gui
}

install_baota_gui() {
    if [ -f "/etc/init.d/bt" ] || [ -f "/www/server/panel/BT-Panel" ]; then
        if ! show_gui "baota_check" "宝塔已安装" \
             --yesno "宝塔面板已经安装！\n\n是否重新安装？" \
             10 60; then
            return
        fi
    fi
    
    if ! show_gui "baota_install" "安装宝塔" \
         --yesno "将安装宝塔Linux面板\n\n默认端口: 8888\n\n安装过程需要5-10分钟\n\n是否继续？" \
         10 60; then
        return
    fi
    
    exit_to_terminal
    
    echo -e "${CYAN}========================================${NC}"
    echo -e "${GREEN}开始安装宝塔面板${NC}"
    echo -e "${YELLOW}安装说明：${NC}"
    echo "1. 当提示确认时，请输入 y"
    echo "2. 等待安装完成（需要5-10分钟）"
    echo "3. 保存显示的登录信息"
    echo -e "${CYAN}========================================${NC}"
    echo ""
    
    log "开始安装宝塔面板..."
    
    # 下载安装脚本
    if command -v curl &>/dev/null; then
        curl -fsSL https://download.bt.cn/install/install_panel.sh -o /tmp/install_panel.sh
    else
        wget -q https://download.bt.cn/install/install_panel.sh -O /tmp/install_panel.sh
    fi
    
    chmod +x /tmp/install_panel.sh
    
    # 运行安装脚本
    echo -e "${BLUE}正在安装宝塔面板，请稍候...${NC}"
    echo ""
    /tmp/install_panel.sh
    
    # 清理临时文件
    rm -f /tmp/install_panel.sh
    
    # 检查安装结果
    sleep 3
    if [ -f "/etc/init.d/bt" ] || [ -f "/www/server/panel/BT-Panel" ]; then
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null)
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo -e "${GREEN}              宝塔面板安装完成！              ${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}访问地址: http://${ip_address}:8888${NC}"
        echo -e "${YELLOW}请查看屏幕上显示的登录信息${NC}"
        echo -e "${YELLOW}或运行 'bt default' 获取登录信息${NC}"
        
        log "宝塔面板安装完成"
    else
        echo ""
        error "宝塔面板安装失败！"
    fi
    
    return_to_gui
}

# ====================== Web服务器安装 ======================

install_nginx_gui() {
    if command -v nginx &>/dev/null; then
        if ! show_gui "nginx_check" "Nginx已安装" \
             --yesno "Nginx已经安装！\n\n是否重新安装？" \
             10 60; then
            return
        fi
    fi
    
    if ! show_gui "nginx_install" "安装Nginx" \
         --yesno "将安装Nginx Web服务器\n\n是否继续？" \
         8 60; then
        return
    fi
    
    exit_to_terminal
    
    log "开始安装Nginx..."
    
    echo -e "${BLUE}安装Nginx Web服务器...${NC}"
    echo ""
    
    apt-get update -y
    apt-get install -y nginx
    
    systemctl enable nginx
    systemctl start nginx
    
    echo ""
    echo -e "${GREEN}✅ Nginx安装成功！${NC}"
    echo ""
    echo -e "${YELLOW}默认网站目录: /var/www/html${NC}"
    echo -e "${YELLOW}配置文件目录: /etc/nginx${NC}"
    echo -e "${YELLOW}访问地址: http://服务器IP${NC}"
    
    return_to_gui
}

install_apache_gui() {
    if command -v apache2 &>/dev/null; then
        if ! show_gui "apache_check" "Apache已安装" \
             --yesno "Apache已经安装！\n\n是否重新安装？" \
             10 60; then
            return
        fi
    fi
    
    if ! show_gui "apache_install" "安装Apache" \
         --yesno "将安装Apache2 Web服务器\n\n是否继续？" \
         8 60; then
        return
    fi
    
    exit_to_terminal
    
    log "开始安装Apache..."
    
    echo -e "${BLUE}安装Apache2 Web服务器...${NC}"
    echo ""
    
    apt-get update -y
    apt-get install -y apache2
    
    systemctl enable apache2
    systemctl start apache2
    
    echo ""
    echo -e "${GREEN}✅ Apache2安装成功！${NC}"
    echo ""
    echo -e "${YELLOW}默认网站目录: /var/www/html${NC}"
    echo -e "${YELLOW}配置文件目录: /etc/apache2${NC}"
    echo -e "${YELLOW}访问地址: http://服务器IP${NC}"
    
    return_to_gui
}

# ====================== 数据库安装 ======================

install_mysql_gui() {
    if command -v mysql &>/dev/null; then
        if ! show_gui "mysql_check" "MySQL已安装" \
             --yesno "MySQL已经安装！\n\n是否重新安装？" \
             10 60; then
            return
        fi
    fi
    
    if ! show_gui "mysql_install" "安装MySQL" \
         --yesno "将安装MySQL数据库服务器\n\n是否继续？" \
         8 60; then
        return
    fi
    
    exit_to_terminal
    
    log "开始安装MySQL..."
    
    echo -e "${BLUE}安装MySQL数据库...${NC}"
    echo ""
    
    apt-get update -y
    apt-get install -y mysql-server
    
    systemctl enable mysql
    systemctl start mysql
    
    echo ""
    echo -e "${GREEN}✅ MySQL安装成功！${NC}"
    echo ""
    echo -e "${YELLOW}默认端口: 3306${NC}"
    echo -e "${YELLOW}配置文件: /etc/mysql/mysql.conf.d/mysqld.cnf${NC}"
    echo -e "${YELLOW}数据目录: /var/lib/mysql${NC}"
    echo ""
    echo -e "${YELLOW}是否运行MySQL安全配置脚本？(y/N): ${NC}"
    read -n1 answer
    echo ""
    if [[ $answer =~ ^[Yy]$ ]]; then
        mysql_secure_installation
    fi
    
    return_to_gui
}

install_redis_gui() {
    if command -v redis-server &>/dev/null; then
        if ! show_gui "redis_check" "Redis已安装" \
             --yesno "Redis已经安装！\n\n是否重新安装？" \
             10 60; then
            return
        fi
    fi
    
    if ! show_gui "redis_install" "安装Redis" \
         --yesno "将安装Redis内存数据库\n\n是否继续？" \
         8 60; then
        return
    fi
    
    exit_to_terminal
    
    log "开始安装Redis..."
    
    echo -e "${BLUE}安装Redis缓存数据库...${NC}"
    echo ""
    
    apt-get update -y
    apt-get install -y redis-server
    
    systemctl enable redis-server
    systemctl start redis-server
    
    echo ""
    echo -e "${GREEN}✅ Redis安装成功！${NC}"
    echo ""
    echo -e "${YELLOW}默认端口: 6379${NC}"
    echo -e "${YELLOW}配置文件: /etc/redis/redis.conf${NC}"
    echo -e "${YELLOW}数据目录: /var/lib/redis${NC}"
    
    return_to_gui
}

# ====================== 其他功能 ======================

service_management_menu() {
    while true; do
        choice=$(show_gui "service_menu" "服务管理" \
                  --menu "请选择操作：" \
                  15 60 7 \
                  "1" "查看服务状态" \
                  "2" "启动服务" \
                  "3" "停止服务" \
                  "4" "重启服务" \
                  "5" "设置开机自启" \
                  "6" "返回主菜单" \
                  3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        case $choice in
            1) show_service_status ;;
            2) start_service_gui ;;
            3) stop_service_gui ;;
            4) restart_service_gui ;;
            5) enable_service_gui ;;
            6) return ;;
        esac
    done
}

show_service_status() {
    exit_to_terminal
    
    echo -e "${CYAN}服务状态检查${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    local services=(
        "docker" "Docker"
        "nginx" "Nginx"
        "apache2" "Apache"
        "mysql" "MySQL"
        "redis-server" "Redis"
        "ssh" "SSH"
    )
    
    for ((i=0; i<${#services[@]}; i+=2)); do
        local service="${services[i]}"
        local name="${services[i+1]}"
        
        if systemctl list-unit-files | grep -q "${service}.service" 2>/dev/null; then
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                echo -e "  ${GREEN}✓ $name: 运行中${NC}"
            else
                echo -e "  ${YELLOW}⚠ $name: 已停止${NC}"
            fi
        else
            echo -e "  ${BLUE}○ $name: 未安装${NC}"
        fi
    done
    
    echo ""
    echo -e "${BLUE}端口监听状态：${NC}"
    local ports=(22 80 3306 6379 9090 8888)
    for port in "${ports[@]}"; do
        if ss -tulpn 2>/dev/null | grep -q ":$port "; then
            echo -e "  ${GREEN}✓ 端口 $port: 已监听${NC}"
        else
            echo -e "  ${YELLOW}⚠ 端口 $port: 未监听${NC}"
        fi
    done
    
    return_to_gui
}

start_service_gui() {
    service=$(show_gui "start_service" "启动服务" \
              --inputbox "请输入要启动的服务名称：" \
              8 60 "")
    
    if [ -z "$service" ]; then
        return
    fi
    
    exit_to_terminal
    echo -e "${BLUE}启动 $service 服务...${NC}"
    systemctl start "$service" 2>/dev/null
    
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo -e "${GREEN}✅ $service 启动成功${NC}"
    else
        error "$service 启动失败"
    fi
    
    return_to_gui
}

system_info_gui() {
    local info_text=""
    
    info_text+="=== 系统信息 ===\n\n"
    info_text+="操作系统: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)\n"
    info_text+="内核版本: $(uname -r)\n"
    info_text+="系统架构: $(uname -m)\n\n"
    
    info_text+="=== 硬件资源 ===\n\n"
    info_text+="CPU核心数: $(nproc)\n"
    info_text+="内存总量: $(free -h | awk '/^Mem:/ {print $2}')\n"
    info_text+="磁盘空间: $(df -h / | awk 'NR==2 {print $2}')\n\n"
    
    info_text+="=== 网络信息 ===\n\n"
    info_text+="主机名: $(hostname)\n"
    info_text+="IP地址: $(hostname -I 2>/dev/null | awk '{print $1}')\n"
    info_text+="运行时间: $(uptime -p)\n"
    
    show_gui "system_info" "系统信息" \
             --msgbox "$info_text" \
             18 60
}

show_log_gui() {
    if [ -f "$INSTALL_LOG" ]; then
        show_gui "view_log" "安装日志" \
                 --textbox "$INSTALL_LOG" \
                 25 80
    else
        show_gui "log_error" "错误" \
                 --msgbox "日志文件不存在" \
                 8 40
    fi
}

exit_program() {
    if show_gui "exit_confirm" "退出程序" \
         --yesno "确定要退出吗？" \
         8 40; then
        clear
        echo -e "${GREEN}感谢使用服务器部署工具！${NC}"
        echo -e "${YELLOW}日志文件: $INSTALL_LOG${NC}"
        exit 0
    fi
}

# ====================== 主程序 ======================

main() {
    # 检查root权限
    check_root
    
    # 初始化日志系统
    init_log_system
    log "脚本开始执行 v$SCRIPT_VERSION"
    
    # 检查并安装dialog
    check_dialog
    
    # 显示主菜单
    show_main_menu
}

# 设置中断处理
trap 'echo -e "\n${RED}脚本被中断${NC}"; exit 1' INT TERM

# 启动程序
main "$@"

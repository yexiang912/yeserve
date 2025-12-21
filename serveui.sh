#!/bin/bash

# =============================================
# Ubuntu 服务器部署脚本 - Dialog GUI版 v9.0
# 使用dialog工具创建完整GUI界面
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
SCRIPT_VERSION="9.0"
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

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "请使用root权限运行此脚本"
        echo "使用: sudo bash $0"
        exit 1
    fi
}

check_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then
        echo "正在安装dialog工具..."
        apt-get update -y >/dev/null 2>&1
        apt-get install -y dialog >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            error "无法安装dialog工具"
            exit 1
        fi
        log "dialog工具安装成功"
    fi
}

# ====================== Dialog GUI函数 ======================

show_welcome() {
    dialog --title "$DIALOG_TITLE" \
           --msgbox "\n欢迎使用Ubuntu服务器部署工具\n\n本工具提供完整的服务器部署和管理功能\n\n包括：\n• 系统优化配置\n• Docker容器安装\n• Web面板安装\n• Web服务器安装\n• 数据库安装\n• 服务管理\n• 系统监控\n\n日志文件: $INSTALL_LOG" \
           15 70
    
    if [ $? -ne 0 ]; then
        exit_program
    fi
}

show_main_menu() {
    while true; do
        choice=$(dialog --title "$DIALOG_TITLE" \
                        --menu "请选择要执行的操作：" \
                        20 60 13 \
                        "1" "系统优化配置" \
                        "2" "安装Docker容器" \
                        "3" "安装1Panel面板" \
                        "4" "安装宝塔面板" \
                        "5" "安装Web服务器" \
                        "6" "安装数据库" \
                        "7" "服务管理" \
                        "8" "系统监控" \
                        "9" "卸载工具" \
                        "10" "系统信息" \
                        "11" "查看日志" \
                        "0" "退出程序" \
                        3>&1 1>&2 2>&3)
        
        exit_status=$?
        
        if [ $exit_status -ne 0 ]; then
            exit_program
            continue
        fi
        
        case $choice in
            1) system_optimization_menu ;;
            2) install_docker_gui ;;
            3) install_1panel_gui ;;
            4) install_baota_gui ;;
            5) install_web_menu ;;
            6) install_database_menu ;;
            7) service_management_menu ;;
            8) system_monitor_menu ;;
            9) uninstall_menu ;;
            10) system_info_gui ;;
            11) show_log_gui ;;
            0) exit_program ;;
        esac
    done
}

show_msgbox() {
    local title="$1"
    local message="$2"
    local height="${3:-10}"
    local width="${4:-60}"
    
    dialog --title "$title" \
           --msgbox "$message" \
           $height $width
}

show_yesno() {
    local title="$1"
    local message="$2"
    
    dialog --title "$title" \
           --yesno "$message" \
           8 60
    
    return $?
}

show_input() {
    local title="$1"
    local prompt="$2"
    local default="$3"
    
    dialog --title "$title" \
           --inputbox "$prompt" \
           8 60 "$default" \
           3>&1 1>&2 2>&3
}

show_progress() {
    local title="$1"
    local cmd="$2"
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 执行命令并将输出重定向到临时文件
    (eval "$cmd" 2>&1 | while IFS= read -r line; do
        echo "XXX"
        echo "$line"
        echo "XXX"
    done) | dialog --title "$title" --gauge "请稍候..." 10 70 0
    
    rm -f "$temp_file"
}

# ====================== 系统信息 ======================

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
    
    show_msgbox "系统信息" "$info_text" 20
}

# ====================== 系统优化菜单 ======================

system_optimization_menu() {
    while true; do
        choice=$(dialog --title "系统优化配置" \
                        --menu "请选择优化项目：" \
                        15 60 6 \
                        "1" "基础系统优化" \
                        "2" "切换软件源" \
                        "3" "安装常用工具" \
                        "4" "安全加固配置" \
                        "5" "性能优化配置" \
                        "6" "返回主菜单" \
                        3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        case $choice in
            1) basic_optimization_gui ;;
            2) change_mirror_source_gui ;;
            3) install_tools_gui ;;
            4) security_hardening_gui ;;
            5) performance_tuning_gui ;;
            6) return ;;
        esac
    done
}

basic_optimization_gui() {
    if ! show_yesno "基础系统优化" "将执行以下操作：\n\n1. 更新软件包列表\n2. 升级现有软件包\n3. 清理无用包\n4. 设置时区（上海）\n5. 配置时间同步\n\n是否继续？"; then
        return
    fi
    
    # 执行优化
    (
        echo "20"
        echo "# 更新软件包列表..."
        apt-get update -y
        echo "40"
        echo "# 升级软件包..."
        apt-get upgrade -y
        echo "60"
        echo "# 清理无用包..."
        apt-get autoremove -y
        apt-get autoclean -y
        echo "80"
        echo "# 设置时区..."
        timedatectl set-timezone Asia/Shanghai
        echo "90"
        echo "# 配置时间同步..."
        systemctl enable chronyd
        systemctl restart chronyd
        echo "100"
        echo "# 基础优化完成！"
    ) | dialog --title "基础系统优化" --gauge "正在执行优化..." 10 70 0
    
    log "基础系统优化完成"
    show_msgbox "完成" "基础系统优化已完成！"
}

change_mirror_source_gui() {
    local current_source=$(grep -E "^deb " /etc/apt/sources.list | head -1 | grep -o "http[s]*://[^ ]*" || echo "官方源")
    
    show_msgbox "当前软件源" "当前软件源: $current_source\n\n是否切换到国内镜像源？"
    
    choice=$(dialog --title "选择镜像源" \
                    --radiolist "请选择要使用的镜像源：" \
                    12 50 5 \
                    "1" "阿里云镜像源" on \
                    "2" "清华大学镜像源" off \
                    "3" "中科大镜像源" off \
                    "4" "网易163镜像源" off \
                    "5" "华为云镜像源" off \
                    3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ] || [ -z "$choice" ]; then
        return
    fi
    
    local mirror_url=""
    case $choice in
        1) mirror_url="https://mirrors.aliyun.com/ubuntu/" ;;
        2) mirror_url="https://mirrors.tuna.tsinghua.edu.cn/ubuntu/" ;;
        3) mirror_url="https://mirrors.ustc.edu.cn/ubuntu/" ;;
        4) mirror_url="http://mirrors.163.com/ubuntu/" ;;
        5) mirror_url="https://repo.huaweicloud.com/ubuntu/" ;;
    esac
    
    # 备份原有源
    cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d)
    
    # 获取系统版本
    local ubuntu_version=$(lsb_release -cs)
    
    # 生成新的sources.list
    cat > /etc/apt/sources.list << EOF
deb ${mirror_url} ${ubuntu_version} main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-security main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-updates main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-proposed main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-backports main restricted universe multiverse
EOF
    
    # 更新软件源
    (
        echo "30"
        echo "# 更新软件包列表..."
        apt-get update -y
        echo "100"
        echo "# 软件源切换完成！"
    ) | dialog --title "切换软件源" --gauge "正在更新软件包列表..." 8 60 0
    
    show_msgbox "完成" "软件源已切换到:\n$mirror_url\n\n请运行 apt-get update 测试速度"
    log "切换到镜像源: $mirror_url"
}

install_tools_gui() {
    # 创建临时文件来存储选择
    local temp_file=$(mktemp)
    
    dialog --title "选择安装工具" \
           --checklist "请选择要安装的工具：" \
           20 60 12 \
           "curl" "cURL工具" on \
           "wget" "下载工具" on \
           "vim" "文本编辑器" on \
           "git" "版本控制工具" on \
           "htop" "进程监控工具" on \
           "iftop" "网络监控工具" off \
           "iotop" "磁盘IO监控工具" off \
           "build-essential" "开发工具包" off \
           "python3" "Python 3" off \
           "python3-pip" "Python包管理器" off \
           "net-tools" "网络工具" on \
           "dnsutils" "DNS工具" on \
           "telnet" "远程登录工具" off \
           "traceroute" "路由跟踪工具" off \
           "zip" "压缩工具" on \
           "unzip" "解压工具" on \
           2> "$temp_file"
    
    if [ $? -ne 0 ]; then
        rm -f "$temp_file"
        return
    fi
    
    local selected_tools=$(cat "$temp_file" | tr '\n' ' ')
    rm -f "$temp_file"
    
    if [ -z "$selected_tools" ]; then
        show_msgbox "提示" "未选择任何工具"
        return
    fi
    
    if ! show_yesno "确认安装" "将安装以下工具：\n\n$selected_tools\n\n是否继续？"; then
        return
    fi
    
    (
        echo "10"
        echo "# 更新软件包列表..."
        apt-get update -y
        echo "50"
        echo "# 安装选择的工具..."
        apt-get install -y $selected_tools
        echo "100"
        echo "# 工具安装完成！"
    ) | dialog --title "安装工具" --gauge "正在安装工具..." 8 60 0
    
    show_msgbox "完成" "工具安装完成！"
    log "安装工具: $selected_tools"
}

security_hardening_gui() {
    if ! show_yesno "安全加固配置" "将进行以下安全加固：\n\n1. SSH安全配置\n2. 防火墙配置\n3. 安装Fail2ban\n\n是否继续？"; then
        return
    fi
    
    # SSH安全配置
    if show_yesno "SSH安全配置" "是否配置SSH安全设置？\n\n包括：\n• 禁止root登录\n• 修改默认端口\n• 其他安全选项"; then
        if [ -f "/etc/ssh/sshd_config" ]; then
            cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
            
            # 禁止root登录
            sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
            
            # 修改端口
            local ssh_port=$(show_input "SSH端口" "请输入新的SSH端口号（默认22）" "22")
            if [[ "$ssh_port" =~ ^[0-9]+$ ]] && [ "$ssh_port" -ge 1024 ] && [ "$ssh_port" -le 65535 ]; then
                sed -i "s/#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
            fi
            
            systemctl restart sshd
            show_msgbox "SSH配置" "SSH安全配置完成！\n\n新端口: $ssh_port\nRoot登录: 已禁用"
        fi
    fi
    
    # 防火墙配置
    if show_yesno "防火墙配置" "是否启用UFW防火墙？"; then
        ufw --force enable
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ssh
        show_msgbox "防火墙" "UFW防火墙已启用！\n\n默认策略：\n• 禁止所有入站连接\n• 允许所有出站连接\n• 允许SSH连接"
    fi
    
    # Fail2ban
    if show_yesno "Fail2ban" "是否安装Fail2ban防暴力破解？"; then
        apt-get install -y fail2ban
        systemctl enable fail2ban
        systemctl start fail2ban
        show_msgbox "Fail2ban" "Fail2ban安装完成并已启动！"
    fi
    
    log "安全加固配置完成"
    show_msgbox "完成" "安全加固配置完成！"
}

# ====================== Docker安装 ======================

install_docker_gui() {
    # 检查是否已安装
    if command -v docker &>/dev/null; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "未知版本")
        if ! show_yesno "Docker已安装" "Docker已经安装：\n版本: $docker_version\n\n是否重新安装？"; then
            return
        fi
    fi
    
    if ! show_yesno "安装Docker" "将安装Docker容器引擎\n\n安装后会自动配置镜像加速器\n\n是否继续？"; then
        return
    fi
    
    (
        echo "10"
        echo "# 卸载旧版本..."
        apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
        echo "20"
        echo "# 安装依赖..."
        apt-get update -y
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
        echo "40"
        echo "# 添加Docker GPG密钥..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "60"
        echo "# 添加Docker仓库..."
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        echo "80"
        echo "# 安装Docker..."
        apt-get update -y
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        echo "90"
        echo "# 启动Docker服务..."
        systemctl start docker
        systemctl enable docker
        echo "100"
        echo "# Docker安装完成！"
    ) | dialog --title "安装Docker" --gauge "正在安装Docker..." 10 70 0
    
    # 配置镜像加速器
    if show_yesno "镜像加速器" "是否配置Docker镜像加速器？"; then
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
    fi
    
    # 测试Docker
    if docker run --rm hello-world &>/dev/null; then
        show_msgbox "成功" "✅ Docker安装成功！\n\n版本: $(docker --version 2>/dev/null)\n\n可以使用docker命令管理容器"
    else
        show_msgbox "警告" "⚠ Docker安装完成，但测试失败\n\n请检查服务状态：systemctl status docker"
    fi
    
    log "Docker安装完成"
}

# ====================== 面板安装 ======================

install_1panel_gui() {
    if systemctl list-unit-files | grep -q 1panel || command -v 1pctl &>/dev/null; then
        if ! show_yesno "1Panel已安装" "1Panel面板已经安装！\n\n是否重新安装？"; then
            return
        fi
    fi
    
    if ! show_yesno "安装1Panel" "将安装1Panel服务器面板\n\n默认端口: 9090\n用户名: admin\n\n安装过程中需要设置密码\n\n是否继续？"; then
        return
    fi
    
    show_msgbox "安装提示" "安装步骤说明：\n\n1. 当提示 'Please enter y or n:' 时，请输入 y\n2. 设置面板密码（输入两次）\n3. 等待安装完成\n\n按确定开始安装"
    
    # 安装1Panel
    (
        echo "30"
        echo "# 下载安装脚本..."
        curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o /tmp/quick_start.sh
        echo "60"
        echo "# 运行安装脚本..."
        chmod +x /tmp/quick_start.sh
        echo "90"
        echo "# 安装中，请按照提示操作..."
        echo "100"
        echo "# 安装完成！"
    ) | dialog --title "安装1Panel" --gauge "正在安装1Panel..." 8 60 0
    
    # 在后台运行安装
    bash /tmp/quick_start.sh &
    
    # 等待并获取结果
    sleep 10
    
    if systemctl list-unit-files | grep -q 1panel; then
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        show_msgbox "成功" "✅ 1Panel安装成功！\n\n访问地址: https://${ip_address}:9090\n用户名: admin\n密码: 您刚才设置的密码\n\n请及时登录并修改密码"
        log "1Panel安装完成"
    else
        show_msgbox "错误" "❌ 1Panel安装失败！\n\n请检查网络连接或手动安装"
    fi
    
    rm -f /tmp/quick_start.sh
}

install_baota_gui() {
    if [ -f "/etc/init.d/bt" ]; then
        if ! show_yesno "宝塔已安装" "宝塔面板已经安装！\n\n是否重新安装？"; then
            return
        fi
    fi
    
    if ! show_yesno "安装宝塔" "将安装宝塔Linux面板\n\n默认端口: 8888\n\n安装过程需要5-10分钟\n\n是否继续？"; then
        return
    fi
    
    show_msgbox "安装提示" "安装步骤说明：\n\n1. 当提示确认时，请输入 y\n2. 等待安装完成\n3. 保存显示的登录信息\n\n按确定开始安装"
    
    # 安装宝塔
    (
        echo "30"
        echo "# 下载安装脚本..."
        if command -v curl &>/dev/null; then
            curl -sSO https://download.bt.cn/install/install_panel.sh
        else
            wget -q https://download.bt.cn/install/install_panel.sh
        fi
        echo "70"
        echo "# 运行安装脚本..."
        echo "100"
        echo "# 安装中，请稍候..."
    ) | dialog --title "安装宝塔" --gauge "正在安装宝塔面板..." 8 60 0
    
    # 在后台运行安装
    bash install_panel.sh &
    
    # 等待
    sleep 10
    
    if [ -f "/etc/init.d/bt" ]; then
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null)
        show_msgbox "成功" "✅ 宝塔面板安装完成！\n\n访问地址: http://${ip_address}:8888\n\n请查看屏幕输出或运行 'bt default' 获取登录信息"
        log "宝塔面板安装完成"
    else
        show_msgbox "错误" "❌ 宝塔面板安装失败！\n\n请检查网络连接或手动安装"
    fi
}

# ====================== Web服务器安装 ======================

install_web_menu() {
    while true; do
        choice=$(dialog --title "安装Web服务器" \
                        --menu "请选择要安装的Web服务器：" \
                        12 50 4 \
                        "1" "安装Nginx" \
                        "2" "安装Apache2" \
                        "3" "安装OpenLiteSpeed" \
                        "4" "返回" \
                        3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        case $choice in
            1) install_nginx_gui ;;
            2) install_apache_gui ;;
            3) install_openlitespeed_gui ;;
            4) return ;;
        esac
    done
}

install_nginx_gui() {
    if command -v nginx &>/dev/null; then
        if ! show_yesno "Nginx已安装" "Nginx已经安装！\n\n是否重新安装？"; then
            return
        fi
    fi
    
    if ! show_yesno "安装Nginx" "将安装Nginx Web服务器\n\n是否继续？"; then
        return
    fi
    
    (
        echo "30"
        echo "# 更新软件包列表..."
        apt-get update -y
        echo "70"
        echo "# 安装Nginx..."
        apt-get install -y nginx
        echo "90"
        echo "# 启动Nginx服务..."
        systemctl enable nginx
        systemctl start nginx
        echo "100"
        echo "# Nginx安装完成！"
    ) | dialog --title "安装Nginx" --gauge "正在安装Nginx..." 8 60 0
    
    show_msgbox "完成" "✅ Nginx安装成功！\n\n默认网站目录: /var/www/html\n配置文件目录: /etc/nginx\n访问地址: http://服务器IP"
    log "Nginx安装完成"
}

install_apache_gui() {
    if command -v apache2 &>/dev/null; then
        if ! show_yesno "Apache已安装" "Apache已经安装！\n\n是否重新安装？"; then
            return
        fi
    fi
    
    if ! show_yesno "安装Apache" "将安装Apache2 Web服务器\n\n是否继续？"; then
        return
    fi
    
    (
        echo "30"
        echo "# 更新软件包列表..."
        apt-get update -y
        echo "70"
        echo "# 安装Apache2..."
        apt-get install -y apache2
        echo "90"
        echo "# 启动Apache服务..."
        systemctl enable apache2
        systemctl start apache2
        echo "100"
        echo "# Apache安装完成！"
    ) | dialog --title "安装Apache" --gauge "正在安装Apache..." 8 60 0
    
    show_msgbox "完成" "✅ Apache2安装成功！\n\n默认网站目录: /var/www/html\n配置文件目录: /etc/apache2\n访问地址: http://服务器IP"
    log "Apache安装完成"
}

# ====================== 数据库安装 ======================

install_database_menu() {
    while true; do
        choice=$(dialog --title "安装数据库" \
                        --menu "请选择要安装的数据库：" \
                        15 50 7 \
                        "1" "安装MySQL" \
                        "2" "安装MariaDB" \
                        "3" "安装PostgreSQL" \
                        "4" "安装Redis" \
                        "5" "安装MongoDB" \
                        "6" "返回" \
                        3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        case $choice in
            1) install_mysql_gui ;;
            2) install_mariadb_gui ;;
            3) install_postgresql_gui ;;
            4) install_redis_gui ;;
            5) install_mongodb_gui ;;
            6) return ;;
        esac
    done
}

install_mysql_gui() {
    if command -v mysql &>/dev/null; then
        if ! show_yesno "MySQL已安装" "MySQL已经安装！\n\n是否重新安装？"; then
            return
        fi
    fi
    
    if ! show_yesno "安装MySQL" "将安装MySQL数据库服务器\n\n是否继续？"; then
        return
    fi
    
    (
        echo "30"
        echo "# 更新软件包列表..."
        apt-get update -y
        echo "70"
        echo "# 安装MySQL..."
        apt-get install -y mysql-server
        echo "90"
        echo "# 启动MySQL服务..."
        systemctl enable mysql
        systemctl start mysql
        echo "100"
        echo "# MySQL安装完成！"
    ) | dialog --title "安装MySQL" --gauge "正在安装MySQL..." 8 60 0
    
    show_msgbox "完成" "✅ MySQL安装成功！\n\n默认端口: 3306\n配置文件: /etc/mysql/mysql.conf.d/mysqld.cnf\n数据目录: /var/lib/mysql"
    log "MySQL安装完成"
    
    if show_yesno "安全配置" "是否运行MySQL安全配置脚本？"; then
        mysql_secure_installation
    fi
}

install_mariadb_gui() {
    if command -v mariadb &>/dev/null; then
        if ! show_yesno "MariaDB已安装" "MariaDB已经安装！\n\n是否重新安装？"; then
            return
        fi
    fi
    
    if ! show_yesno "安装MariaDB" "将安装MariaDB数据库服务器\n\n是否继续？"; then
        return
    fi
    
    (
        echo "30"
        echo "# 更新软件包列表..."
        apt-get update -y
        echo "70"
        echo "# 安装MariaDB..."
        apt-get install -y mariadb-server
        echo "90"
        echo "# 启动MariaDB服务..."
        systemctl enable mariadb
        systemctl start mariadb
        echo "100"
        echo "# MariaDB安装完成！"
    ) | dialog --title "安装MariaDB" --gauge "正在安装MariaDB..." 8 60 0
    
    show_msgbox "完成" "✅ MariaDB安装成功！\n\n默认端口: 3306\n配置文件: /etc/mysql/mariadb.conf.d/50-server.cnf\n数据目录: /var/lib/mysql"
    log "MariaDB安装完成"
    
    if show_yesno "安全配置" "是否运行MariaDB安全配置脚本？"; then
        mysql_secure_installation
    fi
}

install_redis_gui() {
    if command -v redis-server &>/dev/null; then
        if ! show_yesno "Redis已安装" "Redis已经安装！\n\n是否重新安装？"; then
            return
        fi
    fi
    
    if ! show_yesno "安装Redis" "将安装Redis内存数据库\n\n是否继续？"; then
        return
    fi
    
    (
        echo "30"
        echo "# 更新软件包列表..."
        apt-get update -y
        echo "70"
        echo "# 安装Redis..."
        apt-get install -y redis-server
        echo "90"
        echo "# 启动Redis服务..."
        systemctl enable redis-server
        systemctl start redis-server
        echo "100"
        echo "# Redis安装完成！"
    ) | dialog --title "安装Redis" --gauge "正在安装Redis..." 8 60 0
    
    show_msgbox "完成" "✅ Redis安装成功！\n\n默认端口: 6379\n配置文件: /etc/redis/redis.conf\n数据目录: /var/lib/redis"
    log "Redis安装完成"
}

# ====================== 其他功能 ======================

show_log_gui() {
    if [ -f "$INSTALL_LOG" ]; then
        dialog --title "安装日志" \
               --textbox "$INSTALL_LOG" \
               25 80
    else
        show_msgbox "错误" "日志文件不存在"
    fi
}

exit_program() {
    if show_yesno "退出程序" "确定要退出吗？"; then
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
    
    # 显示欢迎界面
    show_welcome
    
    # 显示主菜单
    show_main_menu
}

# 设置中断处理
trap 'echo -e "\n${RED}脚本被中断${NC}"; exit 1' INT TERM

# 启动程序
main "$@"

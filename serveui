#!/bin/bash

# =============================================
# Ubuntu 服务器部署脚本 - GUI版 v7.1
# 使用dialog创建终端图形界面
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
SCRIPT_VERSION="7.1"
SCRIPT_NAME="yx-deploy-gui"
BACKUP_DIR="/backup/${SCRIPT_NAME}"
LOG_DIR="/var/log/${SCRIPT_NAME}"
INSTALL_LOG="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
AUTO_RECOVERY=false
GUI_HEIGHT=24
GUI_WIDTH=80
MENU_HEIGHT=15
OUTPUT_HEIGHT=10
INPUT_HEIGHT=3

# ====================== 初始化 ======================

check_dialog() {
    if ! command -v dialog &>/dev/null; then
        echo -e "${YELLOW}安装dialog工具...${NC}"
        apt-get update -y >/dev/null 2>&1
        apt-get install -y dialog >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "${RED}无法安装dialog，请手动安装：apt-get install dialog${NC}"
            exit 1
        fi
    fi
}

init_log_system() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    touch "$INSTALL_LOG" 2>/dev/null
    exec > >(tee -a "$INSTALL_LOG") 2>&1
}

# ====================== GUI函数 ======================

show_header() {
    clear
    dialog --colors \
           --title " Ubuntu 服务器部署工具 v$SCRIPT_VERSION " \
           --ok-label "确定" \
           --cancel-label "退出" \
           --msgbox "\n欢迎使用服务器部署工具\n\n本工具提供以下功能：\n1. 系统优化配置\n2. Docker安装\n3. 面板安装\n4. 服务管理\n5. 系统监控\n\n操作日志: $INSTALL_LOG" \
           12 70 2>/dev/null
    
    if [ $? -ne 0 ]; then
        exit 0
    fi
}

show_main_menu() {
    while true; do
        choice=$(dialog --colors \
                --title " 主菜单 " \
                --ok-label "选择" \
                --cancel-label "退出" \
                --menu "\n请选择要执行的操作：" \
                $GUI_HEIGHT $GUI_WIDTH $MENU_HEIGHT \
                "1" "系统优化配置" \
                "2" "安装Docker容器" \
                "3" "安装1Panel面板" \
                "4" "安装宝塔面板" \
                "5" "完整安装（优化+Docker+1Panel）" \
                "6" "服务管理" \
                "7" "系统监控" \
                "8" "卸载工具" \
                "9" "系统信息" \
                "0" "退出程序" \
                3>&1 1>&2 2>&3)
        
        exit_status=$?
        
        if [ $exit_status -ne 0 ]; then
            dialog --title " 确认退出 " \
                   --yesno "确定要退出程序吗？" \
                   6 40 2>/dev/null
            
            if [ $? -eq 0 ]; then
                clear
                echo -e "${GREEN}感谢使用！再见！${NC}"
                exit 0
            else
                continue
            fi
        fi
        
        case $choice in
            1) system_optimization_gui ;;
            2) install_docker_gui ;;
            3) install_1panel_gui ;;
            4) install_baota_gui ;;
            5) full_installation ;;
            6) service_management_menu ;;
            7) system_monitor_menu ;;
            8) uninstall_menu ;;
            9) system_info_gui ;;
            0) exit_program ;;
        esac
    done
}

show_output_window() {
    local title="$1"
    local message="$2"
    
    dialog --title " $title " \
           --msgbox "$message" \
           $OUTPUT_HEIGHT 70 2>/dev/null
}

show_input_dialog() {
    local title="$1"
    local prompt="$2"
    local default="$3"
    
    dialog --title " $title " \
           --inputbox "$prompt" \
           $INPUT_HEIGHT 70 "$default" \
           3>&1 1>&2 2>&3 2>/dev/null
}

show_yesno_dialog() {
    local title="$1"
    local message="$2"
    
    dialog --title " $title " \
           --yesno "$message" \
           8 60 2>/dev/null
    
    return $?
}

show_progress() {
    local title="$1"
    local percent="$2"
    local message="$3"
    
    echo "$percent" | dialog --title " $title " \
                             --gauge "$message" \
                             8 70 0 2>/dev/null
}

show_checklist() {
    local title="$1"
    local prompt="$2"
    shift 2
    local options=("$@")
    
    dialog --title " $title " \
           --checklist "$prompt" \
           20 70 15 \
           "${options[@]}" \
           3>&1 1>&2 2>&3 2>/dev/null
}

# ====================== 日志函数 ======================

log_to_file() {
    local msg="$1"
    local level="${2:-INFO}"
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    echo "[${timestamp}] $level: $msg" >> "$INSTALL_LOG"
}

show_log() {
    if [ -f "$INSTALL_LOG" ]; then
        dialog --title " 安装日志 " \
               --textbox "$INSTALL_LOG" \
               25 80 2>/dev/null
    else
        show_output_window "错误" "日志文件不存在"
    fi
}

# ====================== 系统检查 ======================

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log_to_file "使用root权限运行"
        return 0
    fi
    
    if ! command -v sudo &>/dev/null; then
        show_output_window "错误" "未找到sudo命令，请以root用户运行此脚本"
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        show_output_window "提示" "需要sudo权限来运行此脚本\n请输入密码继续..."
        sudo echo "sudo权限检查通过" > /dev/null 2>&1 || {
            show_output_window "错误" "sudo权限验证失败"
            exit 1
        }
    fi
    
    exec sudo bash "$0" "$@"
}

check_ubuntu_version() {
    if [ ! -f "/etc/os-release" ]; then
        show_output_window "错误" "无法检测操作系统"
        exit 1
    fi
    
    if ! grep -q "Ubuntu" /etc/os-release; then
        show_output_window "错误" "本脚本仅适用于Ubuntu系统！"
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
        show_yesno_dialog "警告" "检测到 Ubuntu $version\n支持的版本：${supported_versions[*]}\n可能遇到兼容性问题！\n\n是否继续？"
        if [ $? -ne 0 ]; then
            exit 1
        fi
    fi
    
    log_to_file "检测到 Ubuntu $version 系统"
}

# ====================== 系统信息 ======================

system_info_gui() {
    local sys_info=""
    sys_info+="系统信息：\n"
    sys_info+="  OS: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)\n"
    sys_info+="  内核: $(uname -r)\n"
    sys_info+="  架构: $(uname -m)\n\n"
    
    sys_info+="资源使用：\n"
    sys_info+="  内存: $(free -h | awk 'NR==2{print $4 "/" $2}')\n"
    sys_info+="  磁盘: $(df -h / | awk 'NR==2{print $4 "/" $2}')\n"
    sys_info+="  CPU: $(grep -c ^processor /proc/cpuinfo) 核心\n\n"
    
    sys_info+="网络信息：\n"
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "未知")
    sys_info+="  IP地址: $ip_address\n"
    sys_info+="  主机名: $(hostname)\n\n"
    
    sys_info+="运行时间：\n"
    sys_info+="  $(uptime -p 2>/dev/null || uptime)\n"
    
    show_output_window "系统信息" "$sys_info"
}

# ====================== 软件源管理 ======================

change_mirror_source() {
    local current_source=$(grep -E "^deb " /etc/apt/sources.list | head -1 | grep -o "http[s]*://[^ ]*" || echo "官方源")
    
    show_yesno_dialog "切换软件源" "当前软件源: $current_source\n\n是否切换到国内镜像源以加速下载？\n推荐使用阿里云、清华或中科大镜像源"
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    local options=("1" "阿里云镜像源" off
                   "2" "清华大学镜像源" off
                   "3" "中科大镜像源" off
                   "4" "网易163镜像源" off
                   "5" "华为云镜像源" off)
    
    local mirror_choice=$(dialog --title " 选择镜像源 " \
                                  --radiolist "请选择要使用的镜像源：" \
                                  15 60 5 \
                                  "${options[@]}" \
                                  3>&1 1>&2 2>&3)
    
    if [ -z "$mirror_choice" ]; then
        return
    fi
    
    # 备份原有源
    cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d)
    
    local ubuntu_version=$(grep "VERSION_ID" /etc/os-release | cut -d'"' -f2 | cut -d'.' -f1-2)
    local arch=$(dpkg --print-architecture)
    
    case $mirror_choice in
        "1")  # 阿里云
            mirror_url="https://mirrors.aliyun.com/ubuntu/"
            ;;
        "2")  # 清华
            mirror_url="https://mirrors.tuna.tsinghua.edu.cn/ubuntu/"
            ;;
        "3")  # 中科大
            mirror_url="https://mirrors.ustc.edu.cn/ubuntu/"
            ;;
        "4")  # 网易
            mirror_url="http://mirrors.163.com/ubuntu/"
            ;;
        "5")  # 华为云
            mirror_url="https://repo.huaweicloud.com/ubuntu/"
            ;;
        *) return ;;
    esac
    
    # 生成新的sources.list
    cat > /etc/apt/sources.list << EOF
# 由服务器部署工具设置
# 镜像源: $mirror_url

deb ${mirror_url} ${ubuntu_version} main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-security main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-updates main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-proposed main restricted universe multiverse
deb ${mirror_url} ${ubuntu_version}-backports main restricted universe multiverse

# 源码仓库
# deb-src ${mirror_url} ${ubuntu_version} main restricted universe multiverse
# deb-src ${mirror_url} ${ubuntu_version}-security main restricted universe multiverse
# deb-src ${mirror_url} ${ubuntu_version}-updates main restricted universe multiverse
# deb-src ${mirror_url} ${ubuntu_version}-proposed main restricted universe multiverse
# deb-src ${mirror_url} ${ubuntu_version}-backports main restricted universe multiverse
EOF
    
    # 更新软件包列表
    (
        echo "10" ; sleep 1
        echo "# 正在更新软件包列表..." ; apt-get update -y >/dev/null 2>&1
        echo "100" ; sleep 1
        echo "# 软件源切换完成！"
    ) | show_progress "切换软件源" "正在更新软件包列表..."
    
    show_output_window "完成" "✅ 软件源已切换到: $mirror_url\n\n请运行 apt-get update 测试速度"
    log_to_file "切换到镜像源: $mirror_url"
}

# ====================== 可选软件安装 ======================

select_software_packages() {
    local selected_packages=""
    
    # 定义软件包选项
    local software_options=(
        "1" "基本工具 (curl, wget, vim, git)" on
        "2" "系统监控 (htop, iftop, iotop)" on
        "3" "网络工具 (net-tools, dnsutils, telnet)" on
        "4" "开发工具 (build-essential, gcc, g++)" off
        "5" "Python环境 (python3, python3-pip)" off
        "6" "数据库客户端 (mysql-client, postgresql-client)" off
        "7" "Web服务器 (nginx, apache2)" off
        "8" "文件传输 (rsync, lftp, axel)" on
        "9" "压缩工具 (zip, unzip, p7zip-full)" on
        "10" "版本控制 (git, subversion)" on
        "11" "进程管理 (screen, tmux)" on
        "12" "安全工具 (fail2ban, clamav)" off
        "13" "性能分析 (sysstat, dstat, atop)" off
        "14" "日志工具 (logrotate, multitail)" off
        "15" "容器工具 (docker.io, podman)" off
    )
    
    local choices=$(dialog --title " 选择安装软件 " \
                          --checklist "请选择要安装的软件包（空格键选择/取消）：" \
                          22 70 16 \
                          "${software_options[@]}" \
                          3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ] || [ -z "$choices" ]; then
        return ""
    fi
    
    # 将选择的软件包添加到列表
    local packages_to_install=""
    
    for choice in $choices; do
        case $choice in
            "1") packages_to_install+="curl wget vim git " ;;
            "2") packages_to_install+="htop iftop iotop " ;;
            "3") packages_to_install+="net-tools dnsutils telnet " ;;
            "4") packages_to_install+="build-essential gcc g++ make " ;;
            "5") packages_to_install+="python3 python3-pip " ;;
            "6") packages_to_install+="mysql-client postgresql-client " ;;
            "7") packages_to_install+="nginx apache2 " ;;
            "8") packages_to_install+="rsync lftp axel " ;;
            "9") packages_to_install+="zip unzip p7zip-full " ;;
            "10") packages_to_install+="git subversion " ;;
            "11") packages_to_install+="screen tmux " ;;
            "12") packages_to_install+="fail2ban clamav clamav-daemon " ;;
            "13") packages_to_install+="sysstat dstat atop " ;;
            "14") packages_to_install+="logrotate multitail " ;;
            "15") packages_to_install+="docker.io " ;;
        esac
    done
    
    echo "$packages_to_install"
}

install_selected_software() {
    local packages="$1"
    
    if [ -z "$packages" ]; then
        return
    fi
    
    show_yesno_dialog "确认安装" "将安装以下软件包：\n\n$packages\n\n是否继续？"
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    # 计算软件包数量用于进度条
    local package_count=$(echo "$packages" | wc -w)
    local progress_step=$((100 / package_count))
    local current_progress=0
    
    (
        for package in $packages; do
            current_progress=$((current_progress + progress_step))
            if [ $current_progress -gt 100 ]; then
                current_progress=100
            fi
            
            echo "$current_progress"
            echo "# 正在安装 $package..."
            
            # 尝试安装软件包
            if apt-get install -y "$package" >/dev/null 2>&1; then
                echo "# $package 安装成功"
            else
                echo "# $package 安装失败"
            fi
            
            sleep 1
        done
        
        echo "100"
        echo "# 软件安装完成！"
    ) | show_progress "安装软件" "正在安装选择的软件包..."
    
    show_output_window "完成" "✅ 选择的软件包安装完成！"
    log_to_file "安装软件包: $packages"
}

# ====================== 系统优化 ======================

system_optimization_gui() {
    # 显示优化选项
    local optimization_options=(
        "1" "切换软件源（加速下载）" off
        "2" "更新系统和软件包" on
        "3" "安装常用工具" on
        "4" "配置SSH安全" on
        "5" "优化内核参数" on
        "6" "配置防火墙" off
        "7" "设置时区（上海）" on
        "8" "配置时间同步" on
        "9" "优化系统服务" on
    )
    
    local choices=$(dialog --title " 系统优化选项 " \
                          --checklist "请选择要执行的优化项目（空格键选择/取消）：" \
                          20 70 12 \
                          "${optimization_options[@]}" \
                          3>&1 1>&2 2>&3)
    
    if [ $? -ne 0 ] || [ -z "$choices" ]; then
        return
    fi
    
    # 创建进度条
    local total_steps=$(echo "$choices" | wc -w)
    local step_size=$((100 / (total_steps + 1)))
    local current_progress=0
    
    (
        # 切换软件源
        if [[ $choices == *"1"* ]]; then
            current_progress=$((current_progress + step_size))
            echo "$current_progress"
            echo "# 切换软件源..."
            change_mirror_source
        fi
        
        # 更新系统和软件包
        if [[ $choices == *"2"* ]]; then
            current_progress=$((current_progress + step_size))
            echo "$current_progress"
            echo "# 更新软件包列表..."
            apt-get update -y >/dev/null 2>&1
            echo "# 升级软件包..."
            apt-get upgrade -y >/dev/null 2>&1
        fi
        
        # 安装常用工具
        if [[ $choices == *"3"* ]]; then
            current_progress=$((current_progress + step_size))
            echo "$current_progress"
            echo "# 选择要安装的软件..."
            
            # 显示软件选择对话框
            local selected_packages=$(select_software_packages)
            
            if [ -n "$selected_packages" ]; then
                echo "# 安装选择的软件包..."
                apt-get install -y $selected_packages >/dev/null 2>&1
            fi
        fi
        
        # 配置SSH安全
        if [[ $choices == *"4"* ]]; then
            current_progress=$((current_progress + step_size))
            echo "$current_progress"
            echo "# 配置SSH安全..."
            if [ -f "/etc/ssh/sshd_config" ]; then
                cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
                sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
                sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
                systemctl restart sshd >/dev/null 2>&1
            fi
        fi
        
        # 优化内核参数
        if [[ $choices == *"5"* ]]; then
            current_progress=$((current_progress + step_size))
            echo "$current_progress"
            echo "# 优化内核参数..."
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
            sysctl -p >/dev/null 2>&1
        fi
        
        # 配置防火墙
        if [[ $choices == *"6"* ]]; then
            current_progress=$((current_progress + step_size))
            echo "$current_progress"
            echo "# 配置防火墙..."
            ufw --force enable >/dev/null 2>&1
            ufw default deny incoming >/dev/null 2>&1
            ufw default allow outgoing >/dev/null 2>&1
            ufw allow 22/tcp >/dev/null 2>&1
        fi
        
        # 设置时区
        if [[ $choices == *"7"* ]]; then
            current_progress=$((current_progress + step_size))
            echo "$current_progress"
            echo "# 设置时区..."
            timedatectl set-timezone Asia/Shanghai >/dev/null 2>&1
        fi
        
        # 配置时间同步
        if [[ $choices == *"8"* ]]; then
            current_progress=$((current_progress + step_size))
            echo "$current_progress"
            echo "# 配置时间同步..."
            systemctl stop systemd-timesyncd 2>/dev/null || true
            systemctl disable systemd-timesyncd 2>/dev/null || true
            systemctl enable chronyd >/dev/null 2>&1
            systemctl restart chronyd >/dev/null 2>&1
        fi
        
        # 优化系统服务
        if [[ $choices == *"9"* ]]; then
            current_progress=$((current_progress + step_size))
            echo "$current_progress"
            echo "# 优化系统服务..."
            systemctl disable bluetooth 2>/dev/null || true
            systemctl disable cups 2>/dev/null || true
            systemctl disable avahi-daemon 2>/dev/null || true
        fi
        
        echo "100"
        echo "# 系统优化完成！"
    ) | show_progress "系统优化" "正在执行系统优化..."
    
    show_output_window "完成" "✅ 系统优化配置完成！\n\n已执行以下优化：\n$choices\n\n请重启系统使部分优化生效"
    log_to_file "系统优化完成"
}

# ====================== Docker安装 ======================

install_docker_gui() {
    if command -v docker &>/dev/null; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "未知版本")
        show_yesno_dialog "Docker已安装" "Docker已经安装，版本: $docker_version\n\n是否重新安装？"
        if [ $? -ne 0 ]; then
            return
        fi
    fi
    
    show_yesno_dialog "安装Docker" "将安装Docker容器引擎\n\n安装后会自动配置镜像加速器\n\n是否继续？"
    if [ $? -ne 0 ]; then
        return
    fi
    
    # 安装Docker
    (
        echo "10" ; sleep 1
        echo "# 卸载旧版本Docker..." ; sleep 1
        echo "20" ; sleep 1
        echo "# 安装依赖包..."
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release >/dev/null 2>&1
        echo "40" ; sleep 1
        echo "# 添加Docker官方GPG密钥..."
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg >/dev/null 2>&1
        echo "60" ; sleep 1
        echo "# 添加Docker仓库..."
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null 2>&1
        echo "70" ; sleep 1
        echo "# 安装Docker..."
        apt-get update -y >/dev/null 2>&1
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
        echo "90" ; sleep 1
        echo "# 启动Docker服务..."
        systemctl start docker >/dev/null 2>&1
        systemctl enable docker >/dev/null 2>&1
        echo "100" ; sleep 1
        echo "# Docker安装完成！"
    ) | show_progress "安装Docker" "正在安装Docker容器引擎..."
    
    # 配置镜像加速器
    show_yesno_dialog "配置镜像加速" "是否配置Docker镜像加速器？\n\n这将显著提高镜像下载速度"
    
    if [ $? -eq 0 ]; then
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com",
    "https://registry.docker-cn.com"
  ]
}
EOF
        systemctl restart docker >/dev/null 2>&1
    fi
    
    # 测试Docker
    show_output_window "测试" "正在测试Docker安装..."
    
    if docker run --rm hello-world &>/dev/null; then
        show_output_window "成功" "✅ Docker安装成功！\n\n版本: $(docker --version 2>/dev/null)\n\n可以使用docker命令管理容器"
    else
        show_output_window "警告" "⚠ Docker安装完成，但测试失败\n\n请检查服务状态：systemctl status docker"
    fi
    
    log_to_file "Docker安装完成"
}

# ====================== 面板安装 ======================

install_1panel_gui() {
    if systemctl list-unit-files | grep -q "1panel" || command -v 1pctl &>/dev/null; then
        show_yesno_dialog "1Panel已安装" "1Panel面板已经安装！\n\n是否重新安装？"
        if [ $? -ne 0 ]; then
            return
        fi
    fi
    
    show_yesno_dialog "安装1Panel" "将安装1Panel服务器面板\n\n默认端口: 9090\n用户名: admin\n\n安装过程中需要设置密码\n\n是否继续？"
    if [ $? -ne 0 ]; then
        return
    fi
    
    # 获取安装信息
    local panel_port=$(show_input_dialog "1Panel端口" "请输入1Panel面板端口号（默认: 9090）" "9090")
    if [ -z "$panel_port" ]; then
        panel_port="9090"
    fi
    
    # 安装1Panel
    (
        echo "10" ; sleep 1
        echo "# 下载1Panel安装脚本..." ; sleep 2
        echo "30" ; sleep 1
        echo "# 运行安装脚本..."
        if command -v curl &>/dev/null; then
            curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o /tmp/quick_start.sh >/dev/null 2>&1
        else
            wget -q https://resource.fit2cloud.com/1panel/package/quick_start.sh -O /tmp/quick_start.sh >/dev/null 2>&1
        fi
        chmod +x /tmp/quick_start.sh
        echo "60" ; sleep 1
        echo "# 安装1Panel（这可能需要几分钟）..."
        bash /tmp/quick_start.sh >/dev/null 2>&1
        echo "90" ; sleep 1
        echo "# 配置服务..."
        systemctl enable 1panel >/dev/null 2>&1
        systemctl start 1panel >/dev/null 2>&1
        echo "100" ; sleep 1
        echo "# 1Panel安装完成！"
    ) | show_progress "安装1Panel" "正在安装1Panel面板..."
    
    # 获取IP地址
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    show_output_window "完成" "✅ 1Panel面板安装完成！\n\n访问地址: https://${ip_address}:${panel_port}\n用户名: admin\n密码: 您刚才设置的密码\n\n请及时登录并修改密码"
    log_to_file "1Panel安装完成，端口: $panel_port"
}

install_baota_gui() {
    if [ -f "/etc/init.d/bt" ]; then
        show_yesno_dialog "宝塔已安装" "宝塔面板已经安装！\n\n是否重新安装？"
        if [ $? -ne 0 ]; then
            return
        fi
    fi
    
    show_yesno_dialog "安装宝塔" "将安装宝塔Linux面板\n\n默认端口: 8888\n\n安装过程需要5-10分钟\n\n是否继续？"
    if [ $? -ne 0 ]; then
        return
    fi
    
    (
        echo "10" ; sleep 1
        echo "# 下载宝塔安装脚本..." ; sleep 2
        echo "30" ; sleep 1
        echo "# 运行安装脚本..."
        if command -v curl &>/dev/null; then
            curl -sSO https://download.bt.cn/install/install_panel.sh >/dev/null 2>&1
        else
            wget -q https://download.bt.cn/install/install_panel.sh >/dev/null 2>&1
        fi
        echo "60" ; sleep 1
        echo "# 安装宝塔面板（这可能需要几分钟）..."
        bash install_panel.sh >/dev/null 2>&1
        echo "90" ; sleep 1
        echo "# 等待服务启动..."
        sleep 10
        echo "100" ; sleep 1
        echo "# 宝塔面板安装完成！"
    ) | show_progress "安装宝塔" "正在安装宝塔Linux面板..."
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    
    show_output_window "完成" "✅ 宝塔面板安装完成！\n\n访问地址: http://${ip_address}:8888\n\n请查看屏幕输出或运行 'bt default' 获取登录信息"
    log_to_file "宝塔面板安装完成"
}

# ====================== 其他功能 ======================

full_installation() {
    show_yesno_dialog "完整安装" "完整安装将执行以下操作：\n\n1. 系统优化配置\n2. 安装Docker\n3. 安装1Panel面板\n\n预计需要10-15分钟\n\n是否继续？"
    
    if [ $? -ne 0 ]; then
        return
    fi
    
    (
        echo "10" ; sleep 1
        echo "# 开始系统优化..." ; system_optimization_gui >/dev/null 2>&1
        echo "40" ; sleep 1
        echo "# 安装Docker..." ; install_docker_gui >/dev/null 2>&1
        echo "70" ; sleep 1
        echo "# 安装1Panel面板..." ; install_1panel_gui >/dev/null 2>&1
        echo "100" ; sleep 1
        echo "# 完整安装完成！"
    ) | show_progress "完整安装" "正在执行完整安装流程..."
    
    show_output_window "完成" "✅ 完整安装完成！\n\n所有组件已安装并配置完成\n\n建议重启系统以确保所有服务正常运行"
}

service_management_menu() {
    while true; do
        local choice=$(dialog --title " 服务管理 " \
                             --menu "请选择操作：" \
                             15 60 8 \
                             "1" "查看服务状态" \
                             "2" "启动服务" \
                             "3" "停止服务" \
                             "4" "重启服务" \
                             "5" "设置开机自启" \
                             "6" "查看服务日志" \
                             "7" "返回主菜单" \
                             3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        case $choice in
            1) show_services_status ;;
            2) start_service_gui ;;
            3) stop_service_gui ;;
            4) restart_service_gui ;;
            5) enable_service_gui ;;
            6) show_service_logs ;;
            7) return ;;
        esac
    done
}

show_services_status() {
    local services_status="系统服务状态：\n\n"
    
    # 检查关键服务
    local services=("docker" "1panel" "ssh" "chronyd" "nginx" "apache2" "mysql" "postgresql")
    local service_names=("Docker" "1Panel" "SSH" "时间同步" "Nginx" "Apache" "MySQL" "PostgreSQL")
    
    for i in "${!services[@]}"; do
        local service="${services[i]}"
        local name="${service_names[i]}"
        
        if systemctl list-unit-files | grep -q "${service}.service"; then
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                services_status+="✅ $name: 运行中\n"
            else
                services_status+="❌ $name: 已停止\n"
            fi
        else
            services_status+="⚪ $name: 未安装\n"
        fi
    done
    
    show_output_window "服务状态" "$services_status"
}

start_service_gui() {
    local service=$(dialog --title " 启动服务 " \
                          --inputbox "请输入要启动的服务名称：" \
                          8 60 \
                          3>&1 1>&2 2>&3)
    
    if [ -n "$service" ]; then
        systemctl start "$service" >/dev/null 2>&1
        
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            show_output_window "成功" "✅ 服务 $service 启动成功！"
        else
            show_output_window "错误" "❌ 服务 $service 启动失败！"
        fi
    fi
}

stop_service_gui() {
    local service=$(dialog --title " 停止服务 " \
                          --inputbox "请输入要停止的服务名称：" \
                          8 60 \
                          3>&1 1>&2 2>&3)
    
    if [ -n "$service" ]; then
        systemctl stop "$service" >/dev/null 2>&1
        
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            show_output_window "错误" "❌ 服务 $service 停止失败！"
        else
            show_output_window "成功" "✅ 服务 $service 已停止！"
        fi
    fi
}

restart_service_gui() {
    local service=$(dialog --title " 重启服务 " \
                          --inputbox "请输入要重启的服务名称：" \
                          8 60 \
                          3>&1 1>&2 2>&3)
    
    if [ -n "$service" ]; then
        systemctl restart "$service" >/dev/null 2>&1
        
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            show_output_window "成功" "✅ 服务 $service 重启成功！"
        else
            show_output_window "错误" "❌ 服务 $service 重启失败！"
        fi
    fi
}

enable_service_gui() {
    local service=$(dialog --title " 开机自启 " \
                          --inputbox "请输入要设置开机自启的服务名称：" \
                          8 60 \
                          3>&1 1>&2 2>&3)
    
    if [ -n "$service" ]; then
        systemctl enable "$service" >/dev/null 2>&1
        
        if systemctl is-enabled "$service" 2>/dev/null; then
            show_output_window "成功" "✅ 服务 $service 已设置为开机自启！"
        else
            show_output_window "错误" "❌ 服务 $service 设置开机自启失败！"
        fi
    fi
}

show_service_logs() {
    local service=$(dialog --title " 查看日志 " \
                          --inputbox "请输入要查看日志的服务名称：" \
                          8 60 \
                          3>&1 1>&2 2>&3)
    
    if [ -n "$service" ]; then
        journalctl -u "$service" -n 50 --no-pager > /tmp/service_log.txt 2>&1
        
        if [ -s "/tmp/service_log.txt" ]; then
            dialog --title " $service 服务日志 " \
                   --textbox /tmp/service_log.txt \
                   25 80
        else
            show_output_window "错误" "无法获取 $service 的日志"
        fi
        
        rm -f /tmp/service_log.txt
    fi
}

system_monitor_menu() {
    while true; do
        local choice=$(dialog --title " 系统监控 " \
                             --menu "请选择监控项目：" \
                             15 60 6 \
                             "1" "实时系统资源" \
                             "2" "查看进程列表" \
                             "3" "查看磁盘使用" \
                             "4" "查看网络连接" \
                             "5" "查看系统日志" \
                             "6" "返回主菜单" \
                             3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        case $choice in
            1) show_system_resources ;;
            2) show_process_list ;;
            3) show_disk_usage ;;
            4) show_network_connections ;;
            5) show_system_logs ;;
            6) return ;;
        esac
    done
}

show_system_resources() {
    top -b -n 1 | head -20 > /tmp/top_output.txt
    dialog --title " 系统资源使用 " \
           --textbox /tmp/top_output.txt \
           20 80
    rm -f /tmp/top_output.txt
}

show_process_list() {
    ps aux --sort=-%cpu | head -30 > /tmp/ps_output.txt
    dialog --title " 进程列表 (按CPU排序) " \
           --textbox /tmp/ps_output.txt \
           20 80
    rm -f /tmp/ps_output.txt
}

show_disk_usage() {
    df -h > /tmp/df_output.txt
    dialog --title " 磁盘使用情况 " \
           --textbox /tmp/df_output.txt \
           15 80
    rm -f /tmp/df_output.txt
}

show_network_connections() {
    netstat -tunlp > /tmp/netstat_output.txt
    dialog --title " 网络连接状态 " \
           --textbox /tmp/netstat_output.txt \
           20 80
    rm -f /tmp/netstat_output.txt
}

show_system_logs() {
    dmesg | tail -50 > /tmp/dmesg_output.txt
    dialog --title " 系统日志 (dmesg) " \
           --textbox /tmp/dmesg_output.txt \
           20 80
    rm -f /tmp/dmesg_output.txt
}

uninstall_menu() {
    while true; do
        local choice=$(dialog --title " 卸载工具 " \
                             --menu "请选择要卸载的组件：" \
                             15 60 5 \
                             "1" "卸载Docker" \
                             "2" "卸载1Panel" \
                             "3" "卸载宝塔" \
                             "4" "清理所有安装" \
                             "5" "返回主菜单" \
                             3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        case $choice in
            1) uninstall_docker_gui ;;
            2) uninstall_1panel_gui ;;
            3) uninstall_baota_gui ;;
            4) cleanup_all_gui ;;
            5) return ;;
        esac
    done
}

uninstall_docker_gui() {
    show_yesno_dialog "卸载Docker" "确定要卸载Docker吗？\n\n这将删除所有Docker容器和镜像！"
    
    if [ $? -eq 0 ]; then
        systemctl stop docker >/dev/null 2>&1
        apt-get remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
        apt-get purge -y docker-ce docker-ce-cli containerd.io >/dev/null 2>&1
        rm -rf /var/lib/docker
        rm -rf /var/lib/containerd
        show_output_window "完成" "✅ Docker已卸载"
    fi
}

uninstall_1panel_gui() {
    show_yesno_dialog "卸载1Panel" "确定要卸载1Panel面板吗？\n\n这将删除1Panel及其数据！"
    
    if [ $? -eq 0 ]; then
        systemctl stop 1panel >/dev/null 2>&1
        rm -rf /opt/1panel
        rm -rf /usr/local/bin/1panel
        rm -rf /usr/local/bin/1pctl
        show_output_window "完成" "✅ 1Panel已卸载"
    fi
}

uninstall_baota_gui() {
    show_yesno_dialog "卸载宝塔" "确定要卸载宝塔面板吗？\n\n这将删除宝塔及其网站数据！"
    
    if [ $? -eq 0 ]; then
        if [ -f "/www/server/panel/install.sh" ]; then
            bash /www/server/panel/install.sh uninstall >/dev/null 2>&1
        fi
        rm -rf /www/server/panel
        show_output_window "完成" "✅ 宝塔面板已卸载"
    fi
}

cleanup_all_gui() {
    show_yesno_dialog "清理所有" "确定要清理所有安装吗？\n\n这将卸载：\n1. Docker\n2. 1Panel\n3. 宝塔\n\n请先备份重要数据！"
    
    if [ $? -eq 0 ]; then
        uninstall_docker_gui
        uninstall_1panel_gui
        uninstall_baota_gui
        
        # 清理临时文件
        apt-get autoremove -y >/dev/null 2>&1
        apt-get autoclean -y >/dev/null 2>&1
        
        show_output_window "完成" "✅ 所有安装已清理完成"
    fi
}

exit_program() {
    dialog --title " 确认退出 " \
           --yesno "确定要退出程序吗？" \
           6 40
    
    if [ $? -eq 0 ]; then
        clear
        echo -e "${GREEN}感谢使用服务器部署工具！${NC}"
        echo -e "${YELLOW}日志文件: $INSTALL_LOG${NC}"
        exit 0
    fi
}

# ====================== 主程序 ======================

main() {
    # 检查sudo权限
    check_sudo "$@"
    
    # 检查dialog工具
    check_dialog
    
    # 初始化日志系统
    init_log_system
    
    # 检查系统版本
    check_ubuntu_version
    
    # 显示欢迎界面
    show_header
    
    # 显示主菜单
    show_main_menu
}

# 错误处理
trap 'echo -e "${RED}脚本被中断${NC}"; exit 1' INT TERM

# 执行主程序
main "$@"

#!/bin/bash

# =============================================
# Ubuntu 服务器部署脚本 - 终端GUI稳定版 v8.2
# 修复控制字符显示问题
# =============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# 全局变量
SCRIPT_VERSION="8.2"
SCRIPT_NAME="yx-deploy"
BACKUP_DIR="/backup/${SCRIPT_NAME}"
LOG_DIR="/var/log/${SCRIPT_NAME}"
INSTALL_LOG="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
AUTO_RECOVERY=false

# ====================== 终端修复函数 ======================

fix_terminal() {
    # 重置终端状态
    stty sane
    tput reset
    echo -ne "\033c"
    clear
}

safe_read() {
    # 安全读取输入，防止控制字符问题
    local prompt="$1"
    local default="$2"
    local input=""
    
    # 设置原始模式以避免特殊字符
    stty -echo -icanon time 0 min 0
    
    echo -ne "${CYAN}$prompt${NC} "
    if [ -n "$default" ]; then
        echo -ne "[$default]: "
    fi
    
    # 读取单个字符直到回车
    while IFS= read -r -n1 char; do
        case "$char" in
            $'\0')  # null character
                continue
                ;;
            $'\n'|$'\r')  # enter
                echo
                break
                ;;
            $'\177'|$'\b')  # backspace
                if [ ${#input} -gt 0 ]; then
                    input="${input%?}"
                    echo -ne "\b \b"
                fi
                ;;
            [[:print:]])  # 可打印字符
                input+="$char"
                echo -n "$char"
                ;;
        esac
    done
    
    # 恢复终端设置
    stty echo icanon
    
    if [ -z "$input" ] && [ -n "$default" ]; then
        echo "$default"
    else
        echo "$input"
    fi
}

# ====================== 基础函数 ======================

init_log_system() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    touch "$INSTALL_LOG" 2>/dev/null
    exec 2>> "$INSTALL_LOG"
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

# ====================== 显示函数 ======================

show_header() {
    fix_terminal
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                              ║"
    echo "║               Ubuntu 服务器部署工具 v$SCRIPT_VERSION                        ║"
    echo "║                     终端GUI稳定版                                            ║"
    echo "║                                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

show_menu() {
    local title="$1"
    shift
    local menu_items=("$@")
    
    show_header
    echo -e "${CYAN}$title${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    echo ""
    
    local i=1
    for item in "${menu_items[@]}"; do
        if [[ $item != "---" ]]; then
            printf "  %2d. %s\n" $i "$item"
            ((i++))
        else
            echo ""
        fi
    done
    
    echo ""
    echo "══════════════════════════════════════════════════════════════════════════════"
    echo -e "${YELLOW}提示: 输入数字选择，0返回/退出${NC}"
    echo ""
    
    # 使用安全读取
    local choice
    read -p "请选择 (0-$((i-1))): " choice
    
    # 验证输入
    if [[ ! "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 0 ] || [ "$choice" -ge $i ]; then
        error "无效选择！"
        sleep 2
        return 0
    fi
    
    echo "$choice"
}

show_yesno() {
    local prompt="$1"
    
    while true; do
        echo ""
        echo -e "${YELLOW}$prompt${NC}"
        echo -n "(y/N): "
        
        # 使用安全读取
        local answer
        read -n1 answer
        echo ""
        
        case "$answer" in
            [Yy]) return 0 ;;
            [Nn]) return 1 ;;
            *) 
                error "请输入 y 或 n"
                sleep 1
                ;;
        esac
    done
}

# ====================== 主菜单 ======================

main_menu() {
    while true; do
        choice=$(show_menu "主菜单" \
            "系统优化配置" \
            "安装Docker容器" \
            "安装1Panel面板" \
            "安装宝塔面板" \
            "安装Web服务器" \
            "安装数据库" \
            "服务管理" \
            "系统监控" \
            "卸载工具" \
            "系统信息" \
            "查看日志" \
            "退出程序")
        
        case $choice in
            1) system_optimization_menu ;;
            2) install_docker_menu ;;
            3) install_1panel_menu ;;
            4) install_baota_menu ;;
            5) install_web_menu ;;
            6) install_database_menu ;;
            7) service_management_menu ;;
            8) system_monitor_menu ;;
            9) uninstall_menu ;;
            10) system_info_menu ;;
            11) show_log_menu ;;
            12) exit_program ;;
            0) continue ;;
        esac
    done
}

# ====================== 系统优化菜单 ======================

system_optimization_menu() {
    while true; do
        choice=$(show_menu "系统优化配置" \
            "基础系统优化" \
            "切换软件源" \
            "安装常用工具" \
            "安全加固配置" \
            "性能优化配置" \
            "返回主菜单")
        
        case $choice in
            1) basic_optimization ;;
            2) change_mirror_source ;;
            3) install_tools_menu ;;
            4) security_hardening ;;
            5) performance_tuning ;;
            6) return ;;
            0) return ;;
        esac
    done
}

basic_optimization() {
    show_header
    echo -e "${CYAN}基础系统优化${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    if ! show_yesno "是否执行基础系统优化？"; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}1. 更新软件包列表...${NC}"
    apt-get update -y
    
    echo -e "${BLUE}2. 升级软件包...${NC}"
    apt-get upgrade -y
    
    echo -e "${BLUE}3. 清理无用包...${NC}"
    apt-get autoremove -y
    apt-get autoclean -y
    
    echo -e "${BLUE}4. 设置时区...${NC}"
    timedatectl set-timezone Asia/Shanghai
    
    echo -e "${BLUE}5. 配置时间同步...${NC}"
    systemctl enable chronyd
    systemctl restart chronyd
    
    log "基础系统优化完成"
    read -p "按回车键继续..."
}

change_mirror_source() {
    while true; do
        show_header
        echo -e "${CYAN}切换软件源${NC}"
        echo "══════════════════════════════════════════════════════════════════════════════"
        
        local current_source=$(grep -E "^deb " /etc/apt/sources.list | head -1 | grep -o "http[s]*://[^ ]*" || echo "官方源")
        echo -e "当前软件源: ${YELLOW}$current_source${NC}"
        echo ""
        
        echo "可选镜像源："
        echo "  1. 阿里云 (aliyun.com) - 推荐"
        echo "  2. 清华大学 (tuna.tsinghua.edu.cn)"
        echo "  3. 中科大 (ustc.edu.cn)"
        echo "  4. 网易163 (mirrors.163.com)"
        echo "  5. 华为云 (huaweicloud.com)"
        echo "  6. 恢复默认官方源"
        echo "  0. 返回"
        echo ""
        
        local mirror_choice
        read -p "请选择镜像源 (0-6): " mirror_choice
        
        case $mirror_choice in
            0) return ;;
            1) mirror_url="https://mirrors.aliyun.com/ubuntu/" ;;
            2) mirror_url="https://mirrors.tuna.tsinghua.edu.cn/ubuntu/" ;;
            3) mirror_url="https://mirrors.ustc.edu.cn/ubuntu/" ;;
            4) mirror_url="http://mirrors.163.com/ubuntu/" ;;
            5) mirror_url="https://repo.huaweicloud.com/ubuntu/" ;;
            6) mirror_url="http://archive.ubuntu.com/ubuntu/" ;;
            *) 
                error "无效选择！"
                sleep 2
                continue
                ;;
        esac
        
        if ! show_yesno "确定要切换到 $mirror_url 吗？"; then
            continue
        fi
        
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
        
        echo -e "${BLUE}更新软件源...${NC}"
        apt-get update -y
        
        log "已切换到镜像源: $mirror_url"
        
        if show_yesno "是否测试新源速度？"; then
            echo -e "${BLUE}测试下载速度...${NC}"
            time curl -I $mirror_url
        fi
        
        read -p "按回车键继续..."
        break
    done
}

install_tools_menu() {
    show_header
    echo -e "${CYAN}安装常用工具${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    # 工具分类
    local tools_list=()
    local tools_selected=""
    
    echo "选择要安装的工具（输入对应数字，多个用空格分隔）："
    echo ""
    
    local tools=(
        "curl wget vim git net-tools : 基础工具"
        "htop iftop iotop nmon : 监控工具"
        "build-essential gcc g++ make : 开发工具"
        "python3 python3-pip python3-venv : Python环境"
        "dnsutils telnet traceroute netcat : 网络工具"
        "zip unzip p7zip-full rar unrar : 压缩工具"
        "screen tmux byobu : 进程管理"
        "tree ncdu jq bc : 其他实用工具"
        "fail2ban rkhunter : 安全工具"
        "docker.io docker-compose : 容器工具"
    )
    
    local i=1
    for tool in "${tools[@]}"; do
        echo "  $i. ${tool#*:}"
        tools_list[$i]="${tool%:*}"
        ((i++))
    done
    
    echo ""
    echo "  0. 返回"
    echo ""
    
    read -p "请选择: " selections
    
    if [[ "$selections" == "0" ]]; then
        return
    fi
    
    for sel in $selections; do
        if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le ${#tools_list[@]} ]; then
            tools_selected+="${tools_list[$sel]} "
        fi
    done
    
    if [ -n "$tools_selected" ]; then
        echo -e "${BLUE}安装工具: $tools_selected${NC}"
        apt-get install -y $tools_selected
        log "工具安装完成: $tools_selected"
    else
        warn "未选择任何工具"
    fi
    
    read -p "按回车键继续..."
}

security_hardening() {
    show_header
    echo -e "${CYAN}安全加固配置${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    if ! show_yesno "是否进行安全加固配置？"; then
        return
    fi
    
    echo ""
    
    # SSH安全配置
    if [ -f "/etc/ssh/sshd_config" ]; then
        echo -e "${BLUE}SSH安全配置：${NC}"
        
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
        
        if show_yesno "  禁止root用户SSH登录？"; then
            sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
            sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
            echo "    ✓ 已禁止root用户SSH登录"
        fi
        
        if show_yesno "  修改SSH端口（默认22）？"; then
            local ssh_port
            read -p "    请输入新的SSH端口 (1024-65535): " ssh_port
            if [[ "$ssh_port" =~ ^[0-9]+$ ]] && [ "$ssh_port" -ge 1024 ] && [ "$ssh_port" -le 65535 ]; then
                sed -i "s/#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
                sed -i "s/Port 22/Port $ssh_port/" /etc/ssh/sshd_config
                echo "    ✓ SSH端口已修改为: $ssh_port"
            fi
        fi
        
        systemctl restart sshd
        echo "    ✓ SSH服务已重启"
    fi
    
    # 防火墙配置
    echo ""
    echo -e "${BLUE}防火墙配置：${NC}"
    if show_yesno "  启用UFW防火墙？"; then
        ufw --force enable
        ufw default deny incoming
        ufw default allow outgoing
        echo "    ✓ 防火墙已启用"
        
        if show_yesno "  是否允许SSH端口？"; then
            ufw allow ssh
            echo "    ✓ 已允许SSH端口"
        fi
    fi
    
    # Fail2ban安装
    if show_yesno "  安装Fail2ban防暴力破解？"; then
        apt-get install -y fail2ban
        systemctl enable fail2ban
        systemctl start fail2ban
        echo "    ✓ Fail2ban已安装并启动"
    fi
    
    log "安全加固配置完成"
    read -p "按回车键继续..."
}

performance_tuning() {
    show_header
    echo -e "${CYAN}性能优化配置${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    if ! show_yesno "是否进行性能优化配置？"; then
        return
    fi
    
    echo ""
    
    # 内核参数优化
    echo -e "${BLUE}内核参数优化：${NC}"
    
    cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d)
    
    cat >> /etc/sysctl.conf << 'EOF'

# ===== 网络性能优化 =====
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.default_qdisc = fq
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30

# ===== 系统性能优化 =====
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5

# ===== 安全优化 =====
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
EOF
    
    sysctl -p
    echo "    ✓ 内核参数已优化"
    
    # 资源限制优化
    echo ""
    echo -e "${BLUE}资源限制优化：${NC}"
    
    cat >> /etc/security/limits.conf << 'EOF'

* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
root soft nofile 65536
root hard nofile 65536
EOF
    
    echo "    ✓ 资源限制已优化"
    
    # 禁用不需要的服务
    echo ""
    echo -e "${BLUE}服务优化：${NC}"
    
    if show_yesno "  禁用不需要的系统服务？"; then
        systemctl disable bluetooth 2>/dev/null || true
        systemctl disable cups 2>/dev/null || true
        systemctl disable avahi-daemon 2>/dev/null || true
        echo "    ✓ 已禁用不需要的服务"
    fi
    
    log "性能优化配置完成"
    read -p "按回车键继续..."
}

# ====================== Docker安装 ======================

install_docker_menu() {
    show_header
    echo -e "${CYAN}安装Docker容器${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    # 检查是否已安装
    if command -v docker &>/dev/null; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',')
        echo -e "当前已安装: ${GREEN}Docker $docker_version${NC}"
        echo ""
        
        if ! show_yesno "是否重新安装Docker？"; then
            return
        fi
    fi
    
    if ! show_yesno "是否安装Docker容器引擎？"; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}开始安装Docker...${NC}"
    echo ""
    
    # 卸载旧版本
    echo "1. 卸载旧版本Docker..."
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
        echo -e "   ${GREEN}✓ Docker安装成功！${NC}"
        log "Docker安装成功"
    else
        echo -e "   ${YELLOW}⚠ Docker安装完成，但测试失败${NC}"
        warn "Docker测试失败"
    fi
    
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                          Docker安装完成！${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${NC}"
    
    read -p "按回车键继续..."
}

# ====================== 面板安装 ======================

install_1panel_menu() {
    show_header
    echo -e "${CYAN}安装1Panel面板${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    # 检查是否已安装
    if systemctl list-unit-files | grep -q 1panel || command -v 1pctl &>/dev/null; then
        echo -e "当前已安装: ${GREEN}1Panel面板${NC}"
        echo ""
        
        if ! show_yesno "是否重新安装1Panel？"; then
            return
        fi
        
        # 卸载现有版本
        echo "卸载现有1Panel..."
        systemctl stop 1panel 2>/dev/null || true
        rm -rf /opt/1panel
        rm -rf /usr/local/bin/1panel
    fi
    
    if ! show_yesno "是否安装1Panel服务器面板？"; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}开始安装1Panel...${NC}"
    echo ""
    echo "安装说明："
    echo "  1. 安装过程中需要您输入 'y' 确认"
    echo "  2. 需要设置面板访问密码"
    echo "  3. 默认访问地址: https://服务器IP:9090"
    echo "  4. 用户名: admin"
    echo ""
    
    read -p "按回车键开始安装（按Ctrl+C取消）..."
    
    # 安装1Panel
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh
    chmod +x quick_start.sh
    
    echo ""
    echo -e "${YELLOW}请按照以下步骤操作：${NC}"
    echo "  1. 当提示 'Please enter y or n:' 时，请输入 y"
    echo "  2. 设置面板密码（输入两次）"
    echo "  3. 等待安装完成"
    echo ""
    
    # 运行安装脚本
    ./quick_start.sh
    
    # 清理临时文件
    rm -f quick_start.sh
    
    # 检查安装结果
    sleep 5
    if systemctl list-unit-files | grep -q 1panel; then
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}                         1Panel安装完成！${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}访问地址: https://${ip_address}:9090${NC}"
        echo -e "${YELLOW}用户名: admin${NC}"
        echo -e "${YELLOW}密码: 您刚才设置的密码${NC}"
        echo ""
        echo -e "${RED}⚠ 重要：请立即登录并修改默认密码！${NC}"
        
        log "1Panel安装完成"
    else
        error "1Panel安装失败！"
    fi
    
    read -p "按回车键继续..."
}

install_baota_menu() {
    show_header
    echo -e "${CYAN}安装宝塔面板${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    # 检查是否已安装
    if [ -f "/etc/init.d/bt" ]; then
        echo -e "当前已安装: ${GREEN}宝塔面板${NC}"
        echo ""
        
        if ! show_yesno "是否重新安装宝塔？"; then
            return
        fi
    fi
    
    if ! show_yesno "是否安装宝塔Linux面板？"; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}开始安装宝塔面板...${NC}"
    echo ""
    echo "安装说明："
    echo "  1. 安装过程需要5-10分钟"
    echo "  2. 安装过程中需要您输入 'y' 确认"
    echo "  3. 安装完成后会显示登录信息"
    echo "  4. 请保存显示的登录信息"
    echo "  5. 默认访问地址: http://服务器IP:8888"
    echo ""
    
    read -p "按回车键开始安装（按Ctrl+C取消）..."
    
    # 安装宝塔
    if command -v curl &>/dev/null; then
        curl -sSO https://download.bt.cn/install/install_panel.sh
    else
        wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh
    fi
    
    echo ""
    echo -e "${YELLOW}请按照以下步骤操作：${NC}"
    echo "  1. 当提示确认时，请输入 y"
    echo "  2. 等待安装完成"
    echo "  3. 保存显示的登录信息"
    echo ""
    
    # 运行安装脚本
    bash install_panel.sh
    
    # 检查安装结果
    sleep 5
    if [ -f "/etc/init.d/bt" ]; then
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null)
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}                         宝塔面板安装完成！${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}访问地址: http://${ip_address}:8888${NC}"
        echo -e "${YELLOW}请查看屏幕上显示的登录信息${NC}"
        echo ""
        
        log "宝塔面板安装完成"
    else
        error "宝塔面板安装失败！"
    fi
    
    read -p "按回车键继续..."
}

# ====================== Web服务器安装 ======================

install_web_menu() {
    while true; do
        choice=$(show_menu "安装Web服务器" \
            "安装Nginx" \
            "安装Apache2" \
            "安装OpenLiteSpeed" \
            "返回主菜单")
        
        case $choice in
            1) install_nginx ;;
            2) install_apache ;;
            3) install_openlitespeed ;;
            4) return ;;
            0) return ;;
        esac
    done
}

install_nginx() {
    show_header
    echo -e "${CYAN}安装Nginx${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    if command -v nginx &>/dev/null; then
        local nginx_version=$(nginx -v 2>&1 | cut -d'/' -f2)
        echo -e "当前已安装: ${GREEN}Nginx $nginx_version${NC}"
        echo ""
        
        if ! show_yesno "是否重新安装Nginx？"; then
            return
        fi
    fi
    
    if ! show_yesno "是否安装Nginx Web服务器？"; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}安装Nginx...${NC}"
    apt-get update -y
    apt-get install -y nginx
    
    systemctl enable nginx
    systemctl start nginx
    
    echo ""
    echo -e "${GREEN}✓ Nginx安装完成！${NC}"
    echo ""
    echo -e "${YELLOW}默认网站目录: /var/www/html${NC}"
    echo -e "${YELLOW}配置文件目录: /etc/nginx${NC}"
    echo -e "${YELLOW}访问地址: http://服务器IP${NC}"
    
    log "Nginx安装完成"
    read -p "按回车键继续..."
}

install_apache() {
    show_header
    echo -e "${CYAN}安装Apache2${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    if command -v apache2 &>/dev/null; then
        local apache_version=$(apache2 -v | grep "Server version" | cut -d'/' -f2)
        echo -e "当前已安装: ${GREEN}Apache $apache_version${NC}"
        echo ""
        
        if ! show_yesno "是否重新安装Apache2？"; then
            return
        fi
    fi
    
    if ! show_yesno "是否安装Apache2 Web服务器？"; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}安装Apache2...${NC}"
    apt-get update -y
    apt-get install -y apache2
    
    systemctl enable apache2
    systemctl start apache2
    
    echo ""
    echo -e "${GREEN}✓ Apache2安装完成！${NC}"
    echo ""
    echo -e "${YELLOW}默认网站目录: /var/www/html${NC}"
    echo -e "${YELLOW}配置文件目录: /etc/apache2${NC}"
    echo -e "${YELLOW}访问地址: http://服务器IP${NC}"
    
    log "Apache2安装完成"
    read -p "按回车键继续..."
}

# ====================== 数据库安装 ======================

install_database_menu() {
    while true; do
        choice=$(show_menu "安装数据库" \
            "安装MySQL" \
            "安装MariaDB" \
            "安装PostgreSQL" \
            "安装Redis" \
            "安装MongoDB" \
            "返回主菜单")
        
        case $choice in
            1) install_mysql ;;
            2) install_mariadb ;;
            3) install_postgresql ;;
            4) install_redis ;;
            5) install_mongodb ;;
            6) return ;;
            0) return ;;
        esac
    done
}

install_mysql() {
    show_header
    echo -e "${CYAN}安装MySQL${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    if command -v mysql &>/dev/null; then
        echo -e "当前已安装: ${GREEN}MySQL${NC}"
        echo ""
        
        if ! show_yesno "是否重新安装MySQL？"; then
            return
        fi
    fi
    
    if ! show_yesno "是否安装MySQL数据库？"; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}安装MySQL...${NC}"
    apt-get update -y
    apt-get install -y mysql-server
    
    systemctl enable mysql
    systemctl start mysql
    
    # 运行安全脚本
    echo ""
    if show_yesno "是否运行MySQL安全配置脚本？"; then
        mysql_secure_installation
    fi
    
    echo ""
    echo -e "${GREEN}✓ MySQL安装完成！${NC}"
    echo ""
    echo -e "${YELLOW}配置文件: /etc/mysql/mysql.conf.d/mysqld.cnf${NC}"
    echo -e "${YELLOW}数据目录: /var/lib/mysql${NC}"
    echo -e "${YELLOW}默认端口: 3306${NC}"
    
    log "MySQL安装完成"
    read -p "按回车键继续..."
}

install_mariadb() {
    show_header
    echo -e "${CYAN}安装MariaDB${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    if command -v mariadb &>/dev/null; then
        echo -e "当前已安装: ${GREEN}MariaDB${NC}"
        echo ""
        
        if ! show_yesno "是否重新安装MariaDB？"; then
            return
        fi
    fi
    
    if ! show_yesno "是否安装MariaDB数据库？"; then
        return
    fi
    
    echo ""
    echo -e "${BLUE}安装MariaDB...${NC}"
    apt-get update -y
    apt-get install -y mariadb-server
    
    systemctl enable mariadb
    systemctl start mariadb
    
    # 运行安全脚本
    echo ""
    if show_yesno "是否运行MariaDB安全配置脚本？"; then
        mysql_secure_installation
    fi
    
    echo ""
    echo -e "${GREEN}✓ MariaDB安装完成！${NC}"
    echo ""
    echo -e "${YELLOW}配置文件: /etc/mysql/mariadb.conf.d/50-server.cnf${NC}"
    echo -e "${YELLOW}数据目录: /var/lib/mysql${NC}"
    echo -e "${YELLOW}默认端口: 3306${NC}"
    
    log "MariaDB安装完成"
    read -p "按回车键继续..."
}

# ====================== 服务管理 ======================

service_management_menu() {
    while true; do
        choice=$(show_menu "服务管理" \
            "查看服务状态" \
            "启动服务" \
            "停止服务" \
            "重启服务" \
            "设置开机自启" \
            "查看服务日志" \
            "返回主菜单")
        
        case $choice in
            1) show_service_status ;;
            2) start_service ;;
            3) stop_service ;;
            4) restart_service ;;
            5) enable_service ;;
            6) show_service_logs ;;
            7) return ;;
            0) return ;;
        esac
    done
}

show_service_status() {
    show_header
    echo -e "${CYAN}服务状态${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    local services=(
        "docker" "Docker"
        "1panel" "1Panel"
        "nginx" "Nginx"
        "apache2" "Apache"
        "mysql" "MySQL"
        "mariadb" "MariaDB"
        "postgresql" "PostgreSQL"
        "redis" "Redis"
        "ssh" "SSH"
        "chronyd" "时间同步"
        "ufw" "防火墙"
    )
    
    for ((i=0; i<${#services[@]}; i+=2)); do
        local service="${services[i]}"
        local name="${services[i+1]}"
        
        if systemctl list-unit-files | grep -q "${service}.service"; then
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
    local ports=(22 80 443 3306 5432 6379 9090 8888)
    for port in "${ports[@]}"; do
        if ss -tulpn | grep -q ":$port "; then
            echo -e "  ${GREEN}✓ 端口 $port: 已监听${NC}"
        else
            echo -e "  ${YELLOW}⚠ 端口 $port: 未监听${NC}"
        fi
    done
    
    read -p "按回车键继续..."
}

start_service() {
    show_header
    echo -e "${CYAN}启动服务${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    echo "可管理的服务："
    systemctl list-unit-files --type=service | grep -E "(docker|nginx|apache|mysql|mariadb|postgresql|redis|ssh|chrony)" | awk '{print "  " $1}'
    echo ""
    
    read -p "请输入要启动的服务名称: " service
    
    if [ -z "$service" ]; then
        error "服务名称不能为空"
        sleep 2
        return
    fi
    
    echo -e "${BLUE}启动 $service...${NC}"
    systemctl start "$service" 2>/dev/null
    
    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}✓ $service 启动成功${NC}"
    else
        error "$service 启动失败"
    fi
    
    read -p "按回车键继续..."
}

# ====================== 系统监控 ======================

system_monitor_menu() {
    while true; do
        choice=$(show_menu "系统监控" \
            "查看系统资源" \
            "查看进程列表" \
            "查看磁盘使用" \
            "查看网络连接" \
            "查看系统日志" \
            "性能测试" \
            "返回主菜单")
        
        case $choice in
            1) show_system_resources ;;
            2) show_process_list ;;
            3) show_disk_usage ;;
            4) show_network_connections ;;
            5) show_system_logs ;;
            6) performance_test ;;
            7) return ;;
            0) return ;;
        esac
    done
}

show_system_resources() {
    show_header
    echo -e "${CYAN}系统资源使用${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    echo -e "${BLUE}CPU使用率：${NC}"
    echo "  $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
    
    echo -e "${BLUE}内存使用：${NC}"
    free -h | awk '/^Mem:/ {print "  总量: " $2, "已用: " $3, "剩余: " $4}'
    
    echo -e "${BLUE}磁盘使用：${NC}"
    df -h / | awk 'NR==2 {print "  总量: " $2, "已用: " $3, "剩余: " $4, "使用率: " $5}'
    
    echo -e "${BLUE}系统负载：${NC}"
    uptime | awk -F': ' '{print $2}'
    
    echo -e "${BLUE}运行时间：${NC}"
    uptime -p
    
    read -p "按回车键继续..."
}

# ====================== 其他功能 ======================

show_log_menu() {
    show_header
    echo -e "${CYAN}查看日志${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    if [ -f "$INSTALL_LOG" ]; then
        echo -e "${BLUE}安装日志 (最后50行)：${NC}"
        echo "────────────────────────────────────────────────────────────────────────────────"
        tail -50 "$INSTALL_LOG"
        echo "────────────────────────────────────────────────────────────────────────────────"
        
        echo ""
        if show_yesno "是否查看完整日志？"; then
            less "$INSTALL_LOG"
        fi
    else
        error "日志文件不存在"
    fi
    
    read -p "按回车键继续..."
}

exit_program() {
    show_header
    echo -e "${CYAN}退出程序${NC}"
    echo "══════════════════════════════════════════════════════════════════════════════"
    
    if show_yesno "确定要退出吗？"; then
        echo ""
        echo -e "${GREEN}感谢使用服务器部署工具！${NC}"
        echo -e "${YELLOW}日志文件: $INSTALL_LOG${NC}"
        echo ""
        fix_terminal
        exit 0
    fi
}

# ====================== 主程序 ======================

main() {
    # 初始化
    init_log_system
    log "脚本开始执行 v$SCRIPT_VERSION"
    
    # 检查权限
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}请使用root权限运行此脚本${NC}"
        echo "使用: sudo bash $0"
        exit 1
    fi
    
    # 设置信号处理
    trap 'echo -e "\n${RED}脚本被中断${NC}"; fix_terminal; exit 1' INT TERM
    
    # 显示主菜单
    main_menu
}

# 启动程序
main "$@"

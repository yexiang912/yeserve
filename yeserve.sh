#!/bin/bash

# =============================================
# Ubuntu 服务器一键部署脚本 (增强版 v3.1)
# 作者: yx原创
# 版本: 3.1 (修复显示问题，新增自选安装)
# =============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# 全局变量
SCRIPT_VERSION="3.1"
SCRIPT_NAME="yx-deploy"
BACKUP_DIR="/backup/${SCRIPT_NAME}"
LOG_DIR="/var/log/${SCRIPT_NAME}"
INSTALL_LOG="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
SELECTED_PACKAGES=()

# ====================== 进度条配置 ======================
PROGRESS_STYLE="bar"  # 默认使用条形进度条，显示剩余时间
SHOW_PROGRESS=true
PROGRESS_WIDTH=50

# ====================== 日志系统 ======================

# 初始化日志系统
init_log_system() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    mkdir -p "$BACKUP_DIR" 2>/dev/null
    touch "$INSTALL_LOG" 2>/dev/null
    exec > >(tee -a "$INSTALL_LOG") 2>&1
}

# 日志函数
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

# 命令状态检查
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

# 检查命令是否存在
check_command() {
    local cmd="$1"
    local package="$2"
    
    if ! command -v "$cmd" &>/dev/null; then
        warn "命令 $cmd 未找到"
        if [ -n "$package" ]; then
            read -p "是否安装 $package？(y/N): " -n 1 confirm
            echo
            if [[ $confirm =~ ^[Yy]$ ]]; then
                apt-get install -y "$package" >/dev/null 2>&1
                check_status "已安装 $package" "安装 $package 失败"
            fi
        fi
        return 1
    fi
    return 0
}

# ====================== 基础检查函数 ======================

# 检查sudo权限
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log "使用root权限运行"
        return 0
    fi
    
    info "检测到非root用户，尝试使用sudo..."
    
    # 检查sudo是否可用
    if ! command -v sudo &>/dev/null; then
        error "未找到sudo命令，请以root用户运行此脚本"
        echo -e "${YELLOW}可以使用以下方式：${NC}"
        echo "1. sudo bash $0"
        echo "2. su - root"
        echo "3. 切换到root用户"
        exit 1
    fi
    
    # 检查sudo权限
    if ! sudo -n true 2>/dev/null; then
        echo -e "${YELLOW}需要sudo权限来运行此脚本${NC}"
        echo "请输入密码继续..."
        sudo echo "sudo权限检查通过" || {
            error "sudo权限验证失败"
            exit 1
        }
    fi
    
    # 重新以sudo运行
    warn "重新以sudo权限运行脚本..."
    exec sudo bash "$0" "$@"
}

# 检测系统版本（增强版）
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

# 显示标题
show_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║          Ubuntu 服务器部署脚本 v$SCRIPT_VERSION           ║"
    echo "║              增强版 - 稳定可靠                           ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

# 确认执行
confirm_execution() {
    show_header
    echo -e "${YELLOW}⚠  警告：本脚本将修改系统配置并安装软件${NC}"
    echo -e "${YELLOW}请确保您已经备份重要数据${NC}"
    echo ""
    echo -e "${CYAN}日志文件: ${INSTALL_LOG}${NC}"
    echo -e "${CYAN}备份目录: ${BACKUP_DIR}${NC}"
    echo ""
    echo -e "${WHITE}按 Ctrl+C 取消执行${NC}"
    echo ""
    read -p "是否继续执行？(y/N): " -n 1 start_confirm
    echo
    if [[ ! $start_confirm =~ ^[Yy]$ ]]; then
        log "用户取消执行"
        exit 0
    fi
}

# 检查必要工具
check_required_tools() {
    info "检查必要工具..."
    
    local tools=("curl" "wget" "grep" "awk" "sed" "cut")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        warn "缺少必要工具: ${missing[*]}"
        info "正在安装缺失工具..."
        
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

# ====================== 增强版进度条函数 ======================

# 智能进度监控
smart_progress_monitor() {
    local pid=$1
    local desc="$2"
    local estimated_time="${3:-60}"
    
    if [ "$SHOW_PROGRESS" = false ]; then
        wait "$pid"
        return $?
    fi
    
    echo -e "${CYAN}[信息] ${desc}${NC}"
    
    case $PROGRESS_STYLE in
        "bar")
            show_enhanced_bar_progress "$pid" "$desc" "$estimated_time"
            ;;
        "dots")
            show_dots_progress "$pid" "$desc"
            ;;
        "spinner")
            show_spinner_progress "$pid" "$desc"
            ;;
        "pulse")
            show_pulse_progress "$pid" "$desc"
            ;;
        "rainbow")
            show_rainbow_progress "$pid" "$desc"
            ;;
        *)
            show_enhanced_bar_progress "$pid" "$desc" "$estimated_time"
            ;;
    esac
    
    wait "$pid"
    return $?
}

# 增强版条形进度条
show_enhanced_bar_progress() {
    local pid=$1
    local desc="$2"
    local initial_estimate="$3"
    local width=$PROGRESS_WIDTH
    local start_time=$(date +%s)
    local max_extensions=5
    local extensions=0
    
    while kill -0 "$pid" 2>/dev/null; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        
        # 动态调整预计时间
        if [ $elapsed -gt $initial_estimate ] && [ $extensions -lt $max_extensions ]; then
            initial_estimate=$((initial_estimate + 30))
            extensions=$((extensions + 1))
        fi
        
        local progress=$((elapsed * width / initial_estimate))
        [ $progress -gt $width ] && progress=$width
        
        local bar=""
        for ((i=0; i<progress; i++)); do
            bar="${bar}█"
        done
        for ((i=progress; i<width; i++)); do
            bar="${bar}░"
        done
        
        local percentage=$((elapsed * 100 / initial_estimate))
        [ $percentage -gt 100 ] && percentage=100
        
        local remaining=$((initial_estimate - elapsed))
        [ $remaining -lt 0 ] && remaining=0
        
        # 颜色设置
        if [ $percentage -lt 30 ]; then
            bar_color=$BLUE
        elif [ $percentage -lt 70 ]; then
            bar_color=$YELLOW
        else
            bar_color=$GREEN
        fi
        
        printf "\r[${bar_color}${bar}${NC}] ${CYAN}%3d%%${NC} ${YELLOW}剩余: %02d:%02d${NC}" \
            $percentage $((remaining/60)) $((remaining%60))
        
        sleep 1
    done
    
    local end_time=$(date +%s)
    local actual_time=$((end_time - start_time))
    
    # 完成显示
    bar=""
    for ((i=0; i<width; i++)); do
        bar="${bar}█"
    done
    
    printf "\r[${GREEN}${bar}${NC}] ${GREEN}100%%${NC} ${GREEN}耗时: %02d:%02d${NC}\n" \
        $((actual_time/60)) $((actual_time%60))
}

# 点状进度条
show_dots_progress() {
    local pid=$1
    local desc="$2"
    echo -ne "${CYAN}[信息] ${desc}${NC}"
    
    local dots=""
    while kill -0 "$pid" 2>/dev/null; do
        if [ ${#dots} -lt 3 ]; then
            dots="${dots}."
        else
            dots=""
        fi
        echo -ne "\r${CYAN}[信息] ${desc}${dots}   ${NC}"
        sleep 0.5
    done
    echo -e "\r${GREEN}[信息] ${desc}完成 ✓${NC}   "
}

# 旋转器进度条
show_spinner_progress() {
    local pid=$1
    local desc="$2"
    echo -ne "${CYAN}[信息] ${desc}${NC}"
    
    local spinstr='|/-\'
    while kill -0 "$pid" 2>/dev/null; do
        local temp=${spinstr#?}
        printf "\r${CYAN}[信息] ${desc} %c ${NC}" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep 0.1
    done
    printf "\r${GREEN}[信息] ${desc}完成 ✓${NC}    \n"
}

# 脉冲进度条
show_pulse_progress() {
    local pid=$1
    local desc="$2"
    echo -ne "${CYAN}[信息] ${desc}${NC}"
    
    local pulse_count=0
    while kill -0 "$pid" 2>/dev/null; do
        local pulses=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█" "▇" "▆" "▅" "▄" "▃" "▂")
        local pulse=${pulses[$((pulse_count % ${#pulses[@]}))]}
        printf "\r${CYAN}[信息] ${desc} %s ${NC}" "$pulse"
        pulse_count=$((pulse_count + 1))
        sleep 0.2
    done
    echo -e "\r${GREEN}[信息] ${desc}完成 ✓${NC}      "
}

# 彩虹进度条
show_rainbow_progress() {
    local pid=$1
    local desc="$2"
    echo -ne "${CYAN}[信息] ${desc}${NC}"
    
    local colors=($RED $YELLOW $GREEN $CYAN $BLUE $PURPLE)
    local color_index=0
    while kill -0 "$pid" 2>/dev/null; do
        local color=${colors[$color_index]}
        printf "\r${CYAN}[信息] ${desc}${color}▶${NC}  "
        color_index=$(( (color_index + 1) % ${#colors[@]} ))
        sleep 0.2
    done
    echo -e "\r${GREEN}[信息] ${desc}完成 ✓${NC}    "
}

# 演示进度条样式
demo_progress_styles() {
    echo -e "${PURPLE}[演示] 进度条样式演示${NC}"
    echo "══════════════════════════════════════════════"
    
    local styles=("dots" "spinner" "bar" "pulse" "rainbow")
    local style_names=("点状进度条" "旋转器进度条" "条形进度条" "脉冲进度条" "彩虹进度条")
    
    for i in {0..4}; do
        echo -e "\n${CYAN}$((i+1)). ${style_names[i]}${NC}"
        
        local saved_style=$PROGRESS_STYLE
        PROGRESS_STYLE="${styles[i]}"
        
        # 模拟一个任务
        (
            sleep 3
        ) &
        
        smart_progress_monitor $! "演示任务" 3
        PROGRESS_STYLE="$saved_style"
        
        sleep 1
    done
    
    echo -e "\n${GREEN}[演示] 所有进度条样式演示完成！${NC}"
}

# 设置进度条样式菜单
set_progress_style_menu() {
    while true; do
        show_header
        
        echo -e "${CYAN}进度条样式设置${NC}"
        echo "══════════════════════════════════════════════"
        echo -e "当前样式: ${GREEN}$PROGRESS_STYLE${NC}"
        echo -e "进度条显示: ${GREEN}$([ "$SHOW_PROGRESS" = true ] && echo "启用" || echo "禁用")${NC}"
        echo ""
        echo "请选择进度条样式："
        echo "1. 点状进度条 (dots)"
        echo "2. 旋转器进度条 (spinner)"
        echo "3. 条形进度条 (bar) - 推荐"
        echo "4. 脉冲进度条 (pulse)"
        echo "5. 彩虹进度条 (rainbow)"
        echo "6. $( [ "$SHOW_PROGRESS" = true ] && echo "禁用" || echo "启用" )进度条显示"
        echo "7. 测试当前样式"
        echo "8. 返回主菜单"
        echo ""
        
        read -p "请输入选择 (1-8): " style_choice
        
        case $style_choice in
            1) PROGRESS_STYLE="dots" ; log "已设置为点状进度条样式" ;;
            2) PROGRESS_STYLE="spinner" ; log "已设置为旋转器进度条样式" ;;
            3) PROGRESS_STYLE="bar" ; log "已设置为条形进度条样式" ;;
            4) PROGRESS_STYLE="pulse" ; log "已设置为脉冲进度条样式" ;;
            5) PROGRESS_STYLE="rainbow" ; log "已设置为彩虹进度条样式" ;;
            6)
                if [ "$SHOW_PROGRESS" = true ]; then
                    SHOW_PROGRESS=false
                    log "已禁用进度条显示"
                else
                    SHOW_PROGRESS=true
                    log "已启用进度条显示"
                fi
                ;;
            7)
                echo -e "\n${CYAN}测试当前样式...${NC}"
                (
                    sleep 3
                ) &
                smart_progress_monitor $! "测试任务" 3
                ;;
            8) return 0 ;;
            *) error "无效选择！" ;;
        esac
        
        echo ""
        read -p "按回车键继续..."
    done
}

# ====================== 系统优化函数 ======================

# 备份配置文件
backup_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        local backup_file="${BACKUP_DIR}/$(basename "$config_file").$(date +%Y%m%d_%H%M%S).bak"
        cp "$config_file" "$backup_file" 2>/dev/null
        log "已备份 $config_file"
    fi
}

# 系统优化配置
system_optimization() {
    info "开始系统优化配置..."
    
    # 更新软件包列表
    info "更新软件包列表..."
    apt-get update -y > /dev/null 2>&1 &
    smart_progress_monitor $! "更新软件包列表" 30
    
    # 安装必要软件
    info "安装必要软件..."
    local packages=(
        curl wget vim git net-tools htop iftop iotop screen tmux ufw
        ntpdate software-properties-common apt-transport-https ca-certificates
        gnupg lsb-release chrony build-essential pkg-config
    )
    
    apt-get install -y "${packages[@]}" > /dev/null 2>&1 &
    smart_progress_monitor $! "安装必要软件" 120
    
    # 设置时区
    info "设置时区..."
    timedatectl set-timezone Asia/Shanghai
    check_status "时区设置为上海" "时区设置失败"
    
    # 配置时间同步
    info "配置时间同步..."
    systemctl stop systemd-timesyncd 2>/dev/null || true
    systemctl disable systemd-timesyncd 2>/dev/null || true
    systemctl restart chronyd 2>/dev/null &
    smart_progress_monitor $! "配置时间同步" 10
    
    # 配置SSH安全
    info "配置SSH安全..."
    if [ -f "/etc/ssh/sshd_config" ]; then
        backup_config "/etc/ssh/sshd_config"
        
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config 2>/dev/null || true
        
        systemctl restart sshd 2>/dev/null &
        smart_progress_monitor $! "重启SSH服务" 5
    fi
    
    # 配置防火墙
    info "配置防火墙..."
    ufw --force disable 2>/dev/null
    check_status "防火墙已禁用" "防火墙配置失败"
    
    # 优化内核参数
    info "优化内核参数..."
    backup_config "/etc/sysctl.conf"
    
    cat >> /etc/sysctl.conf << 'EOF'
# 系统优化配置
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.default_qdisc = fq
vm.swappiness = 10
EOF
    
    # 应用内核参数
    sysctl -p > /dev/null 2>&1
    check_status "内核参数已应用" "内核参数应用失败"
    
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}          系统优化配置完成！${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    
    return 0
}

# ====================== Docker安装函数 ======================

# 检查Docker安装状态
check_docker_installed() {
    if command -v docker &>/dev/null && systemctl is-active --quiet docker 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# 安装Docker
install_docker() {
    info "开始安装Docker..."
    
    # 检查是否已安装
    if check_docker_installed; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "未知版本")
        warn "Docker已经安装，版本: $docker_version"
        
        read -p "是否重新安装？(y/N): " -n 1 reinstall_confirm
        echo
        if [[ ! $reinstall_confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # 显示安装信息
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              Docker安装信息${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo "预计安装时间: 2-3分钟"
    echo "将自动配置镜像加速器"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    # 安装Docker
    info "安装Docker..."
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun > /tmp/docker_install.log 2>&1 &
    
    smart_progress_monitor $! "安装Docker" 180
    
    # 检查安装结果
    if check_docker_installed; then
        log "✅ Docker安装成功！"
        
        # 配置镜像加速器
        info "配置Docker镜像加速器..."
        mkdir -p /etc/docker
        cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
EOF
        
        # 重启Docker
        systemctl restart docker
        systemctl enable docker
        
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo -e "${GREEN}           Docker安装完成！${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        
        return 0
    else
        error "❌ Docker安装失败！"
        return 1
    fi
}

# ====================== 面板安装函数 ======================

# 安装宝塔面板
install_baota() {
    info "开始安装宝塔面板..."
    
    # 检查是否已安装
    if [ -f "/etc/init.d/bt" ]; then
        warn "宝塔面板已经安装！"
        read -p "是否重新安装？(y/N): " -n 1 reinstall_confirm
        echo
        if [[ ! $reinstall_confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # 显示安装信息
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           宝塔面板安装信息${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo "预计安装时间: 5-8分钟"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "按回车键开始安装，或按 Ctrl+C 取消..." 
    
    # 安装宝塔面板
    info "安装宝塔面板..."
    if command -v curl &>/dev/null; then
        curl -sSO https://download.bt.cn/install/install_panel.sh
    else
        wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh
    fi
    
    bash install_panel.sh ed8484bec > /tmp/baota_install.log 2>&1 &
    
    smart_progress_monitor $! "安装宝塔面板" 480
    
    # 检查安装结果
    if [ -f "/etc/init.d/bt" ]; then
        sleep 5
        /etc/init.d/bt start 2>/dev/null
        
        log "✅ 宝塔面板安装成功！"
        
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo -e "${GREEN}           宝塔面板安装完成！${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        
        return 0
    else
        error "❌ 宝塔面板安装失败！"
        return 1
    fi
}

# 安装1Panel面板
install_1panel() {
    info "开始安装1Panel面板..."
    
    # 检查是否已安装
    if systemctl list-unit-files | grep -q "1panel" || command -v 1pctl &>/dev/null; then
        warn "1Panel面板已经安装！"
        read -p "是否重新安装？(y/N): " -n 1 reinstall_confirm
        echo
        if [[ ! $reinstall_confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # 显示安装信息
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           1Panel面板安装信息${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo "预计安装时间: 3-5分钟"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "按回车键开始安装，或按 Ctrl+C 取消..." 
    
    # 安装1Panel面板
    info "安装1Panel面板..."
    curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh -o quick_start.sh
    bash quick_start.sh > /tmp/1panel_install.log 2>&1 &
    
    smart_progress_monitor $! "安装1Panel面板" 300
    
    # 检查安装结果
    sleep 5
    if systemctl list-unit-files | grep -q "1panel"; then
        log "✅ 1Panel面板安装成功！"
        
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo -e "${GREEN}           1Panel面板安装完成！${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        
        return 0
    else
        error "❌ 1Panel面板安装失败！"
        return 1
    fi
}

# ====================== Web服务器安装函数 ======================

# 安装Nginx
install_nginx() {
    info "开始安装Nginx..."
    
    if command -v nginx &>/dev/null; then
        warn "Nginx已经安装"
        read -p "是否重新安装？(y/N): " -n 1 confirm
        echo
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    apt-get update -y >/dev/null 2>&1
    apt-get install -y nginx >/dev/null 2>&1 &
    
    smart_progress_monitor $! "安装Nginx" 60
    
    systemctl enable nginx
    systemctl start nginx
    
    check_status "Nginx安装成功" "Nginx安装失败"
}

# 安装Apache
install_apache() {
    info "开始安装Apache..."
    
    if command -v apache2 &>/dev/null; then
        warn "Apache已经安装"
        read -p "是否重新安装？(y/N): " -n 1 confirm
        echo
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    apt-get update -y >/dev/null 2>&1
    apt-get install -y apache2 >/dev/null 2>&1 &
    
    smart_progress_monitor $! "安装Apache" 60
    
    systemctl enable apache2
    systemctl start apache2
    
    check_status "Apache安装成功" "Apache安装失败"
}

# ====================== 数据库安装函数 ======================

# 安装MySQL
install_mysql() {
    info "开始安装MySQL..."
    
    if command -v mysql &>/dev/null; then
        warn "MySQL已经安装"
        read -p "是否重新安装？(y/N): " -n 1 confirm
        echo
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    apt-get update -y >/dev/null 2>&1
    apt-get install -y mysql-server >/dev/null 2>&1 &
    
    smart_progress_monitor $! "安装MySQL" 120
    
    systemctl enable mysql
    systemctl start mysql
    
    check_status "MySQL安装成功" "MySQL安装失败"
}

# 安装PostgreSQL
install_postgresql() {
    info "开始安装PostgreSQL..."
    
    if command -v psql &>/dev/null; then
        warn "PostgreSQL已经安装"
        read -p "是否重新安装？(y/N): " -n 1 confirm
        echo
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    apt-get update -y >/dev/null 2>&1
    apt-get install -y postgresql postgresql-contrib >/dev/null 2>&1 &
    
    smart_progress_monitor $! "安装PostgreSQL" 90
    
    systemctl enable postgresql
    systemctl start postgresql
    
    check_status "PostgreSQL安装成功" "PostgreSQL安装失败"
}

# ====================== 清理函数 ======================

# 卸载Docker
uninstall_docker() {
    warn "开始卸载Docker..."
    
    read -p "确定要卸载Docker吗？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "取消卸载"
        return 0
    fi
    
    systemctl stop docker
    apt-get purge -y docker-ce docker-ce-cli containerd.io
    rm -rf /var/lib/docker
    
    log "Docker卸载完成"
}

# 卸载宝塔面板
uninstall_baota() {
    warn "开始卸载宝塔面板..."
    
    read -p "确定要卸载宝塔面板吗？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "取消卸载"
        return 0
    fi
    
    if [ -f "/www/server/panel/install.sh" ]; then
        bash /www/server/panel/install.sh uninstall
    fi
    
    log "宝塔面板卸载完成"
}

# 卸载1Panel面板
uninstall_1panel() {
    warn "开始卸载1Panel面板..."
    
    read -p "确定要卸载1Panel面板吗？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "取消卸载"
        return 0
    fi
    
    if command -v 1pctl &>/dev/null; then
        1pctl uninstall
    fi
    
    log "1Panel面板卸载完成"
}

# ====================== 自选安装功能 ======================

# 显示安装选项菜单
show_selection_menu() {
    local title="$1"
    local options=("${!2}")
    local descriptions=("${!3}")
    
    echo -e "${CYAN}$title${NC}"
    echo "══════════════════════════════════════════════"
    
    for i in "${!options[@]}"; do
        echo "$((i+1)). ${options[i]} - ${descriptions[i]}"
    done
    echo "$((${#options[@]}+1)). 全选"
    echo "$((${#options[@]}+2)). 继续安装"
    echo "$((${#options[@]}+3)). 取消"
    echo ""
}

# 自选安装功能
custom_installation() {
    while true; do
        show_header
        echo -e "${CYAN}          自选安装功能${NC}"
        echo "══════════════════════════════════════════════"
        echo ""
        
        # 定义安装选项
        local categories=("系统工具" "Web服务器" "数据库" "开发工具" "其他")
        local selected_category=""
        
        # 选择分类
        echo "请选择分类："
        for i in "${!categories[@]}"; do
            echo "$((i+1)). ${categories[i]}"
        done
        echo "6. 开始安装"
        echo "7. 返回主菜单"
        echo ""
        
        read -p "请输入选择 (1-7): " category_choice
        
        case $category_choice in
            1) # 系统工具
                show_system_tools_menu
                ;;
            2) # Web服务器
                show_webserver_menu
                ;;
            3) # 数据库
                show_database_menu
                ;;
            4) # 开发工具
                show_dev_tools_menu
                ;;
            5) # 其他
                show_other_tools_menu
                ;;
            6) # 开始安装
                if [ ${#SELECTED_PACKAGES[@]} -eq 0 ]; then
                    warn "未选择任何安装项目！"
                    sleep 2
                    continue
                fi
                execute_selected_installations
                return 0
                ;;
            7) # 返回主菜单
                return 0
                ;;
            *)
                error "无效选择！"
                sleep 2
                ;;
        esac
    done
}

# 系统工具菜单
show_system_tools_menu() {
    local options=("htop" "iftop" "iotop" "tmux" "screen" "ncdu" "tree" "ranger")
    local descriptions=("进程监控" "网络流量监控" "磁盘IO监控" "终端复用器" "终端复用器" "磁盘使用分析" "目录树显示" "文件管理器")
    
    while true; do
        show_header
        show_selection_menu "系统工具选择" options[@] descriptions[@]
        
        read -p "请输入选择 (1-$((${#options[@]}+3))): " choice
        
        if [ "$choice" -eq $((${#options[@]}+1)) ]; then
            # 全选
            SELECTED_PACKAGES+=("${options[@]}")
            log "已选择所有系统工具"
        elif [ "$choice" -eq $((${#options[@]}+2)) ]; then
            # 继续安装
            break
        elif [ "$choice" -eq $((${#options[@]}+3)) ]; then
            # 取消
            return
        elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#options[@]} ]; then
            local selected="${options[$((choice-1))]}"
            if [[ ! " ${SELECTED_PACKAGES[@]} " =~ " ${selected} " ]]; then
                SELECTED_PACKAGES+=("$selected")
                log "已选择: $selected"
            else
                warn "$selected 已选择"
            fi
        else
            error "无效选择！"
        fi
        
        sleep 1
    done
}

# Web服务器菜单
show_webserver_menu() {
    local options=("nginx" "apache2" "lighttpd" "openresty")
    local descriptions=("高性能Web服务器" "经典Web服务器" "轻量级Web服务器" "Nginx增强版")
    
    while true; do
        show_header
        show_selection_menu "Web服务器选择" options[@] descriptions[@]
        
        read -p "请输入选择 (1-$((${#options[@]}+3))): " choice
        
        if [ "$choice" -eq $((${#options[@]}+1)) ]; then
            SELECTED_PACKAGES+=("${options[@]}")
            log "已选择所有Web服务器"
        elif [ "$choice" -eq $((${#options[@]}+2)) ]; then
            break
        elif [ "$choice" -eq $((${#options[@]}+3)) ]; then
            return
        elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#options[@]} ]; then
            local selected="${options[$((choice-1))]}"
            if [[ ! " ${SELECTED_PACKAGES[@]} " =~ " ${selected} " ]]; then
                SELECTED_PACKAGES+=("$selected")
                log "已选择: $selected"
            else
                warn "$selected 已选择"
            fi
        else
            error "无效选择！"
        fi
        
        sleep 1
    done
}

# 数据库菜单
show_database_menu() {
    local options=("mysql-server" "postgresql" "redis" "mongodb" "sqlite3")
    local descriptions=("MySQL数据库" "PostgreSQL数据库" "Redis缓存" "MongoDB数据库" "SQLite数据库")
    
    while true; do
        show_header
        show_selection_menu "数据库选择" options[@] descriptions[@]
        
        read -p "请输入选择 (1-$((${#options[@]}+3))): " choice
        
        if [ "$choice" -eq $((${#options[@]}+1)) ]; then
            SELECTED_PACKAGES+=("${options[@]}")
            log "已选择所有数据库"
        elif [ "$choice" -eq $((${#options[@]}+2)) ]; then
            break
        elif [ "$choice" -eq $((${#options[@]}+3)) ]; then
            return
        elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#options[@]} ]; then
            local selected="${options[$((choice-1))]}"
            if [[ ! " ${SELECTED_PACKAGES[@]} " =~ " ${selected} " ]]; then
                SELECTED_PACKAGES+=("$selected")
                log "已选择: $selected"
            else
                warn "$selected 已选择"
            fi
        else
            error "无效选择！"
        fi
        
        sleep 1
    done
}

# 开发工具菜单
show_dev_tools_menu() {
    local options=("git" "vim" "build-essential" "python3-pip" "nodejs" "npm" "docker-compose" "jq")
    local descriptions=("版本控制" "文本编辑器" "编译工具链" "Python包管理" "Node.js运行环境" "Node包管理" "Docker编排工具" "JSON处理器")
    
    while true; do
        show_header
        show_selection_menu "开发工具选择" options[@] descriptions[@]
        
        read -p "请输入选择 (1-$((${#options[@]}+3))): " choice
        
        if [ "$choice" -eq $((${#options[@]}+1)) ]; then
            SELECTED_PACKAGES+=("${options[@]}")
            log "已选择所有开发工具"
        elif [ "$choice" -eq $((${#options[@]}+2)) ]; then
            break
        elif [ "$choice" -eq $((${#options[@]}+3)) ]; then
            return
        elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#options[@]} ]; then
            local selected="${options[$((choice-1))]}"
            if [[ ! " ${SELECTED_PACKAGES[@]} " =~ " ${selected} " ]]; then
                SELECTED_PACKAGES+=("$selected")
                log "已选择: $selected"
            else
                warn "$selected 已选择"
            fi
        else
            error "无效选择！"
        fi
        
        sleep 1
    done
}

# 其他工具菜单
show_other_tools_menu() {
    local options=("fail2ban" "ufw" "logrotate" "backupninja" "cockpit" "webmin")
    local descriptions=("防暴力破解" "防火墙管理" "日志轮转" "备份工具" "Web管理面板" "Web管理面板")
    
    while true; do
        show_header
        show_selection_menu "其他工具选择" options[@] descriptions[@]
        
        read -p "请输入选择 (1-$((${#options[@]}+3))): " choice
        
        if [ "$choice" -eq $((${#options[@]}+1)) ]; then
            SELECTED_PACKAGES+=("${options[@]}")
            log "已选择所有其他工具"
        elif [ "$choice" -eq $((${#options[@]}+2)) ]; then
            break
        elif [ "$choice" -eq $((${#options[@]}+3)) ]; then
            return
        elif [ "$choice" -ge 1 ] && [ "$choice" -le ${#options[@]} ]; then
            local selected="${options[$((choice-1))]}"
            if [[ ! " ${SELECTED_PACKAGES[@]} " =~ " ${selected} " ]]; then
                SELECTED_PACKAGES+=("$selected")
                log "已选择: $selected"
            else
                warn "$selected 已选择"
            fi
        else
            error "无效选择！"
        fi
        
        sleep 1
    done
}

# 执行选择的安装
execute_selected_installations() {
    if [ ${#SELECTED_PACKAGES[@]} -eq 0 ]; then
        warn "没有选择任何安装项目"
        return
    fi
    
    info "开始安装选择的软件包..."
    echo -e "${YELLOW}选择的软件包：${NC}"
    printf "  %s\n" "${SELECTED_PACKAGES[@]}"
    echo ""
    
    read -p "确定要安装以上软件包吗？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "取消安装"
        SELECTED_PACKAGES=()
        return
    fi
    
    # 更新软件包列表
    apt-get update -y >/dev/null 2>&1
    
    # 分组安装
    local total=${#SELECTED_PACKAGES[@]}
    local installed=0
    
    for package in "${SELECTED_PACKAGES[@]}"; do
        installed=$((installed + 1))
        info "安装 $package ($installed/$total)..."
        
        apt-get install -y "$package" >/dev/null 2>&1 &
        smart_progress_monitor $! "安装 $package" 60
        
        check_status "✅ $package 安装完成" "❌ $package 安装失败"
    done
    
    success "所有选择的软件包安装完成！"
    SELECTED_PACKAGES=()
}

# ====================== 功能测试 ======================

# 测试安装功能
test_installation() {
    info "开始功能测试..."
    
    echo ""
    echo -e "${YELLOW}测试项目：${NC}"
    echo "1. 系统优化功能测试"
    echo "2. Docker安装测试"
    echo "3. 软件包安装测试"
    echo "4. 全部测试"
    echo "5. 返回主菜单"
    echo ""
    
    read -p "请选择测试项目 (1-5): " test_choice
    
    case $test_choice in
        1)
            test_system_optimization
            ;;
        2)
            test_docker_installation
            ;;
        3)
            test_package_installation
            ;;
        4)
            test_system_optimization
            test_docker_installation
            test_package_installation
            ;;
        5)
            return
            ;;
        *)
            error "无效选择！"
            ;;
    esac
}

# 测试系统优化
test_system_optimization() {
    info "测试系统优化功能..."
    
    # 测试时区设置
    local current_tz=$(timedatectl show --property=Timezone --value)
    if [ "$current_tz" = "Asia/Shanghai" ]; then
        log "✓ 时区设置正常"
    else
        warn "⚠ 时区设置异常: $current_tz"
    fi
    
    # 测试SSH配置
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config 2>/dev/null; then
        log "✓ SSH安全配置正常"
    else
        warn "⚠ SSH安全配置未启用"
    fi
    
    # 测试内核参数
    if sysctl -n net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        log "✓ BBR拥塞控制已启用"
    else
        warn "⚠ BBR未启用"
    fi
    
    success "系统优化功能测试完成"
}

# 测试Docker安装
test_docker_installation() {
    info "测试Docker安装功能..."
    
    if command -v docker &>/dev/null; then
        log "✓ Docker命令可用"
        
        if systemctl is-active --quiet docker; then
            log "✓ Docker服务运行正常"
            
            # 测试运行容器
            if docker run --rm hello-world &>/dev/null; then
                log "✓ Docker容器运行正常"
            else
                warn "⚠ Docker容器运行测试失败"
            fi
        else
            warn "⚠ Docker服务未运行"
        fi
    else
        warn "⚠ Docker未安装"
    fi
    
    success "Docker安装功能测试完成"
}

# 测试软件包安装
test_package_installation() {
    info "测试软件包安装功能..."
    
    local test_packages=("curl" "wget" "vim")
    local failed=()
    
    for pkg in "${test_packages[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            log "✓ $pkg 已安装"
        else
            warn "⚠ $pkg 未安装"
            failed+=("$pkg")
        fi
    done
    
    if [ ${#failed[@]} -eq 0 ]; then
        success "所有测试软件包均已安装"
    else
        warn "以下软件包未安装: ${failed[*]}"
    fi
}

# ====================== 系统完整性检查 ======================

system_integrity_check() {
    show_header
    echo -e "${CYAN}       系统完整性检查报告${NC}"
    echo "══════════════════════════════════════════════"
    echo ""
    
    # 系统信息
    echo -e "${BLUE}1. 系统信息：${NC}"
    echo "   OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
    echo "   内核: $(uname -r)"
    echo "   架构: $(uname -m)"
    
    # 资源使用
    echo ""
    echo -e "${BLUE}2. 资源使用：${NC}"
    echo -n "   内存: "
    free -h | awk 'NR==2{print $4 " / " $2}'
    echo -n "   磁盘: "
    df -h / | awk 'NR==2{print $4 " / " $2}'
    
    # 服务状态
    echo ""
    echo -e "${BLUE}3. 服务状态：${NC}"
    local services=("docker" "nginx" "apache2" "mysql" "postgresql" "ssh")
    for svc in "${services[@]}"; do
        if systemctl list-unit-files | grep -q "$svc.service"; then
            if systemctl is-active --quiet "$svc" 2>/dev/null; then
                echo "   ✓ $svc 正在运行"
            else
                echo "   ✗ $svc 未运行"
            fi
        fi
    done
    
    echo ""
    echo "══════════════════════════════════════════════"
    echo -e "${GREEN}检查完成！${NC}"
    
    read -p "按回车键返回主菜单..."
}

# ====================== 主菜单 ======================

# 显示主菜单
main_menu() {
    while true; do
        show_header
        echo -e "${CYAN}请选择要执行的操作：${NC}"
        echo "══════════════════════════════════════════════"
        echo ""
        echo "1. 系统优化配置"
        echo "2. 安装Docker"
        echo "3. 安装面板（宝塔/1Panel）"
        echo "4. 安装Web服务器"
        echo "5. 安装数据库"
        echo "6. 自选安装（推荐）"
        echo "7. 完整安装（1+2+3）"
        echo "8. 系统完整性检查"
        echo "9. 功能测试"
        echo "10. 清理工具"
        echo "11. 演示进度条样式"
        echo "12. 设置进度条样式"
        echo "0. 退出"
        echo ""
        echo -e "${YELLOW}当前进度条样式: $PROGRESS_STYLE${NC}"
        echo -e "${YELLOW}已选择软件包: ${#SELECTED_PACKAGES[@]}个${NC}"
        echo "══════════════════════════════════════════════"
        
        read -p "请输入选择 (0-12): " choice
        
        case $choice in
            1) system_optimization ;;
            2) install_docker ;;
            3)
                echo ""
                echo "1. 安装宝塔面板"
                echo "2. 安装1Panel面板"
                echo "3. 返回"
                read -p "请选择: " panel_choice
                case $panel_choice in
                    1) install_baota ;;
                    2) install_1panel ;;
                esac
                ;;
            4)
                echo ""
                echo "1. 安装Nginx"
                echo "2. 安装Apache"
                echo "3. 返回"
                read -p "请选择: " web_choice
                case $web_choice in
                    1) install_nginx ;;
                    2) install_apache ;;
                esac
                ;;
            5)
                echo ""
                echo "1. 安装MySQL"
                echo "2. 安装PostgreSQL"
                echo "3. 返回"
                read -p "请选择: " db_choice
                case $db_choice in
                    1) install_mysql ;;
                    2) install_postgresql ;;
                esac
                ;;
            6) custom_installation ;;
            7)
                system_optimization
                install_docker
                echo ""
                echo "1. 安装宝塔面板"
                echo "2. 安装1Panel面板"
                echo "3. 跳过面板安装"
                read -p "请选择: " panel_choice
                case $panel_choice in
                    1) install_baota ;;
                    2) install_1panel ;;
                esac
                ;;
            8) system_integrity_check ;;
            9) test_installation ;;
            10)
                echo ""
                echo "1. 卸载Docker"
                echo "2. 卸载宝塔面板"
                echo "3. 卸载1Panel面板"
                echo "4. 返回"
                read -p "请选择: " cleanup_choice
                case $cleanup_choice in
                    1) uninstall_docker ;;
                    2) uninstall_baota ;;
                    3) uninstall_1panel ;;
                esac
                ;;
            11)
                demo_progress_styles
                read -p "按回车键返回主菜单..."
                ;;
            12)
                set_progress_style_menu
                ;;
            0)
                log "感谢使用！再见！"
                exit 0
                ;;
            *)
                error "无效选择！"
                sleep 2
                ;;
        esac
        
        echo ""
        read -p "操作完成，按回车键返回主菜单..."
    done
}

# ====================== 主程序 ======================

# 主函数
main() {
    # 初始化日志系统
    init_log_system
    
    # 检查sudo权限
    check_sudo "$@"
    
    # 检查必要工具
    check_required_tools
    
    # 检测系统版本
    check_ubuntu_version
    
    # 确认执行
    confirm_execution
    
    # 记录开始时间
    local start_time=$(date +%s)
    log "脚本开始执行 (v$SCRIPT_VERSION)"
    
    # 显示主菜单
    main_menu
    
    # 记录结束时间
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log "脚本执行完成，总耗时: ${duration}秒"
}

# 设置异常处理
trap 'error "脚本被中断"; echo -e "${YELLOW}日志文件: ${INSTALL_LOG}${NC}"; exit 1' INT TERM

# 执行主函数
main "$@"

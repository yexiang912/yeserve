#!/bin/bash

# =============================================
# Ubuntu 服务器一键部署脚本 (优化版 v6.0)
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
SCRIPT_VERSION="6.0"
SCRIPT_NAME="yx-deploy"
BACKUP_DIR="/backup/${SCRIPT_NAME}"
LOG_DIR="/var/log/${SCRIPT_NAME}"
INSTALL_LOG="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
AUTO_RECOVERY=false

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

# ====================== 系统检查 ======================

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
    
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$free_space" -lt "$min_space" ]; then
        error "磁盘空间不足！当前剩余: ${free_space}GB，需要至少: ${min_space}GB"
        return 1
    fi
    
    log "磁盘空间充足: ${free_space}GB ✓"
    return 0
}

check_browser_support() {
    if [ -n "$DISPLAY" ] || [ "$XDG_SESSION_TYPE" = "x11" ] || [ "$XDG_SESSION_TYPE" = "wayland" ]; then
        if command -v xdg-open &>/dev/null || command -v gnome-open &>/dev/null || command -v kde-open &>/dev/null; then
            return 0
        fi
    fi
    return 1
}

open_in_browser() {
    local url="$1"
    local url_desc="$2"
    
    echo ""
    echo -e "${YELLOW}正在尝试在浏览器中打开${url_desc}...${NC}"
    
    if check_browser_support; then
        if command -v xdg-open &>/dev/null; then
            xdg-open "$url" 2>/dev/null &
            log "已使用 xdg-open 打开浏览器"
            return 0
        elif command -v gnome-open &>/dev/null; then
            gnome-open "$url" 2>/dev/null &
            log "已使用 gnome-open 打开浏览器"
            return 0
        elif command -v kde-open &>/dev/null; then
            kde-open "$url" 2>/dev/null &
            log "已使用 kde-open 打开浏览器"
            return 0
        fi
    fi
    
    warn "无法自动打开浏览器，请手动访问: $url"
    return 1
}

# ====================== 服务管理 ======================

check_service_status() {
    local service_name="$1"
    local display_name="${2:-$service_name}"
    
    if systemctl list-unit-files | grep -q "$service_name.service"; then
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
    if systemctl list-unit-files | grep -q "1panel" || command -v 1pctl &>/dev/null || [ -f "/usr/local/bin/1panel" ]; then
        return 0
    else
        return 1
    fi
}

# ====================== 启动器功能 ======================

quick_start_menu() {
    while true; do
        show_header
        echo -e "${CYAN}快速启动管理器${NC}"
        show_separator
        echo ""
        echo "1. 检查所有服务状态"
        echo "2. 恢复所有停止的服务"
        echo "3. 重启所有服务"
        echo "4. 设置自动恢复模式"
        echo "5. 查看服务日志"
        echo "6. 返回主菜单"
        echo ""
        
        read -p "请输入选择 (1-6): " start_choice
        
        case $start_choice in
            1)
                check_all_services
                read -p "按回车键继续..."
                ;;
            2)
                recover_all_services
                read -p "按回车键继续..."
                ;;
            3)
                restart_all_services
                read -p "按回车键继续..."
                ;;
            4)
                set_auto_recovery_mode
                ;;
            5)
                view_service_logs
                ;;
            6)
                return
                ;;
            *)
                error "无效选择！"
                sleep 2
                ;;
        esac
    done
}

check_all_services() {
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}               服务状态报告                  ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${BLUE}系统信息：${NC}"
    echo "  系统: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
    echo "  时间: $(date)"
    echo "  运行时间: $(uptime -p 2>/dev/null || uptime)"
    echo ""
    
    echo -e "${BLUE}系统服务：${NC}"
    check_service_status "chronyd" "时间同步"
    check_service_status "ssh" "SSH服务"
    check_service_status "ufw" "防火墙"
    echo ""
    
    echo -e "${BLUE}容器服务：${NC}"
    if check_docker_installed; then
        echo -e "  ${GREEN}✓ Docker: 正在运行${NC}"
        local container_count=$(docker ps -q 2>/dev/null | wc -l)
        echo "    运行中的容器: $container_count"
    else
        echo -e "  ${YELLOW}⚠ Docker: 未运行${NC}"
    fi
    echo ""
    
    echo -e "${BLUE}管理面板：${NC}"
    if check_1panel_installed; then
        check_service_status "1panel" "1Panel"
    else
        echo -e "  ${BLUE}ℹ 1Panel: 未安装${NC}"
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        if /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
            echo -e "  ${GREEN}✓ 宝塔面板: 正在运行${NC}"
        else
            echo -e "  ${YELLOW}⚠ 宝塔面板: 已安装但未运行${NC}"
        fi
    else
        echo -e "  ${BLUE}ℹ 宝塔面板: 未安装${NC}"
    fi
    echo ""
    
    echo -e "${BLUE}端口状态：${NC}"
    local ports_to_check=(22 80 443 9090 8888)
    local port_names=("SSH" "HTTP" "HTTPS" "1Panel" "宝塔")
    
    for i in "${!ports_to_check[@]}"; do
        local port="${ports_to_check[i]}"
        local name="${port_names[i]}"
        
        if ss -tulpn | grep -q ":$port "; then
            echo -e "  ${GREEN}✓ 端口 ${port} (${name}): 已监听${NC}"
        else
            echo -e "  ${YELLOW}⚠ 端口 ${port} (${name}): 未监听${NC}"
        fi
    done
    
    show_separator
    echo -e "${GREEN}检查完成！${NC}"
}

recover_all_services() {
    warn "开始恢复所有服务..."
    
    read -p "确定要恢复所有停止的服务吗？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "取消服务恢复"
        return 0
    fi
    
    local system_services=("chronyd" "ssh" "ufw")
    for service in "${system_services[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service" && ! systemctl is-active --quiet "$service" 2>/dev/null; then
            start_service "$service"
        fi
    done
    
    if command -v docker &>/dev/null && ! systemctl is-active --quiet docker 2>/dev/null; then
        start_service "docker" "Docker"
    fi
    
    if check_1panel_installed && ! systemctl is-active --quiet 1panel 2>/dev/null; then
        start_service "1panel" "1Panel"
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        if ! /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
            info "启动宝塔面板..."
            /etc/init.d/bt start 2>/dev/null
            if /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
                success "宝塔面板启动成功"
            else
                error "宝塔面板启动失败"
            fi
        fi
    fi
    
    success "所有服务恢复完成"
}

restart_all_services() {
    warn "开始重启所有服务..."
    
    echo -e "${RED}⚠  警告：这将重启所有服务，可能导致短暂的服务中断${NC}"
    read -p "确定要重启所有服务吗？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "取消服务重启"
        return 0
    fi
    
    local system_services=("chronyd" "ssh")
    for service in "${system_services[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service"; then
            restart_service "$service"
        fi
    done
    
    if command -v docker &>/dev/null; then
        restart_service "docker" "Docker"
    fi
    
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
    
    success "所有服务重启完成"
}

set_auto_recovery_mode() {
    show_header
    echo -e "${CYAN}自动恢复模式设置${NC}"
    show_separator
    echo ""
    
    echo -e "当前自动恢复模式: ${YELLOW}$([ "$AUTO_RECOVERY" = true ] && echo "启用" || echo "禁用")${NC}"
    echo ""
    echo "自动恢复模式说明："
    echo "  启用时：服务器重启后自动恢复所有服务"
    echo "  禁用时：需要手动确认是否恢复服务"
    echo ""
    echo "1. 启用自动恢复模式"
    echo "2. 禁用自动恢复模式"
    echo "3. 创建开机自启动脚本"
    echo "4. 删除开机自启动脚本"
    echo "5. 返回"
    echo ""
    
    read -p "请输入选择 (1-5): " recovery_choice
    
    case $recovery_choice in
        1)
            AUTO_RECOVERY=true
            log "已启用自动恢复模式"
            ;;
        2)
            AUTO_RECOVERY=false
            log "已禁用自动恢复模式"
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
        *)
            error "无效选择！"
            ;;
    esac
    
    read -p "按回车键继续..."
}

create_autostart_script() {
    info "创建开机自启动脚本..."
    
    local service_file="/etc/systemd/system/yx-deploy-recovery.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=yx-deploy Auto Recovery Service
After=network.target docker.service
Wants=network.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 30 && /usr/local/bin/yx-deploy-recovery.sh'
RemainAfterExit=yes
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    
    cat > /usr/local/bin/yx-deploy-recovery.sh << 'EOF'
#!/bin/bash
# yx-deploy Auto Recovery Script

LOG_FILE="/var/log/yx-deploy/recovery.log"
mkdir -p /var/log/yx-deploy 2>/dev/null

echo "$(date): 开始自动恢复服务..." >> "$LOG_FILE"
sleep 10

if command -v docker &>/dev/null; then
    if ! systemctl is-active --quiet docker; then
        systemctl start docker >> "$LOG_FILE" 2>&1
        echo "$(date): 启动Docker服务" >> "$LOG_FILE"
    fi
fi

if systemctl list-unit-files | grep -q "1panel.service"; then
    if ! systemctl is-active --quiet 1panel; then
        systemctl start 1panel >> "$LOG_FILE" 2>&1
        echo "$(date): 启动1Panel服务" >> "$LOG_FILE"
    fi
fi

if [ -f "/etc/init.d/bt" ]; then
    if ! /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
        /etc/init.d/bt start >> "$LOG_FILE" 2>&1
        echo "$(date): 启动宝塔面板" >> "$LOG_FILE"
    fi
fi

echo "$(date): 自动恢复服务完成" >> "$LOG_FILE"
EOF
    
    chmod +x /usr/local/bin/yx-deploy-recovery.sh
    chmod 644 "$service_file"
    
    systemctl daemon-reload
    systemctl enable yx-deploy-recovery.service 2>/dev/null
    systemctl start yx-deploy-recovery.service 2>/dev/null
    
    success "开机自启动脚本创建成功"
    echo ""
    echo -e "${GREEN}服务已配置为开机自动启动${NC}"
    echo "服务名称: yx-deploy-recovery.service"
    echo "恢复脚本: /usr/local/bin/yx-deploy-recovery.sh"
    echo "日志文件: /var/log/yx-deploy/recovery.log"
}

remove_autostart_script() {
    info "删除开机自启动脚本..."
    
    systemctl stop yx-deploy-recovery.service 2>/dev/null
    systemctl disable yx-deploy-recovery.service 2>/dev/null
    systemctl daemon-reload
    
    rm -f /etc/systemd/system/yx-deploy-recovery.service 2>/dev/null
    rm -f /usr/local/bin/yx-deploy-recovery.sh 2>/dev/null
    
    success "开机自启动脚本已删除"
}

view_service_logs() {
    while true; do
        show_header
        echo -e "${CYAN}查看服务日志${NC}"
        show_separator
        echo ""
        echo "1. 查看Docker日志"
        echo "2. 查看1Panel日志"
        echo "3. 查看系统日志"
        echo "4. 查看恢复日志"
        echo "5. 返回"
        echo ""
        
        read -p "请输入选择 (1-5): " log_choice
        
        case $log_choice in
            1)
                echo ""
                echo -e "${CYAN}Docker日志：${NC}"
                journalctl -u docker -n 30 --no-pager
                read -p "按回车键继续..."
                ;;
            2)
                echo ""
                echo -e "${CYAN}1Panel日志：${NC}"
                journalctl -u 1panel -n 30 --no-pager 2>/dev/null || echo "1Panel服务日志不可用"
                read -p "按回车键继续..."
                ;;
            3)
                echo ""
                echo -e "${CYAN}系统日志：${NC}"
                dmesg | tail -30
                read -p "按回车键继续..."
                ;;
            4)
                echo ""
                echo -e "${CYAN}恢复日志：${NC}"
                if [ -f "/var/log/yx-deploy/recovery.log" ]; then
                    tail -30 "/var/log/yx-deploy/recovery.log"
                else
                    echo "恢复日志文件不存在"
                fi
                read -p "按回车键继续..."
                ;;
            5)
                return
                ;;
            *)
                error "无效选择！"
                sleep 2
                ;;
        esac
    done
}

startup_recovery_check() {
    info "启动时服务状态检查..."
    
    local stopped_services=()
    local critical_services=("docker" "1panel")
    
    for service in "${critical_services[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service"; then
            if ! systemctl is-active --quiet "$service" 2>/dev/null; then
                stopped_services+=("$service")
            fi
        fi
    done
    
    if [ -f "/etc/init.d/bt" ]; then
        if ! /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
            stopped_services+=("宝塔面板")
        fi
    fi
    
    if [ ${#stopped_services[@]} -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠  发现以下服务未运行：${NC}"
        for service in "${stopped_services[@]}"; do
            echo "  - $service"
        done
        echo ""
        
        if [ "$AUTO_RECOVERY" = true ]; then
            log "自动恢复模式已启用，正在自动恢复服务..."
            recover_all_services
        else
            read -p "是否立即恢复这些服务？(y/N): " -n 1 recovery_confirm
            echo
            if [[ $recovery_confirm =~ ^[Yy]$ ]]; then
                recover_all_services
            else
                log "用户选择不恢复服务"
            fi
        fi
    else
        log "所有关键服务运行正常"
    fi
}

# ====================== 基础检查 ======================

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

show_header() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║          Ubuntu 服务器部署脚本 v$SCRIPT_VERSION           ║"
    echo "║                  优化版 - 专业运维                      ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

confirm_execution() {
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
    
    startup_recovery_check
    
    read -p "按回车键进入主菜单，或按 Ctrl+C 退出..." 
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

# ====================== 系统优化 ======================

backup_config() {
    local config_file="$1"
    if [ -f "$config_file" ]; then
        local backup_file="${BACKUP_DIR}/$(basename "$config_file").$(date +%Y%m%d_%H%M%S).bak"
        cp "$config_file" "$backup_file" 2>/dev/null
        log "已备份 $config_file"
    fi
}

system_optimization() {
    info "开始系统优化配置..."
    
    echo ""
    echo -e "${YELLOW}系统优化将执行以下操作：${NC}"
    echo "  1. 更新软件包列表"
    echo "  2. 升级现有软件包"
    echo "  3. 安装运维工具包"
    echo "  4. 设置时区和时间同步"
    echo "  5. 配置SSH安全加固"
    echo "  6. 优化内核参数"
    echo "  7. 配置资源限制"
    echo "  8. 安装监控工具"
    echo "  9. 配置日志轮转"
    echo "  10. 设置安全基线"
    echo ""
    
    read -p "是否继续？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "用户取消系统优化"
        return 0
    fi
    
    # 更新软件包
    info "更新软件包列表..."
    show_separator
    apt-get update -y
    check_status "软件包列表更新完成" "更新失败"
    show_separator
    
    # 升级软件包
    echo ""
    read -p "是否升级现有软件包？(y/N): " -n 1 upgrade_confirm
    echo
    if [[ $upgrade_confirm =~ ^[Yy]$ ]]; then
        info "升级现有软件包..."
        show_separator
        apt-get upgrade -y
        check_status "软件包升级完成" "升级失败"
        show_separator
    fi
    
    # 安装运维工具包
    info "安装运维工具包..."
    local packages=(
        curl wget vim git net-tools htop iftop iotop screen tmux ufw
        ntpdate software-properties-common apt-transport-https ca-certificates
        gnupg lsb-release chrony build-essential pkg-config
        ncdu tree jq bc rsync fail2ban clamav clamav-daemon
        sysstat dstat atop smartmontools iperf3
    )
    
    echo "将安装以下运维工具："
    printf "  %s\n" "${packages[@]}" | fold -w 50
    echo ""
    
    read -p "是否继续安装？(y/N): " -n 1 install_confirm
    echo
    if [[ ! $install_confirm =~ ^[Yy]$ ]]; then
        log "用户取消软件安装"
        return 0
    fi
    
    show_separator
    apt-get install -y "${packages[@]}"
    check_status "运维工具安装完成" "软件安装失败"
    show_separator
    
    # 设置时区
    info "设置时区为上海..."
    timedatectl set-timezone Asia/Shanghai
    check_status "时区设置成功" "时区设置失败"
    
    # 时间同步
    info "配置时间同步服务..."
    systemctl stop systemd-timesyncd 2>/dev/null || true
    systemctl disable systemd-timesyncd 2>/dev/null || true
    systemctl enable chronyd
    systemctl restart chronyd
    check_status "时间同步配置完成" "时间同步配置失败"
    
    # SSH安全加固
    echo ""
    read -p "是否配置SSH安全加固？(y/N): " -n 1 ssh_confirm
    echo
    if [[ $ssh_confirm =~ ^[Yy]$ ]]; then
        info "配置SSH安全加固..."
        if [ -f "/etc/ssh/sshd_config" ]; then
            backup_config "/etc/ssh/sshd_config"
            
            echo -e "${CYAN}修改SSH配置...${NC}"
            sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
            sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
            sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config 2>/dev/null || true
            sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/' /etc/ssh/sshd_config 2>/dev/null || true
            sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/' /etc/ssh/sshd_config 2>/dev/null || true
            sed -i 's/#LoginGraceTime 2m/LoginGraceTime 1m/' /etc/ssh/sshd_config 2>/dev/null || true
            echo "AllowUsers root" >> /etc/ssh/sshd_config 2>/dev/null || true
            
            systemctl restart sshd
            check_status "SSH安全加固完成" "SSH配置失败"
        fi
    fi
    
    # 防火墙配置
    echo ""
    read -p "是否配置防火墙？(y/N): " -n 1 fw_confirm
    echo
    if [[ $fw_confirm =~ ^[Yy]$ ]]; then
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
    fi
    
    # 内核优化
    echo ""
    read -p "是否优化内核参数？(y/N): " -n 1 kernel_confirm
    echo
    if [[ $kernel_confirm =~ ^[Yy]$ ]]; then
        info "优化内核参数..."
        backup_config "/etc/sysctl.conf"
        
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

# 安全设置
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 1024
net.ipv4.tcp_synack_retries = 2
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
EOF
        
        sysctl -p
        check_status "内核参数已应用" "内核参数应用失败"
    fi
    
    # 资源限制配置
    echo ""
    read -p "是否配置资源限制？(y/N): " -n 1 ulimit_confirm
    echo
    if [[ $ulimit_confirm =~ ^[Yy]$ ]]; then
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
    fi
    
    # 日志轮转配置
    info "优化日志轮转配置..."
    
    cat > /etc/logrotate.d/syslog-optimized << 'EOF'
/var/log/syslog
{
    rotate 7
    daily
    missingok
    notifempty
    delaycompress
    compress
    postrotate
        /usr/lib/rsyslog/rsyslog-rotate
    endscript
}
EOF
    
    # Fail2ban配置
    echo ""
    read -p "是否配置Fail2ban防暴力破解？(y/N): " -n 1 fail2ban_confirm
    echo
    if [[ $fail2ban_confirm =~ ^[Yy]$ ]]; then
        info "配置Fail2ban..."
        
        cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
EOF
        
        systemctl restart fail2ban
        check_status "Fail2ban配置完成" "Fail2ban配置失败"
    fi
    
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}          系统优化配置完成！${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    
    return 0
}

# ====================== Docker安装 ======================

install_docker() {
    info "开始安装Docker..."
    
    if check_docker_installed; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "未知版本")
        warn "Docker已经安装，版本: $docker_version"
        
        read -p "是否重新安装Docker？(y/N): " -n 1 reinstall_confirm
        echo
        if [[ ! $reinstall_confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}              Docker安装信息${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo "将使用官方脚本安装Docker"
    echo "安装过程中可能需要您确认"
    echo "安装后会自动配置镜像加速器"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "是否继续安装Docker？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "用户取消Docker安装"
        return 0
    fi
    
    info "正在下载并运行Docker安装脚本..."
    show_separator
    
    if command -v curl &>/dev/null; then
        curl -fsSL https://get.docker.com | sh
    else
        wget -O- https://get.docker.com | sh
    fi
    
    local docker_install_status=$?
    show_separator
    
    if [ $docker_install_status -eq 0 ]; then
        log "✅ Docker安装成功！"
        
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
        
        systemctl restart docker
        systemctl enable docker
        
        echo ""
        info "测试Docker安装..."
        if docker run --rm hello-world &>/dev/null; then
            success "✅ Docker测试成功！"
        else
            warn "⚠ Docker测试失败，但Docker已安装"
        fi
        
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

# ====================== 面板安装 ======================

install_1panel() {
    info "开始安装1Panel面板..."
    
    if check_1panel_installed; then
        warn "1Panel面板已经安装！"
        
        read -p "是否重新安装1Panel面板？(y/N): " -n 1 reinstall_confirm
        echo
        if [[ ! $reinstall_confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
        
        info "卸载现有1Panel面板..."
        if command -v 1pctl &>/dev/null; then
            1pctl uninstall
        fi
        systemctl stop 1panel 2>/dev/null || true
        rm -rf /opt/1panel
        rm -rf /usr/local/bin/1panel
        sleep 2
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           1Panel面板安装信息${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo "重要提示："
    echo "  1. 安装过程中需要您手动确认（输入 y）"
    echo "  2. 需要设置面板访问密码"
    echo "  3. 请记住设置的密码"
    echo "  4. 默认访问地址: https://服务器IP:9090"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "是否继续安装1Panel？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "用户取消1Panel安装"
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}安装步骤说明：${NC}"
    echo "  1. 下载安装脚本"
    echo "  2. 运行安装脚本"
    echo "  3. 当提示 'Please enter y or n:' 时，请输入 y"
    echo "  4. 设置面板密码（输入两次）"
    echo "  5. 等待安装完成"
    echo ""
    
    read -p "按回车键开始安装，或按 Ctrl+C 取消..." 
    
    info "下载并安装1Panel面板..."
    show_separator
    
    curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh
    chmod +x quick_start.sh
    ./quick_start.sh
    
    local install_status=$?
    show_separator
    
    sleep 5
    if check_1panel_installed; then
        success "✅ 1Panel面板安装成功！"
        
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        local panel_url="https://${ip_address}:9090"
        
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo -e "${GREEN}           1Panel面板安装完成！${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}访问地址: ${panel_url}${NC}"
        echo -e "${YELLOW}用户名: admin${NC}"
        echo -e "${YELLOW}密码: 您刚才设置的密码${NC}"
        echo ""
        
        open_in_browser "$panel_url" "1Panel面板"
        
        return 0
    else
        error "❌ 1Panel安装失败！"
        return 1
    fi
}

install_baota() {
    info "开始安装宝塔面板..."
    
    if [ -f "/etc/init.d/bt" ]; then
        warn "宝塔面板已经安装！"
        
        read -p "是否重新安装宝塔面板？(y/N): " -n 1 reinstall_confirm
        echo
        if [[ ! $reinstall_confirm =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           宝塔面板安装信息${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo "重要提示："
    echo "  1. 安装过程需要较长时间（5-10分钟）"
    echo "  2. 安装过程中需要您确认（输入 y）"
    echo "  3. 安装完成后会显示登录信息"
    echo "  4. 请保存显示的登录信息"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "是否继续安装宝塔面板？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "用户取消宝塔面板安装"
        return 0
    fi
    
    echo ""
    echo -e "${YELLOW}安装步骤说明：${NC}"
    echo "  1. 下载安装脚本"
    echo "  2. 运行安装脚本"
    echo "  3. 当提示确认时，请输入 y"
    echo "  4. 等待安装完成"
    echo "  5. 保存显示的登录信息"
    echo ""
    
    read -p "按回车键开始安装，或按 Ctrl+C 取消..." 
    
    info "下载并安装宝塔面板..."
    show_separator
    
    if command -v curl &>/dev/null; then
        curl -sSO https://download.bt.cn/install/install_panel.sh
    else
        wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh
    fi
    
    bash install_panel.sh
    
    local install_status=$?
    show_separator
    
    sleep 5
    if [ -f "/etc/init.d/bt" ]; then
        success "✅ 宝塔面板安装成功！"
        
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null)
        local panel_url="http://${ip_address}:8888"
        
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo -e "${GREEN}           宝塔面板安装完成！${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}访问地址: ${panel_url}${NC}"
        echo -e "${YELLOW}请查看屏幕上显示的登录信息${NC}"
        echo ""
        
        open_in_browser "$panel_url" "宝塔面板"
        
        return 0
    else
        error "❌ 宝塔面板安装失败！"
        return 1
    fi
}

# ====================== 卸载功能 ======================

uninstall_docker() {
    warn "开始卸载Docker..."
    
    read -p "确定要卸载Docker吗？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "取消卸载Docker"
        return 0
    fi
    
    info "停止Docker服务..."
    systemctl stop docker 2>/dev/null
    systemctl stop containerd 2>/dev/null
    
    info "卸载Docker软件包..."
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
    apt-get purge -y docker-ce docker-ce-cli containerd.io 2>/dev/null
    
    info "清理Docker数据..."
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
    rm -rf /etc/docker
    
    success "Docker卸载完成"
}

uninstall_1panel() {
    warn "开始卸载1Panel面板..."
    
    if ! check_1panel_installed; then
        warn "1Panel面板未安装"
        return 0
    fi
    
    read -p "确定要卸载1Panel面板吗？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "取消卸载1Panel面板"
        return 0
    fi
    
    info "卸载1Panel面板..."
    
    if command -v 1pctl &>/dev/null; then
        echo "请按照提示完成卸载操作..."
        1pctl uninstall
    fi
    
    systemctl stop 1panel 2>/dev/null || true
    systemctl disable 1panel 2>/dev/null || true
    
    rm -rf /opt/1panel
    rm -rf /usr/local/bin/1panel
    rm -rf /usr/local/bin/1pctl 2>/dev/null
    rm -f /etc/systemd/system/1panel.service 2>/dev/null
    
    success "1Panel面板卸载完成"
}

uninstall_baota() {
    warn "开始卸载宝塔面板..."
    
    if [ ! -f "/etc/init.d/bt" ]; then
        warn "宝塔面板未安装"
        return 0
    fi
    
    read -p "确定要卸载宝塔面板吗？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "取消卸载宝塔面板"
        return 0
    fi
    
    info "卸载宝塔面板..."
    
    if [ -f "/www/server/panel/install.sh" ]; then
        echo "请按照提示完成卸载操作..."
        bash /www/server/panel/install.sh uninstall
    fi
    
    rm -rf /www/server/panel
    rm -f /etc/init.d/bt
    
    success "宝塔面板卸载完成"
}

cleanup_temp_files() {
    info "清理临时文件..."
    
    rm -f quick_start.sh 2>/dev/null
    rm -f install_panel.sh 2>/dev/null
    
    find "$LOG_DIR" -type f -name "*.log" -mtime +7 -delete 2>/dev/null
    
    log "临时文件清理完成"
}

cleanup_all() {
    warn "开始清理所有安装..."
    
    echo -e "${RED}⚠  警告：这将卸载所有通过本脚本安装的软件${NC}"
    echo "包括："
    echo "  1. Docker"
    echo "  2. 1Panel面板"
    echo "  3. 宝塔面板"
    echo ""
    
    read -p "确定要清理所有安装吗？(y/N): " -n 1 confirm
    echo
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        log "取消清理所有安装"
        return 0
    fi
    
    if check_1panel_installed; then
        uninstall_1panel
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        uninstall_baota
    fi
    
    if check_docker_installed; then
        uninstall_docker
    fi
    
    cleanup_temp_files
    
    success "所有安装清理完成"
}

cleanup_menu() {
    while true; do
        show_header
        echo -e "${YELLOW}卸载工具${NC}"
        show_separator
        echo ""
        echo "1. 卸载Docker"
        echo "2. 卸载1Panel面板"
        echo "3. 卸载宝塔面板"
        echo "4. 清理所有安装"
        echo "5. 返回主菜单"
        echo ""
        
        read -p "请输入选择 (1-5): " cleanup_choice
        
        case $cleanup_choice in
            1)
                uninstall_docker
                read -p "按回车键继续..."
                ;;
            2)
                uninstall_1panel
                read -p "按回车键继续..."
                ;;
            3)
                uninstall_baota
                read -p "按回车键继续..."
                ;;
            4)
                cleanup_all
                read -p "按回车键继续..."
                ;;
            5)
                return
                ;;
            *)
                error "无效选择！"
                sleep 2
                ;;
        esac
    done
}

# ====================== 系统状态检查 ======================

system_integrity_check() {
    show_header
    echo -e "${CYAN}       系统完整性检查报告${NC}"
    show_separator
    echo ""
    
    echo -e "${BLUE}1. 系统信息：${NC}"
    echo "   OS: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
    echo "   内核: $(uname -r)"
    echo "   架构: $(uname -m)"
    
    echo ""
    echo -e "${BLUE}2. 资源使用：${NC}"
    echo -n "   内存: "
    free -h | awk 'NR==2{print $4 " / " $2}'
    echo -n "   磁盘: "
    df -h / | awk 'NR==2{print $4 " / " $2}'
    
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
    
    echo ""
    echo -e "${BLUE}4. 网络状态：${NC}"
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "未知")
    echo "   IP地址: $ip_address"
    
    echo ""
    show_separator
    echo -e "${GREEN}检查完成！${NC}"
    
    read -p "按回车键返回主菜单..."
}

# ====================== 主菜单 ======================

main_menu() {
    while true; do
        show_header
        
        echo -e "${CYAN}当前安装状态：${NC}"
        echo -n "  Docker: "
        if check_docker_installed; then
            echo -e "${GREEN}已安装${NC}"
        else
            echo -e "${YELLOW}未安装${NC}"
        fi
        
        echo -n "  1Panel: "
        if check_1panel_installed; then
            echo -e "${GREEN}已安装${NC}"
        else
            echo -e "${YELLOW}未安装${NC}"
        fi
        
        echo -n "  宝塔: "
        if [ -f "/etc/init.d/bt" ]; then
            echo -e "${GREEN}已安装${NC}"
        else
            echo -e "${YELLOW}未安装${NC}"
        fi
        echo ""
        
        echo -e "${CYAN}请选择要执行的操作：${NC}"
        show_separator
        echo ""
        echo "1. 系统优化配置"
        echo "2. 安装Docker"
        echo "3. 安装1Panel面板"
        echo "4. 安装宝塔面板"
        echo "5. 完整安装（1+2+3）"
        echo "6. 快速启动管理器"
        echo "7. 系统状态检查"
        echo "8. 卸载工具"
        echo "9. 清理临时文件"
        echo "0. 退出"
        echo ""
        echo -e "${YELLOW}提示：所有安装都会显示输出，需要您手动确认${NC}"
        echo -e "${YELLOW}日志文件: ${INSTALL_LOG}${NC}"
        show_separator
        
        read -p "请输入选择 (0-9): " choice
        
        case $choice in
            1) 
                system_optimization
                read -p "按回车键返回主菜单..." 
                ;;
            2) 
                install_docker
                read -p "按回车键返回主菜单..." 
                ;;
            3) 
                install_1panel
                read -p "按回车键返回主菜单..." 
                ;;
            4) 
                install_baota
                read -p "按回车键返回主菜单..." 
                ;;
            5) 
                echo -e "${YELLOW}开始完整安装流程...${NC}"
                echo ""
                system_optimization
                install_docker
                install_1panel
                read -p "按回车键返回主菜单..." 
                ;;
            6)
                quick_start_menu
                ;;
            7)
                system_integrity_check
                ;;
            8)
                cleanup_menu
                ;;
            9)
                cleanup_temp_files
                read -p "按回车键返回主菜单..." 
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
    done
}

# ====================== 主程序 ======================

main() {
    init_log_system
    check_sudo "$@"
    check_required_tools
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

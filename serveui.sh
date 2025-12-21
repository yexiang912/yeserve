#!/bin/bash

# =============================================
# Ubuntu 服务器一键部署脚本 (GUI修复版 v6.0)
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
SCRIPT_NAME="yx-deploy-gui"
BACKUP_DIR="/backup/${SCRIPT_NAME}"
LOG_DIR="/var/log/${SCRIPT_NAME}"
INSTALL_LOG="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
DIALOG_TITLE="Ubuntu服务器部署工具 v$SCRIPT_VERSION"
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

# ====================== 快速启动管理器 ======================

quick_start_menu() {
    while true; do
        choice=$(show_gui_menu "快速启动管理器" 15 60 6 \
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
            1)
                check_all_services_gui
                ;;
            2)
                recover_all_services_gui
                ;;
            3)
                restart_all_services_gui
                ;;
            4)
                set_auto_recovery_mode_gui
                ;;
            5)
                view_service_logs_gui
                ;;
            6)
                return
                ;;
        esac
    done
}

check_all_services_gui() {
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
    
    echo ""
    show_separator
    echo -e "${GREEN}检查完成！${NC}"
    
    return_to_gui
}

recover_all_services_gui() {
    if ! show_gui_yesno "恢复服务" "确定要恢复所有停止的服务吗？" 8 40; then
        log "取消服务恢复"
        return
    fi
    
    exit_to_terminal
    warn "开始恢复所有服务..."
    
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
    return_to_gui
}

restart_all_services_gui() {
    if ! show_gui_yesno "重启服务" "⚠ 警告：这将重启所有服务，可能导致短暂的服务中断\n\n确定要重启所有服务吗？" 10 50; then
        log "取消服务重启"
        return
    fi
    
    exit_to_terminal
    warn "开始重启所有服务..."
    
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
    return_to_gui
}

set_auto_recovery_mode_gui() {
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
                create_autostart_script_gui
                ;;
            4)
                remove_autostart_script_gui
                ;;
            5)
                return
                ;;
        esac
    done
}

create_autostart_script_gui() {
    if ! show_gui_yesno "创建自启动脚本" "将创建开机自启动脚本，系统启动时自动恢复服务。\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
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
    
    return_to_gui
}

remove_autostart_script_gui() {
    if ! show_gui_yesno "删除自启动脚本" "确定要删除开机自启动脚本吗？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "删除开机自启动脚本..."
    
    systemctl stop yx-deploy-recovery.service 2>/dev/null
    systemctl disable yx-deploy-recovery.service 2>/dev/null
    systemctl daemon-reload
    
    rm -f /etc/systemd/system/yx-deploy-recovery.service 2>/dev/null
    rm -f /usr/local/bin/yx-deploy-recovery.sh 2>/dev/null
    
    success "开机自启动脚本已删除"
    return_to_gui
}

view_service_logs_gui() {
    while true; do
        choice=$(show_gui_menu "查看服务日志" 12 60 5 \
                  "1" "查看Docker日志" \
                  "2" "查看1Panel日志" \
                  "3" "查看系统日志" \
                  "4" "查看恢复日志" \
                  "5" "返回")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1)
                exit_to_terminal
                echo -e "${CYAN}Docker日志：${NC}"
                journalctl -u docker -n 30 --no-pager
                return_to_gui
                ;;
            2)
                exit_to_terminal
                echo -e "${CYAN}1Panel日志：${NC}"
                journalctl -u 1panel -n 30 --no-pager 2>/dev/null || echo "1Panel服务日志不可用"
                return_to_gui
                ;;
            3)
                exit_to_terminal
                echo -e "${CYAN}系统日志：${NC}"
                dmesg | tail -30
                return_to_gui
                ;;
            4)
                exit_to_terminal
                echo -e "${CYAN}恢复日志：${NC}"
                if [ -f "/var/log/yx-deploy/recovery.log" ]; then
                    tail -30 "/var/log/yx-deploy/recovery.log"
                else
                    echo "恢复日志文件不存在"
                fi
                return_to_gui
                ;;
            5)
                return
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
            recover_all_services_gui
        else
            echo -e "${YELLOW}是否立即恢复这些服务？${NC}"
            read -p "(y/N): " -n 1 recovery_confirm
            echo
            if [[ $recovery_confirm =~ ^[Yy]$ ]]; then
                recover_all_services_gui
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
    echo "║                 GUI版 - 专业运维                        ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
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

system_optimization_gui() {
    while true; do
        choice=$(show_gui_menu "系统优化配置" 20 70 10 \
                  "1" "更新软件包列表" \
                  "2" "升级现有软件包" \
                  "3" "安装运维工具包" \
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
            1) update_packages_gui ;;
            2) upgrade_packages_gui ;;
            3) install_tools_gui ;;
            4) setup_timezone_gui ;;
            5) configure_ssh_gui ;;
            6) optimize_kernel_gui ;;
            7) configure_resources_gui ;;
            8) configure_firewall_gui ;;
            9) full_optimization_gui ;;
            10) return ;;
        esac
    done
}

update_packages_gui() {
    if ! show_gui_yesno "更新软件包" "将更新系统软件包列表\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "更新软件包列表..."
    show_separator
    apt-get update -y
    check_status "软件包列表更新完成" "更新失败"
    show_separator
    return_to_gui
}

upgrade_packages_gui() {
    if ! show_gui_yesno "升级软件包" "将升级现有软件包\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "升级现有软件包..."
    show_separator
    apt-get upgrade -y
    check_status "软件包升级完成" "升级失败"
    show_separator
    return_to_gui
}

install_tools_gui() {
    if ! show_gui_yesno "安装运维工具" "将安装常用运维工具包\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "安装运维工具包..."
    local packages=(
        curl wget vim git net-tools htop iftop iotop screen tmux ufw
        ntpdate software-properties-common apt-transport-https ca-certificates
        gnupg lsb-release chrony build-essential pkg-config
        ncdu tree jq bc rsync fail2ban
    )
    
    show_separator
    apt-get install -y "${packages[@]}"
    check_status "运维工具安装完成" "软件安装失败"
    show_separator
    return_to_gui
}

setup_timezone_gui() {
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

configure_ssh_gui() {
    if ! show_gui_yesno "SSH安全加固" "将配置SSH安全加固设置\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "配置SSH安全加固..."
    if [ -f "/etc/ssh/sshd_config" ]; then
        backup_config "/etc/ssh/sshd_config"
        
        echo -e "${CYAN}修改SSH配置...${NC}"
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 2/' /etc/ssh/sshd_config 2>/dev/null || true
        
        systemctl restart sshd
        check_status "SSH安全加固完成" "SSH配置失败"
    fi
    
    return_to_gui
}

optimize_kernel_gui() {
    if ! show_gui_yesno "内核优化" "将优化内核参数\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
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
EOF
    
    sysctl -p
    check_status "内核参数已应用" "内核参数应用失败"
    return_to_gui
}

configure_resources_gui() {
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

configure_firewall_gui() {
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

full_optimization_gui() {
    if ! show_gui_yesno "一键优化" "将执行所有系统优化操作\n\n是否继续？" 8 40; then
        return
    fi
    
    exit_to_terminal
    info "开始系统一键优化..."
    
    # 更新软件包
    info "更新软件包列表..."
    apt-get update -y
    apt-get upgrade -y
    
    # 安装工具
    info "安装运维工具包..."
    local packages=(
        curl wget vim git net-tools htop iftop iotop screen tmux ufw
        ntpdate software-properties-common apt-transport-https ca-certificates
        gnupg lsb-release chrony build-essential pkg-config
        ncdu tree jq bc rsync fail2ban
    )
    apt-get install -y "${packages[@]}"
    
    # 设置时区
    info "设置时区为上海..."
    timedatectl set-timezone Asia/Shanghai
    systemctl enable chronyd
    systemctl restart chronyd
    
    # SSH安全
    info "配置SSH安全..."
    if [ -f "/etc/ssh/sshd_config" ]; then
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config 2>/dev/null || true
        systemctl restart sshd
    fi
    
    # 内核优化
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
    sysctl -p
    
    # 防火墙
    info "配置防火墙..."
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw allow https
    
    # 资源限制
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

# ====================== Docker安装 ======================

install_docker_gui() {
    if check_docker_installed; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "未知版本")
        if ! show_gui_yesno "Docker状态" "Docker已经安装：\n版本: $docker_version\n\n是否重新安装？" 10 50; then
            return
        fi
    fi
    
    if ! show_gui_yesno "安装Docker" "将安装Docker容器引擎\n\n安装后会自动配置镜像加速器\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    info "开始安装Docker..."
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}              Docker安装信息${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo "将使用官方脚本安装Docker"
    echo "安装过程中可能需要您确认"
    echo "安装后会自动配置镜像加速器"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
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
    else
        error "❌ Docker安装失败！"
    fi
    
    return_to_gui
}

# ====================== 面板安装 ======================

install_1panel_gui() {
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
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           1Panel面板安装信息${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo "安装步骤说明："
    echo "  1. 当提示 'Please enter y or n:' 时，请输入 y"
    echo "  2. 设置面板密码（输入两次）"
    echo "  3. 等待安装完成"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    info "下载并安装1Panel面板..."
    show_separator
    
    curl -fsSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh
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
    else
        error "❌ 1Panel安装失败！"
    fi
    
    return_to_gui
}

install_baota_gui() {
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
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           宝塔面板安装信息${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo "安装步骤说明："
    echo "  1. 当提示确认时，请输入 y"
    echo "  2. 等待安装完成（需要5-10分钟）"
    echo "  3. 保存显示的登录信息"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    info "下载并安装宝塔面板..."
    show_separator
    
    if command -v curl &>/dev/null; then
        curl -fsSL https://download.bt.cn/install/install_panel.sh -o install_panel.sh
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
    else
        error "❌ 宝塔面板安装失败！"
    fi
    
    return_to_gui
}

# ====================== 完整安装 ======================

full_installation_gui() {
    if ! show_gui_yesno "完整安装" "将执行完整安装流程：\n1. 系统优化配置\n2. 安装Docker\n3. 安装1Panel面板\n\n是否继续？" 10 50; then
        return
    fi
    
    exit_to_terminal
    
    echo -e "${YELLOW}开始完整安装流程...${NC}"
    echo ""
    
    # 系统优化
    info "执行系统优化配置..."
    apt-get update -y
    apt-get upgrade -y
    apt-get install -y curl wget vim git net-tools htop ufw chrony
    timedatectl set-timezone Asia/Shanghai
    ufw --force enable
    ufw allow ssh
    log "系统优化完成"
    
    # Docker安装
    info "安装Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    log "Docker安装完成"
    
    # 1Panel安装
    info "安装1Panel面板..."
    curl -fsSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh
    chmod +x quick_start.sh
    ./quick_start.sh
    sleep 5
    
    if check_1panel_installed; then
        success "✅ 完整安装流程完成！"
        
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo -e "${GREEN}          完整安装完成！${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════${NC}"
        echo ""
        echo -e "${YELLOW}1Panel访问地址: https://${ip_address}:9090${NC}"
        echo -e "${YELLOW}用户名: admin${NC}"
    else
        error "❌ 1Panel安装失败！"
    fi
    
    return_to_gui
}

# ====================== 系统状态检查 ======================

system_integrity_check_gui() {
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

# ====================== 卸载工具 ======================

uninstall_menu_gui() {
    while true; do
        choice=$(show_gui_menu "卸载工具" 12 60 5 \
                  "1" "卸载Docker" \
                  "2" "卸载1Panel面板" \
                  "3" "卸载宝塔面板" \
                  "4" "清理所有安装" \
                  "5" "返回主菜单")
        
        if [ -z "$choice" ]; then
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
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
    rm -rf /etc/docker
    
    success "Docker卸载完成"
    return_to_gui
}

uninstall_1panel_gui() {
    if ! check_1panel_installed; then
        show_gui_msgbox "提示" "1Panel面板未安装" 8 40
        return
    fi
    
    if ! show_gui_yesno "卸载1Panel" "确定要卸载1Panel面板吗？" 8 40; then
        return
    fi
    
    exit_to_terminal
    warn "开始卸载1Panel面板..."
    
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
    return_to_gui
}

uninstall_baota_gui() {
    if [ ! -f "/etc/init.d/bt" ]; then
        show_gui_msgbox "提示" "宝塔面板未安装" 8 40
        return
    fi
    
    if ! show_gui_yesno "卸载宝塔" "确定要卸载宝塔面板吗？" 8 40; then
        return
    fi
    
    exit_to_terminal
    warn "开始卸载宝塔面板..."
    
    info "卸载宝塔面板..."
    if [ -f "/www/server/panel/install.sh" ]; then
        echo "请按照提示完成卸载操作..."
        bash /www/server/panel/install.sh uninstall
    fi
    
    rm -rf /www/server/panel
    rm -f /etc/init.d/bt
    
    success "宝塔面板卸载完成"
    return_to_gui
}

cleanup_all_gui() {
    if ! show_gui_yesno "清理所有安装" "⚠ 警告：这将卸载所有通过本脚本安装的软件\n包括：\n1. Docker\n2. 1Panel面板\n3. 宝塔面板\n\n确定要清理所有安装吗？" 12 60; then
        return
    fi
    
    exit_to_terminal
    warn "开始清理所有安装..."
    
    if check_1panel_installed; then
        warn "卸载1Panel面板..."
        systemctl stop 1panel 2>/dev/null
        rm -rf /opt/1panel
        rm -rf /usr/local/bin/1panel
        rm -f /etc/systemd/system/1panel.service 2>/dev/null
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        warn "卸载宝塔面板..."
        rm -rf /www/server/panel
        rm -f /etc/init.d/bt
    fi
    
    if check_docker_installed; then
        warn "卸载Docker..."
        systemctl stop docker 2>/dev/null
        apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
        rm -rf /var/lib/docker
        rm -rf /etc/docker
    fi
    
    info "清理临时文件..."
    rm -f quick_start.sh 2>/dev/null
    rm -f install_panel.sh 2>/dev/null
    find "$LOG_DIR" -type f -name "*.log" -mtime +7 -delete 2>/dev/null
    
    success "所有安装清理完成"
    return_to_gui
}

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

# ====================== 主菜单 ======================

main_menu_gui() {
    while true; do
        # 获取当前状态
        local docker_status="○ 未安装"
        local panel1_status="○ 未安装"
        local baota_status="○ 未安装"
        
        if check_docker_installed; then
            docker_status="✓ 已安装"
        fi
        
        if check_1panel_installed; then
            panel1_status="✓ 已安装"
        fi
        
        if [ -f "/etc/init.d/bt" ]; then
            baota_status="✓ 已安装"
        fi
        
        choice=$(show_gui_menu "主菜单" 25 70 10 \
                  "1" "系统优化配置" \
                  "2" "安装Docker" \
                  "3" "安装1Panel面板" \
                  "4" "安装宝塔面板" \
                  "5" "完整安装（1+2+3）" \
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
            1) system_optimization_gui ;;
            2) install_docker_gui ;;
            3) install_1panel_gui ;;
            4) install_baota_gui ;;
            5) full_installation_gui ;;
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
        echo -e "${GREEN}感谢使用服务器部署工具！${NC}"
        echo -e "${YELLOW}日志文件: $INSTALL_LOG${NC}"
        exit 0
    fi
}

# ====================== 主程序 ======================

main() {
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

# 设置异常处理
trap 'error "脚本被中断"; echo -e "${YELLOW}日志文件: ${INSTALL_LOG}${NC}"; exit 1' INT TERM

# 执行主函数
main "$@"

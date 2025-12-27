#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

SCRIPT_VERSION="8.0-Pro-Bilingual"
SCRIPT_NAME="server-deploy-pro-bilingual"
BACKUP_DIR="/backup/${SCRIPT_NAME}"
LOG_DIR="/var/log/${SCRIPT_NAME}"
INSTALL_LOG="${LOG_DIR}/install_$(date +%Y%m%d_%H%M%S).log"
DIALOG_TITLE=""
AUTO_RECOVERY=false

CURRENT_LANG="zh"
LANG_FILE="/tmp/${SCRIPT_NAME}_lang"

load_language_setting() {
    if [ -f "$LANG_FILE" ]; then
        CURRENT_LANG=$(cat "$LANG_FILE")
    else
        CURRENT_LANG="zh"
    fi
}

save_language_setting() {
    echo "$CURRENT_LANG" > "$LANG_FILE"
}

tr() {
    local zh_text="$1"
    local en_text="$2"
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo "$zh_text"
    else
        echo "$en_text"
    fi
}

set_dialog_title() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        DIALOG_TITLE="服务器专业部署工具 Pro版 v$SCRIPT_VERSION"
    else
        DIALOG_TITLE="Server Deployment Tool Pro v$SCRIPT_VERSION"
    fi
}

validate_access() {
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${PURPLE}       服务器专业部署工具 Pro版           ${NC}"
        echo -e "${PURPLE}             版本 $SCRIPT_VERSION              ${NC}"
    else
        echo -e "${PURPLE}       Server Deployment Tool Pro          ${NC}"
        echo -e "${PURPLE}              Version $SCRIPT_VERSION           ${NC}"
    fi
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    local user_input=""
    if [ -n "$ACCESS_CODE" ]; then
        user_input="$ACCESS_CODE"
    else
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${YELLOW}请输入访问代码: ${NC}"
        else
            echo -e "${YELLOW}Please enter access code: ${NC}"
        fi
        read -s user_input
        echo ""
    fi
    
    local salt="websoft9_pro_deploy_salt_2025"
    local expected_hash="d60a5b8f3c7e2a1f9b4d8c7a6e5f4b3c2d1e0a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0"
    local salted_input="${salt}${user_input}"
    local input_hash=$(echo -n "$salted_input" | sha256sum | awk '{print $1}')
    
    if [ "$input_hash" != "$expected_hash" ]; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${RED}❌ 访问验证失败！${NC}"
            echo -e "${YELLOW}请检查访问代码是否正确${NC}"
        else
            echo -e "${RED}❌ Access verification failed!${NC}"
            echo -e "${YELLOW}Please check your access code${NC}"
        fi
        
        local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
        local ip_addr=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "unknown")
        echo "[${timestamp}] FAILED_ACCESS: IP=$ip_addr, InputHash=${input_hash:0:16}..." >> "$LOG_DIR/access.log"
        
        sleep 2
        exit 1
    fi
    
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local ip_addr=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "unknown")
    echo "[${timestamp}] SUCCESS_ACCESS: IP=$ip_addr" >> "$LOG_DIR/access.log"
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${GREEN}✅ 访问验证通过！${NC}"
    else
        echo -e "${GREEN}✅ Access verification passed!${NC}"
    fi
    echo ""
    sleep 1
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
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${YELLOW}正在安装dialog工具...${NC}"
        else
            echo -e "${YELLOW}Installing dialog tool...${NC}"
        fi
        apt-get update -y >/dev/null 2>&1
        apt-get install -y dialog >/dev/null 2>&1
        if [ $? -ne 0 ]; then
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo -e "${RED}错误：无法安装dialog工具${NC}"
            else
                echo -e "${RED}Error: Unable to install dialog tool${NC}"
            fi
            exit 1
        fi
        if [ "$CURRENT_LANG" = "zh" ]; then
            log "dialog工具安装成功"
        else
            log "Dialog tool installed successfully"
        fi
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
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${GREEN}正在退出GUI界面，进入终端模式${NC}"
        echo -e "${YELLOW}操作完成后会自动返回GUI界面${NC}"
    else
        echo -e "${GREEN}Exiting GUI, entering terminal mode${NC}"
        echo -e "${YELLOW}Will return to GUI after operation${NC}"
    fi
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
}

return_to_gui() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${GREEN}操作完成！按回车键返回GUI界面...${NC}"
    else
        echo -e "${GREEN}Operation complete! Press Enter to return to GUI...${NC}"
    fi
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    read -p "" dummy
}

check_network() {
    info "$(tr "检查网络连接..." "Checking network connection...")"
    
    local test_urls=(
        "https://github.com"
        "https://download.docker.com"
        "https://resource.fit2cloud.com"
    )
    
    for url in "${test_urls[@]}"; do
        if ! curl -s --connect-timeout 10 --head "$url" >/dev/null 2>&1; then
            warn "$(tr "无法访问: $url" "Unable to access: $url")"
        fi
    done
    log "$(tr "网络检查完成" "Network check completed")"
}

check_disk_space() {
    local min_space=${1:-5}
    
    info "$(tr "检查磁盘空间..." "Checking disk space...")"
    
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//' 2>/dev/null || echo "0")
    
    if [ "$free_space" -lt "$min_space" ]; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            error "磁盘空间不足！当前剩余: ${free_space}GB，需要至少: ${min_space}GB"
        else
            error "Insufficient disk space! Available: ${free_space}GB, Required: ${min_space}GB"
        fi
        return 1
    fi
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        log "磁盘空间充足: ${free_space}GB ✓"
    else
        log "Sufficient disk space: ${free_space}GB ✓"
    fi
    return 0
}

check_service_status() {
    local service_name="$1"
    local display_name="${2:-$service_name}"
    
    if systemctl list-unit-files | grep -q "$service_name.service" 2>/dev/null; then
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo -e "  ${GREEN}✓ ${display_name}: 正在运行${NC}"
            else
                echo -e "  ${GREEN}✓ ${display_name}: Running${NC}"
            fi
            return 0
        else
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo -e "  ${YELLOW}⚠ ${display_name}: 已安装但未运行${NC}"
            else
                echo -e "  ${YELLOW}⚠ ${display_name}: Installed but not running${NC}"
            fi
            return 1
        fi
    else
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "  ${BLUE}ℹ ${display_name}: 未安装${NC}"
        else
            echo -e "  ${BLUE}ℹ ${display_name}: Not installed${NC}"
        fi
        return 2
    fi
}

start_service() {
    local service_name="$1"
    local display_name="${2:-$service_name}"
    
    info "$(tr "启动 ${display_name} 服务..." "Starting ${display_name} service...")"
    if systemctl start "$service_name" 2>/dev/null; then
        sleep 2
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            success "$(tr "${display_name} 服务启动成功" "${display_name} service started successfully")"
            return 0
        else
            error "$(tr "${display_name} 服务启动失败" "${display_name} service failed to start")"
            return 1
        fi
    else
        error "$(tr "无法启动 ${display_name} 服务" "Unable to start ${display_name} service")"
        return 1
    fi
}

restart_service() {
    local service_name="$1"
    local display_name="${2:-$service_name}"
    
    info "$(tr "重启 ${display_name} 服务..." "Restarting ${display_name} service...")"
    if systemctl restart "$service_name" 2>/dev/null; then
        sleep 2
        if systemctl is-active --quiet "$service_name" 2>/dev/null; then
            success "$(tr "${display_name} 服务重启成功" "${display_name} service restarted successfully")"
            return 0
        else
            error "$(tr "${display_name} 服务重启失败" "${display_name} service failed to restart")"
            return 1
        fi
    else
        error "$(tr "无法重启 ${display_name} 服务" "Unable to restart ${display_name} service")"
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

select_language_gui() {
    while true; do
        choice=$(show_gui_menu "$(tr "选择语言 / Select Language" "Select Language")" 10 50 3 \
                  "1" "中文 (Chinese)" \
                  "2" "English" \
                  "3" "$(tr "继续 / Continue" "Continue")")
        
        if [ -z "$choice" ]; then
            choice="3"
        fi
        
        case $choice in
            1)
                CURRENT_LANG="zh"
                save_language_setting
                set_dialog_title
                show_gui_msgbox "$(tr "语言设置" "Language Setting")" "$(tr "语言已设置为中文" "Language set to Chinese")" 8 40
                return
                ;;
            2)
                CURRENT_LANG="en"
                save_language_setting
                set_dialog_title
                show_gui_msgbox "$(tr "语言设置" "Language Setting")" "Language set to English" 8 40
                return
                ;;
            3)
                set_dialog_title
                return
                ;;
        esac
    done
}

install_docker_ce() {
    if check_docker_installed; then
        local docker_version=$(docker --version 2>/dev/null | cut -d' ' -f3 | tr -d ',' || echo "$(tr "未知版本" "Unknown version")")
        if [ "$CURRENT_LANG" = "zh" ]; then
            if ! show_gui_yesno "Docker状态" "Docker已经安装：\n版本: $docker_version\n\n是否重新安装？" 10 50; then
                return
            fi
        else
            if ! show_gui_yesno "Docker Status" "Docker is already installed:\nVersion: $docker_version\n\nReinstall?" 10 50; then
                return
            fi
        fi
    fi
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "安装Docker CE" "将安装Docker容器引擎\n\n安装后会自动配置镜像加速器\n\n是否继续？" 10 50; then
            return
        fi
    else
        if ! show_gui_yesno "Install Docker CE" "Will install Docker container engine\n\nWill configure mirror accelerators after installation\n\nContinue?" 10 50; then
            return
        fi
    fi
    
    exit_to_terminal
    
    info "$(tr "开始安装Docker CE..." "Starting Docker CE installation...")"
    
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
        success "✅ $(tr "Docker CE安装成功！" "Docker CE installed successfully!")"
    else
        error "❌ $(tr "Docker CE安装失败！" "Docker CE installation failed!")"
    fi
    
    return_to_gui
}

install_1panel_gui() {
    if check_1panel_installed; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            if ! show_gui_yesno "1Panel状态" "1Panel面板已经安装！\n\n是否重新安装？" 10 50; then
                return
            fi
        else
            if ! show_gui_yesno "1Panel Status" "1Panel is already installed!\n\nReinstall?" 10 50; then
                return
            fi
        fi
    fi
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "安装1Panel" "将安装1Panel面板\n\n重要提示：\n1. 安装过程中需要手动确认（输入 y）\n2. 需要设置面板访问密码\n3. 默认访问地址: https://服务器IP:9090\n\n是否继续？" 12 60; then
            return
        fi
    else
        if ! show_gui_yesno "Install 1Panel" "Will install 1Panel\n\nImportant:\n1. Manual confirmation required during installation (type y)\n2. Need to set panel access password\n3. Default access: https://server-IP:9090\n\nContinue?" 12 60; then
            return
        fi
    fi
    
    exit_to_terminal
    
    info "$(tr "开始安装1Panel面板..." "Starting 1Panel installation...")"
    
    curl -fsSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh
    chmod +x quick_start.sh
    ./quick_start.sh
    
    sleep 5
    
    if check_1panel_installed; then
        success "✅ $(tr "1Panel面板安装成功！" "1Panel installed successfully!")"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${GREEN}访问地址: https://${ip_address}:9090${NC}"
            echo -e "${GREEN}用户名: admin${NC}"
        else
            echo -e "${GREEN}Access URL: https://${ip_address}:9090${NC}"
            echo -e "${GREEN}Username: admin${NC}"
        fi
    else
        error "❌ $(tr "1Panel安装失败！" "1Panel installation failed!")"
    fi
    
    return_to_gui
}

install_baota_gui() {
    if [ -f "/etc/init.d/bt" ]; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            if ! show_gui_yesno "宝塔状态" "宝塔面板已经安装！\n\n是否重新安装？" 10 50; then
                return
            fi
        else
            if ! show_gui_yesno "Baota Status" "Baota panel is already installed!\n\nReinstall?" 10 50; then
                return
            fi
        fi
    fi
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "安装宝塔" "将安装宝塔面板\n\n重要提示：\n1. 安装过程需要5-10分钟\n2. 安装过程中需要确认（输入 y）\n3. 请保存显示的登录信息\n\n是否继续？" 12 60; then
            return
        fi
    else
        if ! show_gui_yesno "Install Baota" "Will install Baota panel\n\nImportant:\n1. Installation takes 5-10 minutes\n2. Confirmation required during installation (type y)\n3. Save the displayed login information\n\nContinue?" 12 60; then
            return
        fi
    fi
    
    exit_to_terminal
    
    info "$(tr "开始安装宝塔面板..." "Starting Baota panel installation...")"
    
    if command -v curl &>/dev/null; then
        curl -fsSL https://download.bt.cn/install/install_panel.sh -o install_panel.sh
    else
        wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh
    fi
    
    bash install_panel.sh
    
    sleep 5
    
    if [ -f "/etc/init.d/bt" ]; then
        success "✅ $(tr "宝塔面板安装成功！" "Baota panel installed successfully!")"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null)
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${GREEN}访问地址: http://${ip_address}:8888${NC}"
        else
            echo -e "${GREEN}Access URL: http://${ip_address}:8888${NC}"
        fi
    else
        error "❌ $(tr "宝塔面板安装失败！" "Baota panel installation failed!")"
    fi
    
    return_to_gui
}

install_xiaopi_gui() {
    if [ -f "/usr/bin/xp" ]; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            if ! show_gui_yesno "小皮状态" "小皮面板已经安装！\n\n是否重新安装？" 10 50; then
                return
            fi
        else
            if ! show_gui_yesno "Xiaopi Status" "Xiaopi panel is already installed!\n\nReinstall?" 10 50; then
                return
            fi
        fi
    fi
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "安装小皮" "将安装小皮面板\n\n重要提示：\n1. 安装过程需要3-5分钟\n2. 默认访问地址: http://服务器IP:9080\n3. 默认账号: admin 密码: admin\n\n是否继续？" 12 60; then
            return
        fi
    else
        if ! show_gui_yesno "Install Xiaopi" "Will install Xiaopi panel\n\nImportant:\n1. Installation takes 3-5 minutes\n2. Default access: http://server-IP:9080\n3. Default: admin/admin\n\nContinue?" 12 60; then
            return
        fi
    fi
    
    exit_to_terminal
    
    info "$(tr "开始安装小皮面板..." "Starting Xiaopi panel installation...")"
    
    if [ -f /usr/bin/curl ]; then
        curl -O https://dl.xp.cn/dl/xp/install.sh
    else
        wget -O install.sh https://dl.xp.cn/dl/xp/install.sh
    fi
    
    bash install.sh
    
    sleep 5
    
    if [ -f "/usr/bin/xp" ]; then
        success "✅ $(tr "小皮面板安装成功！" "Xiaopi panel installed successfully!")"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null)
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${GREEN}访问地址: http://${ip_address}:9080${NC}"
            echo -e "${GREEN}默认账号: admin 密码: admin${NC}"
        else
            echo -e "${GREEN}Access URL: http://${ip_address}:9080${NC}"
            echo -e "${GREEN}Default: admin/admin${NC}"
        fi
    else
        error "❌ $(tr "小皮面板安装失败！" "Xiaopi panel installation failed!")"
    fi
    
    return_to_gui
}

install_amh_gui() {
    if [ -f "/usr/local/amh/amh" ]; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            if ! show_gui_yesno "AMH状态" "AMH面板已经安装！\n\n是否重新安装？" 10 50; then
                return
            fi
        else
            if ! show_gui_yesno "AMH Status" "AMH panel is already installed!\n\nReinstall?" 10 50; then
                return
            fi
        fi
    fi
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "安装AMH" "将安装AMH面板\n\n重要提示：\n1. 安装过程需要1-3分钟\n2. 需要纯净系统(Debian/Centos/Ubuntu)\n3. 安装后请保存显示的登录信息\n\n是否继续？" 12 60; then
            return
        fi
    else
        if ! show_gui_yesno "Install AMH" "Will install AMH panel\n\nImportant:\n1. Installation takes 1-3 minutes\n2. Requires clean system (Debian/Centos/Ubuntu)\n3. Save login information after installation\n\nContinue?" 12 60; then
            return
        fi
    fi
    
    exit_to_terminal
    
    info "$(tr "开始安装AMH面板..." "Starting AMH panel installation...")"
    
    wget https://dl.amh.sh/amh.sh && bash amh.sh
    
    sleep 5
    
    if [ -f "/usr/local/amh/amh" ]; then
        success "✅ $(tr "AMH面板安装成功！" "AMH panel installed successfully!")"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null)
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${GREEN}访问地址: http://${ip_address}:8888${NC}"
        else
            echo -e "${GREEN}Access URL: http://${ip_address}:8888${NC}"
        fi
    else
        error "❌ $(tr "AMH面板安装失败！" "AMH panel installation failed!")"
    fi
    
    return_to_gui
}

install_websoft9_gui() {
    if [ -f "/opt/websoft9/websoft9" ]; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            if ! show_gui_yesno "Websoft9状态" "Websoft9已经安装！\n\n是否重新安装？" 10 50; then
                return
            fi
        else
            if ! show_gui_yesno "Websoft9 Status" "Websoft9 is already installed!\n\nReinstall?" 10 50; then
                return
            fi
        fi
    fi
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "安装Websoft9" "将安装Websoft9应用管理器\n\n安装命令：\nwget -O install.sh https://artifact.websoft9.com/release/websoft9/install.sh && bash install.sh\n\n是否继续？" 12 60; then
            return
        fi
    else
        if ! show_gui_yesno "Install Websoft9" "Will install Websoft9 application manager\n\nInstall command:\nwget -O install.sh https://artifact.websoft9.com/release/websoft9/install.sh && bash install.sh\n\nContinue?" 12 60; then
            return
        fi
    fi
    
    exit_to_terminal
    
    info "$(tr "开始安装Websoft9..." "Starting Websoft9 installation...")"
    
    wget -O install.sh https://artifact.websoft9.com/release/websoft9/install.sh && bash install.sh
    
    sleep 5
    
    if [ -f "/opt/websoft9/websoft9" ]; then
        success "✅ $(tr "Websoft9安装成功！" "Websoft9 installed successfully!")"
        local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null)
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${GREEN}访问地址: http://${ip_address}:9000${NC}"
        else
            echo -e "${GREEN}Access URL: http://${ip_address}:9000${NC}"
        fi
    else
        error "❌ $(tr "Websoft9安装失败！" "Websoft9 installation failed!")"
    fi
    
    return_to_gui
}

install_development_tools_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "安装开发工具" "将安装常用开发环境\n包括：\n1. Node.js运行环境\n2. Python环境\n3. Java运行环境\n4. PHP环境\n\n是否继续？" 12 60; then
            return
        fi
    else
        if ! show_gui_yesno "Install Dev Tools" "Will install common development environment\nIncludes:\n1. Node.js runtime\n2. Python environment\n3. Java runtime\n4. PHP environment\n\nContinue?" 12 60; then
            return
        fi
    fi
    
    exit_to_terminal
    
    info "$(tr "开始安装开发工具..." "Starting development tools installation...")"
    
    info "$(tr "安装Node.js运行环境..." "Installing Node.js runtime...")"
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt-get install -y nodejs
    npm install -g npm yarn pm2
    
    info "$(tr "安装Python环境..." "Installing Python environment...")"
    apt-get install -y python3 python3-pip python3-venv
    pip3 install --upgrade pip
    pip3 install virtualenv flask django numpy pandas 2>/dev/null || true
    
    info "$(tr "安装Java运行环境..." "Installing Java runtime...")"
    apt-get install -y default-jdk default-jre
    
    info "$(tr "安装PHP环境..." "Installing PHP environment...")"
    apt-get install -y php php-cli php-fpm php-mysql php-curl php-gd php-mbstring php-xml php-zip
    
    success "✅ $(tr "开发工具安装完成！" "Development tools installed!")"
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${GREEN}Node.js版本: $(node --version 2>/dev/null || echo '未知')${NC}"
        echo -e "${GREEN}Python版本: $(python3 --version 2>/dev/null || echo '未知')${NC}"
        echo -e "${GREEN}Java版本: $(java -version 2>&1 | head -n 1 | cut -d'"' -f2 2>/dev/null || echo '未知')${NC}"
        echo -e "${GREEN}PHP版本: $(php --version 2>/dev/null | head -n 1 || echo '未知')${NC}"
    else
        echo -e "${GREEN}Node.js version: $(node --version 2>/dev/null || echo 'unknown')${NC}"
        echo -e "${GREEN}Python version: $(python3 --version 2>/dev/null || echo 'unknown')${NC}"
        echo -e "${GREEN}Java version: $(java -version 2>&1 | head -n 1 | cut -d'"' -f2 2>/dev/null || echo 'unknown')${NC}"
        echo -e "${GREEN}PHP version: $(php --version 2>/dev/null | head -n 1 || echo 'unknown')${NC}"
    fi
    
    return_to_gui
}

install_database_tools_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "安装数据库" "将安装常用数据库\n包括：\n1. MySQL数据库\n2. PostgreSQL数据库\n3. Redis缓存\n4. MongoDB数据库\n\n是否继续？" 12 60; then
            return
        fi
    else
        if ! show_gui_yesno "Install Databases" "Will install common databases\nIncludes:\n1. MySQL database\n2. PostgreSQL database\n3. Redis cache\n4. MongoDB database\n\nContinue?" 12 60; then
            return
        fi
    fi
    
    exit_to_terminal
    
    info "$(tr "开始安装数据库工具..." "Starting database tools installation...")"
    
    info "$(tr "安装MySQL数据库..." "Installing MySQL database...")"
    apt-get install -y mysql-server
    if systemctl is-active --quiet mysql; then
        mysql_secure_installation <<EOF
y
y
y
y
y
EOF
    fi
    
    info "$(tr "安装PostgreSQL数据库..." "Installing PostgreSQL database...")"
    apt-get install -y postgresql postgresql-contrib
    if systemctl is-active --quiet postgresql; then
        sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';" 2>/dev/null || true
    fi
    
    info "$(tr "安装Redis缓存..." "Installing Redis cache...")"
    apt-get install -y redis-server
    sed -i 's/bind 127.0.0.1 ::1/bind 0.0.0.0/' /etc/redis/redis.conf 2>/dev/null || true
    systemctl restart redis-server
    
    info "$(tr "安装MongoDB数据库..." "Installing MongoDB database...")"
    wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/mongodb.gpg >/dev/null
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    apt-get update
    apt-get install -y mongodb-org
    systemctl start mongod
    systemctl enable mongod
    
    success "✅ $(tr "数据库工具安装完成！" "Database tools installed!")"
    return_to_gui
}

install_web_servers_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "安装Web服务器" "将安装常用Web服务器\n包括：\n1. Nginx Web服务器\n2. Apache Web服务器\n\n是否继续？" 10 50; then
            return
        fi
    else
        if ! show_gui_yesno "Install Web Servers" "Will install common web servers\nIncludes:\n1. Nginx web server\n2. Apache web server\n\nContinue?" 10 50; then
            return
        fi
    fi
    
    exit_to_terminal
    
    info "$(tr "开始安装Web服务器..." "Starting web servers installation...")"
    
    info "$(tr "安装Nginx Web服务器..." "Installing Nginx web server...")"
    apt-get install -y nginx
    mkdir -p /var/www/html
    echo "<h1>Welcome to Nginx Server</h1>" > /var/www/html/index.html
    systemctl restart nginx
    
    info "$(tr "安装Apache Web服务器..." "Installing Apache web server...")"
    apt-get install -y apache2
    echo "<h1>Welcome to Apache Server</h1>" > /var/www/html/index.html
    systemctl restart apache2
    
    success "✅ $(tr "Web服务器安装完成！" "Web servers installed!")"
    
    local ip_address=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "localhost")
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${GREEN}Nginx访问地址: http://${ip_address}${NC}"
        echo -e "${GREEN}Apache访问地址: http://${ip_address}:8080${NC}"
    else
        echo -e "${GREEN}Nginx access: http://${ip_address}${NC}"
        echo -e "${GREEN}Apache access: http://${ip_address}:8080${NC}"
    fi
    
    return_to_gui
}

server_app_install_menu() {
    while true; do
        choice=$(show_gui_menu "$(tr "服务器应用安装" "Server App Installation")" 20 70 12 \
                  "1" "$(tr "安装Docker容器引擎" "Install Docker CE")" \
                  "2" "$(tr "安装1Panel面板" "Install 1Panel")" \
                  "3" "$(tr "安装宝塔面板" "Install Baota")" \
                  "4" "$(tr "安装小皮面板" "Install Xiaopi")" \
                  "5" "$(tr "安装AMH面板" "Install AMH")" \
                  "6" "$(tr "安装Websoft9" "Install Websoft9")" \
                  "7" "$(tr "安装开发工具环境" "Install Dev Tools")" \
                  "8" "$(tr "安装数据库工具" "Install Databases")" \
                  "9" "$(tr "安装Web服务器" "Install Web Servers")" \
                  "10" "$(tr "返回主菜单" "Back to Main Menu")")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1) install_docker_ce ;;
            2) install_1panel_gui ;;
            3) install_baota_gui ;;
            4) install_xiaopi_gui ;;
            5) install_amh_gui ;;
            6) install_websoft9_gui ;;
            7) install_development_tools_gui ;;
            8) install_database_tools_gui ;;
            9) install_web_servers_gui ;;
            10) return ;;
        esac
    done
}

system_optimization_gui() {
    while true; do
        choice=$(show_gui_menu "$(tr "系统优化配置" "System Optimization")" 20 70 10 \
                  "1" "$(tr "更新软件包列表" "Update package list")" \
                  "2" "$(tr "升级现有软件包" "Upgrade packages")" \
                  "3" "$(tr "安装运维工具包" "Install admin tools")" \
                  "4" "$(tr "设置时区和时间同步" "Set timezone & sync")" \
                  "5" "$(tr "配置SSH安全加固" "Configure SSH security")" \
                  "6" "$(tr "优化内核参数" "Optimize kernel params")" \
                  "7" "$(tr "配置资源限制" "Configure resource limits")" \
                  "8" "$(tr "配置防火墙" "Configure firewall")" \
                  "9" "$(tr "一键优化所有项目" "One-click optimization")" \
                  "10" "$(tr "返回主菜单" "Back to Main Menu")")
        
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
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "更新软件包" "将更新系统软件包列表\n\n是否继续？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Update Packages" "Will update system package list\n\nContinue?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "更新软件包列表..." "Updating package list...")"
    show_separator
    apt-get update -y
    check_status "$(tr "软件包列表更新完成" "Package list updated")" "$(tr "更新失败" "Update failed")"
    show_separator
    return_to_gui
}

upgrade_packages_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "升级软件包" "将升级现有软件包\n\n是否继续？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Upgrade Packages" "Will upgrade existing packages\n\nContinue?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "升级现有软件包..." "Upgrading packages...")"
    show_separator
    apt-get upgrade -y
    check_status "$(tr "软件包升级完成" "Packages upgraded")" "$(tr "升级失败" "Upgrade failed")"
    show_separator
    return_to_gui
}

install_tools_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "安装运维工具" "将安装常用运维工具包\n\n是否继续？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Install Tools" "Will install common admin tools\n\nContinue?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "安装运维工具包..." "Installing admin tools...")"
    local packages=(
        curl wget vim git net-tools htop iftop iotop screen tmux ufw
        ntpdate software-properties-common apt-transport-https ca-certificates
        gnupg lsb-release chrony build-essential pkg-config
        ncdu tree jq bc rsync fail2ban
    )
    
    show_separator
    apt-get install -y "${packages[@]}"
    check_status "$(tr "运维工具安装完成" "Admin tools installed")" "$(tr "软件安装失败" "Installation failed")"
    show_separator
    return_to_gui
}

setup_timezone_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "设置时区" "将设置时区为上海并配置时间同步\n\n是否继续？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Setup Timezone" "Will set timezone to Shanghai and configure time sync\n\nContinue?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "设置时区为上海..." "Setting timezone to Shanghai...")"
    timedatectl set-timezone Asia/Shanghai
    check_status "$(tr "时区设置成功" "Timezone set")" "$(tr "时区设置失败" "Timezone setup failed")"
    
    info "$(tr "配置时间同步服务..." "Configuring time sync service...")"
    systemctl stop systemd-timesyncd 2>/dev/null || true
    systemctl disable systemd-timesyncd 2>/dev/null || true
    systemctl enable chronyd
    systemctl restart chronyd
    check_status "$(tr "时间同步配置完成" "Time sync configured")" "$(tr "时间同步配置失败" "Time sync setup failed")"
    
    return_to_gui
}

configure_ssh_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "SSH安全加固" "将配置SSH安全加固设置\n\n是否继续？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "SSH Security" "Will configure SSH security settings\n\nContinue?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "配置SSH安全加固..." "Configuring SSH security...")"
    if [ -f "/etc/ssh/sshd_config" ]; then
        echo -e "${CYAN}$(tr "修改SSH配置..." "Modifying SSH config...")${NC}"
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config 2>/dev/null || true
        
        systemctl restart sshd
        check_status "$(tr "SSH安全加固完成" "SSH security configured")" "$(tr "SSH配置失败" "SSH setup failed")"
    fi
    
    return_to_gui
}

optimize_kernel_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "内核优化" "将优化内核参数\n\n是否继续？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Kernel Optimization" "Will optimize kernel parameters\n\nContinue?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "优化内核参数..." "Optimizing kernel parameters...")"
    
    cat >> /etc/sysctl.conf << 'EOF'
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_fastopen = 3
net.core.default_qdisc = fq
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
EOF
    
    sysctl -p 2>/dev/null
    check_status "$(tr "内核参数已应用" "Kernel params applied")" "$(tr "内核参数应用失败" "Kernel params failed")"
    return_to_gui
}

configure_resources_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "资源限制" "将配置系统资源限制\n\n是否继续？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Resource Limits" "Will configure system resource limits\n\nContinue?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "配置资源限制..." "Configuring resource limits...")"
    
    cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
root soft nofile 65536
root hard nofile 65536
EOF
    
    log "$(tr "资源限制配置完成" "Resource limits configured")"
    return_to_gui
}

configure_firewall_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "防火墙配置" "将配置防火墙设置\n\n是否继续？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Firewall Config" "Will configure firewall settings\n\nContinue?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "配置防火墙..." "Configuring firewall...")"
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo "1. 启用UFW防火墙（推荐）"
        echo "2. 禁用UFW防火墙"
        echo "3. 保持当前状态"
        read -p "请选择 (1-3): " fw_choice
    else
        echo "1. Enable UFW firewall (Recommended)"
        echo "2. Disable UFW firewall"
        echo "3. Keep current state"
        read -p "Choose (1-3): " fw_choice
    fi
    
    case $fw_choice in
        1)
            ufw --force enable
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow 22/tcp
            ufw allow 80/tcp
            ufw allow 443/tcp
            log "$(tr "UFW防火墙已启用并配置规则" "UFW enabled and rules configured")"
            ;;
        2)
            ufw --force disable
            log "$(tr "UFW防火墙已禁用" "UFW disabled")"
            ;;
        *)
            log "$(tr "保持防火墙当前状态" "Keeping firewall state")"
            ;;
    esac
    
    return_to_gui
}

full_optimization_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "一键优化" "将执行所有系统优化操作\n\n是否继续？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "One-click Optimization" "Will perform all optimization operations\n\nContinue?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "开始系统一键优化..." "Starting one-click optimization...")"
    
    info "$(tr "更新软件包列表..." "Updating package list...")"
    apt-get update -y
    apt-get upgrade -y
    
    info "$(tr "安装运维工具包..." "Installing admin tools...")"
    local packages=(
        curl wget vim git net-tools htop iftop iotop screen tmux ufw
        ntpdate software-properties-common apt-transport-https ca-certificates
        gnupg lsb-release chrony build-essential pkg-config
        ncdu tree jq bc rsync fail2ban
    )
    apt-get install -y "${packages[@]}"
    
    info "$(tr "设置时区为上海..." "Setting timezone to Shanghai...")"
    timedatectl set-timezone Asia/Shanghai
    systemctl enable chronyd
    systemctl restart chronyd
    
    info "$(tr "配置SSH安全..." "Configuring SSH security...")"
    if [ -f "/etc/ssh/sshd_config" ]; then
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config 2>/dev/null || true
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 300/' /etc/ssh/sshd_config 2>/dev/null || true
        systemctl restart sshd
    fi
    
    info "$(tr "优化内核参数..." "Optimizing kernel parameters...")"
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
    
    info "$(tr "配置防火墙..." "Configuring firewall...")"
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow http
    ufw allow https
    
    info "$(tr "配置资源限制..." "Configuring resource limits...")"
    cat >> /etc/security/limits.conf << 'EOF'
* soft nofile 65536
* hard nofile 65536
root soft nofile 65536
root hard nofile 65536
EOF
    
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${GREEN}          系统一键优化完成！${NC}"
    else
        echo -e "${GREEN}          One-click optimization complete!${NC}"
    fi
    echo -e "${GREEN}══════════════════════════════════════════════${NC}"
    
    return_to_gui
}

quick_start_menu() {
    while true; do
        choice=$(show_gui_menu "$(tr "快速启动管理器" "Quick Start Manager")" 15 60 6 \
                  "1" "$(tr "检查所有服务状态" "Check all services")" \
                  "2" "$(tr "恢复所有停止的服务" "Recover stopped services")" \
                  "3" "$(tr "重启所有服务" "Restart all services")" \
                  "4" "$(tr "设置自动恢复模式" "Set auto recovery")" \
                  "5" "$(tr "查看服务日志" "View service logs")" \
                  "6" "$(tr "返回主菜单" "Back to Main Menu")")
        
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
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${CYAN}               服务状态报告                  ${NC}"
    else
        echo -e "${CYAN}              Service Status Report            ${NC}"
    fi
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${BLUE}系统信息：${NC}"
        echo "  系统: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
        echo "  时间: $(date)"
        echo "  运行时间: $(uptime -p 2>/dev/null || uptime)"
        echo ""
        echo -e "${BLUE}系统服务：${NC}"
    else
        echo -e "${BLUE}System Info:${NC}"
        echo "  OS: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
        echo "  Time: $(date)"
        echo "  Uptime: $(uptime -p 2>/dev/null || uptime)"
        echo ""
        echo -e "${BLUE}System Services:${NC}"
    fi
    check_service_status "chronyd" "$(tr "时间同步" "Time sync")"
    check_service_status "ssh" "SSH"
    check_service_status "ufw" "$(tr "防火墙" "Firewall")"
    echo ""
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${BLUE}容器服务：${NC}"
    else
        echo -e "${BLUE}Container Services:${NC}"
    fi
    if check_docker_installed; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "  ${GREEN}✓ Docker: 正在运行${NC}"
            echo "    运行中的容器: $(docker ps -q 2>/dev/null | wc -l)"
        else
            echo -e "  ${GREEN}✓ Docker: Running${NC}"
            echo "    Running containers: $(docker ps -q 2>/dev/null | wc -l)"
        fi
    else
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "  ${YELLOW}⚠ Docker: 未运行${NC}"
        else
            echo -e "  ${YELLOW}⚠ Docker: Not running${NC}"
        fi
    fi
    echo ""
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${BLUE}管理面板：${NC}"
    else
        echo -e "${BLUE}Admin Panels:${NC}"
    fi
    if check_1panel_installed; then
        check_service_status "1panel" "1Panel"
    else
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "  ${BLUE}ℹ 1Panel: 未安装${NC}"
        else
            echo -e "  ${BLUE}ℹ 1Panel: Not installed${NC}"
        fi
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        if /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo -e "  ${GREEN}✓ 宝塔面板: 正在运行${NC}"
            else
                echo -e "  ${GREEN}✓ Baota: Running${NC}"
            fi
        else
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo -e "  ${YELLOW}⚠ 宝塔面板: 已安装但未运行${NC}"
            else
                echo -e "  ${YELLOW}⚠ Baota: Installed but not running${NC}"
            fi
        fi
    else
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "  ${BLUE}ℹ 宝塔面板: 未安装${NC}"
        else
            echo -e "  ${BLUE}ℹ Baota: Not installed${NC}"
        fi
    fi
    echo ""
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${BLUE}端口状态：${NC}"
    else
        echo -e "${BLUE}Port Status:${NC}"
    fi
    local ports_to_check=(22 80 443 9090 8888)
    local port_names_zh=("SSH" "HTTP" "HTTPS" "1Panel" "宝塔")
    local port_names_en=("SSH" "HTTP" "HTTPS" "1Panel" "Baota")
    
    for i in "${!ports_to_check[@]}"; do
        local port="${ports_to_check[i]}"
        local name_zh="${port_names_zh[i]}"
        local name_en="${port_names_en[i]}"
        local name=""
        
        if [ "$CURRENT_LANG" = "zh" ]; then
            name="$name_zh"
        else
            name="$name_en"
        fi
        
        if ss -tulpn 2>/dev/null | grep -q ":$port "; then
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo -e "  ${GREEN}✓ 端口 ${port} (${name}): 已监听${NC}"
            else
                echo -e "  ${GREEN}✓ Port ${port} (${name}): Listening${NC}"
            fi
        else
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo -e "  ${YELLOW}⚠ 端口 ${port} (${name}): 未监听${NC}"
            else
                echo -e "  ${YELLOW}⚠ Port ${port} (${name}): Not listening${NC}"
            fi
        fi
    done
    
    echo ""
    show_separator
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${GREEN}检查完成！${NC}"
    else
        echo -e "${GREEN}Check complete!${NC}"
    fi
    
    return_to_gui
}

recover_all_services_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "恢复服务" "确定要恢复所有停止的服务吗？" 8 40; then
            log "取消服务恢复"
            return
        fi
    else
        if ! show_gui_yesno "Recover Services" "Recover all stopped services?" 8 40; then
            log "Service recovery cancelled"
            return
        fi
    fi
    
    exit_to_terminal
    warn "$(tr "开始恢复所有服务..." "Starting service recovery...")"
    
    local system_services=("chronyd" "ssh" "ufw")
    for service in "${system_services[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service" 2>/dev/null && ! systemctl is-active --quiet "$service" 2>/dev/null; then
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
            info "$(tr "启动宝塔面板..." "Starting Baota panel...")"
            /etc/init.d/bt start 2>/dev/null
            if /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
                success "$(tr "宝塔面板启动成功" "Baota panel started")"
            else
                error "$(tr "宝塔面板启动失败" "Baota panel failed to start")"
            fi
        fi
    fi
    
    success "$(tr "所有服务恢复完成" "All services recovered")"
    return_to_gui
}

restart_all_services_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "重启服务" "⚠ 警告：这将重启所有服务，可能导致短暂的服务中断\n\n确定要重启所有服务吗？" 10 50; then
            log "取消服务重启"
            return
        fi
    else
        if ! show_gui_yesno "Restart Services" "⚠ Warning: This will restart all services, may cause brief interruption\n\nRestart all services?" 10 50; then
            log "Service restart cancelled"
            return
        fi
    fi
    
    exit_to_terminal
    warn "$(tr "开始重启所有服务..." "Starting service restart...")"
    
    local system_services=("chronyd" "ssh")
    for service in "${system_services[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service" 2>/dev/null; then
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
        info "$(tr "重启宝塔面板..." "Restarting Baota panel...")"
        /etc/init.d/bt restart 2>/dev/null
        sleep 3
        if /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
            success "$(tr "宝塔面板重启成功" "Baota panel restarted")"
        else
            error "$(tr "宝塔面板重启失败" "Baota panel failed to restart")"
        fi
    fi
    
    success "$(tr "所有服务重启完成" "All services restarted")"
    return_to_gui
}

set_auto_recovery_mode_gui() {
    while true; do
        choice=$(show_gui_menu "$(tr "自动恢复模式设置" "Auto Recovery Settings")" 15 60 5 \
                  "1" "$(tr "启用自动恢复模式" "Enable auto recovery")" \
                  "2" "$(tr "禁用自动恢复模式" "Disable auto recovery")" \
                  "3" "$(tr "创建开机自启动脚本" "Create autostart script")" \
                  "4" "$(tr "删除开机自启动脚本" "Remove autostart script")" \
                  "5" "$(tr "返回" "Back")")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1)
                AUTO_RECOVERY=true
                show_gui_msgbox "$(tr "提示" "Notice")" "$(tr "已启用自动恢复模式" "Auto recovery enabled")" 8 40
                ;;
            2)
                AUTO_RECOVERY=false
                show_gui_msgbox "$(tr "提示" "Notice")" "$(tr "已禁用自动恢复模式" "Auto recovery disabled")" 8 40
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
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "创建自启动脚本" "将创建开机自启动脚本，系统启动时自动恢复服务。\n\n是否继续？" 10 50; then
            return
        fi
    else
        if ! show_gui_yesno "Create Autostart Script" "Will create autostart script to auto-recover services on boot.\n\nContinue?" 10 50; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "创建开机自启动脚本..." "Creating autostart script...")"
    
    local service_file="/etc/systemd/system/yx-deploy-recovery.service"
    local recovery_script="/usr/local/bin/yx-deploy-recovery.sh"
    
    if [ -f "$service_file" ]; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${YELLOW}检测到已存在的自启动服务，将覆盖...${NC}"
        else
            echo -e "${YELLOW}Existing autostart service detected, overwriting...${NC}"
        fi
    fi
    
    cat > "$recovery_script" << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/yx-deploy-gui/recovery.log"
mkdir -p /var/log/yx-deploy-gui 2>/dev/null
echo "==========================================" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S'): 开始自动恢复服务" >> "$LOG_FILE"
echo "==========================================" >> "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S'): 等待网络就绪..." >> "$LOG_FILE"
sleep 15
services=("docker" "1panel" "chronyd" "ssh" "ufw")
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
Description=yx-deploy Auto Recovery Service
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
    systemctl enable yx-deploy-recovery.service 2>/dev/null
    systemctl start yx-deploy-recovery.service 2>/dev/null
    
    success "$(tr "开机自启动脚本创建成功" "Autostart script created")"
    return_to_gui
}

remove_autostart_script_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "删除自启动脚本" "确定要删除开机自启动脚本吗？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Remove Autostart Script" "Remove autostart script?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "删除开机自启动脚本..." "Removing autostart script...")"
    
    local service_file="/etc/systemd/system/yx-deploy-recovery.service"
    local recovery_script="/usr/local/bin/yx-deploy-recovery.sh"
    
    systemctl stop yx-deploy-recovery.service 2>/dev/null
    systemctl disable yx-deploy-recovery.service 2>/dev/null
    systemctl daemon-reload
    
    rm -f "$service_file" 2>/dev/null
    rm -f "$recovery_script" 2>/dev/null
    
    success "$(tr "开机自启动脚本已删除" "Autostart script removed")"
    return_to_gui
}

view_service_logs_gui() {
    while true; do
        choice=$(show_gui_menu "$(tr "查看服务日志" "View Service Logs")" 12 60 5 \
                  "1" "$(tr "查看Docker日志" "View Docker logs")" \
                  "2" "$(tr "查看1Panel日志" "View 1Panel logs")" \
                  "3" "$(tr "查看系统日志" "View system logs")" \
                  "4" "$(tr "查看恢复日志" "View recovery logs")" \
                  "5" "$(tr "返回" "Back")")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1)
                exit_to_terminal
                echo -e "${CYAN}$(tr "Docker日志：" "Docker logs:")${NC}"
                journalctl -u docker -n 30 --no-pager 2>/dev/null || echo "$(tr "Docker日志不可用" "Docker logs unavailable")"
                return_to_gui
                ;;
            2)
                exit_to_terminal
                echo -e "${CYAN}$(tr "1Panel日志：" "1Panel logs:")${NC}"
                journalctl -u 1panel -n 30 --no-pager 2>/dev/null || echo "$(tr "1Panel日志不可用" "1Panel logs unavailable")"
                return_to_gui
                ;;
            3)
                exit_to_terminal
                echo -e "${CYAN}$(tr "系统日志：" "System logs:")${NC}"
                dmesg | tail -30 2>/dev/null || echo "$(tr "系统日志不可用" "System logs unavailable")"
                return_to_gui
                ;;
            4)
                exit_to_terminal
                echo -e "${CYAN}$(tr "恢复日志：" "Recovery logs:")${NC}"
                if [ -f "/var/log/yx-deploy-gui/recovery.log" ]; then
                    tail -30 "/var/log/yx-deploy-gui/recovery.log"
                else
                    echo "$(tr "恢复日志文件不存在" "Recovery log file not found")"
                fi
                return_to_gui
                ;;
            5)
                return
                ;;
        esac
    done
}

system_integrity_check_gui() {
    exit_to_terminal
    
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${CYAN}       系统完整性检查报告${NC}"
    else
        echo -e "${CYAN}       System Integrity Check Report${NC}"
    fi
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${BLUE}1. 系统信息：${NC}"
        echo "   OS: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
        echo "   内核: $(uname -r)"
        echo "   架构: $(uname -m)"
        echo ""
        echo -e "${BLUE}2. 资源使用：${NC}"
    else
        echo -e "${BLUE}1. System Info:${NC}"
        echo "   OS: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
        echo "   Kernel: $(uname -r)"
        echo "   Arch: $(uname -m)"
        echo ""
        echo -e "${BLUE}2. Resource Usage:${NC}"
    fi
    echo -n "   $(tr "内存: " "Memory: ")"
    free -h | awk 'NR==2{print $4 " / " $2}' 2>/dev/null || echo "$(tr "未知" "Unknown")"
    echo -n "   $(tr "磁盘: " "Disk: ")"
    df -h / | awk 'NR==2{print $4 " / " $2}' 2>/dev/null || echo "$(tr "未知" "Unknown")"
    
    echo ""
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${BLUE}3. 服务状态：${NC}"
    else
        echo -e "${BLUE}3. Service Status:${NC}"
    fi
    
    if check_docker_installed; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo "   ✓ Docker: 已安装且运行正常"
        else
            echo "   ✓ Docker: Installed and running"
        fi
    else
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo "   ✗ Docker: 未安装或未运行"
        else
            echo "   ✗ Docker: Not installed or not running"
        fi
    fi
    
    if check_1panel_installed; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo "   ✓ 1Panel: 已安装"
        else
            echo "   ✓ 1Panel: Installed"
        fi
        if systemctl is-active --quiet 1panel 2>/dev/null; then
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo "       服务状态: 运行中"
            else
                echo "       Service: Running"
            fi
        else
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo "       服务状态: 未运行"
            else
                echo "       Service: Not running"
            fi
        fi
    else
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo "   ✗ 1Panel: 未安装"
        else
            echo "   ✗ 1Panel: Not installed"
        fi
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo "   ✓ 宝塔: 已安装"
        else
            echo "   ✓ Baota: Installed"
        fi
        if /etc/init.d/bt status 2>/dev/null | grep -q "running"; then
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo "       服务状态: 运行中"
            else
                echo "       Service: Running"
            fi
        else
            if [ "$CURRENT_LANG" = "zh" ]; then
                echo "       服务状态: 未运行"
            else
                echo "       Service: Not running"
            fi
        fi
    else
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo "   ✗ 宝塔: 未安装"
        else
            echo "   ✗ Baota: Not installed"
        fi
    fi
    
    echo ""
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${BLUE}4. 网络状态：${NC}"
        echo "   IP地址: $(hostname -I | awk '{print $1}' 2>/dev/null || echo "未知")"
    else
        echo -e "${BLUE}4. Network Status:${NC}"
        echo "   IP Address: $(hostname -I | awk '{print $1}' 2>/dev/null || echo "Unknown")"
    fi
    
    echo ""
    show_separator
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${GREEN}检查完成！${NC}"
    else
        echo -e "${GREEN}Check complete!${NC}"
    fi
    
    return_to_gui
}

uninstall_menu_gui() {
    while true; do
        choice=$(show_gui_menu "$(tr "卸载工具" "Uninstall Tools")" 12 60 5 \
                  "1" "$(tr "卸载Docker" "Uninstall Docker")" \
                  "2" "$(tr "卸载1Panel面板" "Uninstall 1Panel")" \
                  "3" "$(tr "卸载宝塔面板" "Uninstall Baota")" \
                  "4" "$(tr "清理所有安装" "Cleanup all installs")" \
                  "5" "$(tr "返回主菜单" "Back to Main Menu")")
        
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
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "卸载Docker" "确定要卸载Docker吗？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Uninstall Docker" "Uninstall Docker?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    warn "$(tr "开始卸载Docker..." "Starting Docker uninstallation...")"
    
    info "$(tr "停止Docker服务..." "Stopping Docker service...")"
    systemctl stop docker 2>/dev/null
    systemctl stop containerd 2>/dev/null
    
    info "$(tr "卸载Docker软件包..." "Uninstalling Docker packages...")"
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
    apt-get purge -y docker-ce docker-ce-cli containerd.io 2>/dev/null
    
    info "$(tr "清理Docker数据..." "Cleaning Docker data...")"
    rm -rf /var/lib/docker 2>/dev/null
    rm -rf /var/lib/containerd 2>/dev/null
    rm -rf /etc/docker 2>/dev/null
    
    success "$(tr "Docker卸载完成" "Docker uninstalled")"
    return_to_gui
}

uninstall_1panel_gui() {
    if ! check_1panel_installed; then
        show_gui_msgbox "$(tr "提示" "Notice")" "$(tr "1Panel面板未安装" "1Panel not installed")" 8 40
        return
    fi
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "卸载1Panel" "确定要卸载1Panel面板吗？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Uninstall 1Panel" "Uninstall 1Panel?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    warn "$(tr "开始卸载1Panel面板..." "Starting 1Panel uninstallation...")"
    
    info "$(tr "停止1Panel服务..." "Stopping 1Panel service...")"
    systemctl stop 1panel 2>/dev/null || true
    systemctl disable 1panel 2>/dev/null || true
    
    rm -rf /opt/1panel 2>/dev/null
    rm -rf /usr/local/bin/1panel 2>/dev/null
    rm -rf /usr/local/bin/1pctl 2>/dev/null
    rm -f /etc/systemd/system/1panel.service 2>/dev/null
    
    success "$(tr "1Panel面板卸载完成" "1Panel uninstalled")"
    return_to_gui
}

uninstall_baota_gui() {
    if [ ! -f "/etc/init.d/bt" ]; then
        show_gui_msgbox "$(tr "提示" "Notice")" "$(tr "宝塔面板未安装" "Baota not installed")" 8 40
        return
    fi
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "卸载宝塔" "确定要卸载宝塔面板吗？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Uninstall Baota" "Uninstall Baota?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    warn "$(tr "开始卸载宝塔面板..." "Starting Baota uninstallation...")"
    
    info "$(tr "停止宝塔面板..." "Stopping Baota panel...")"
    /etc/init.d/bt stop 2>/dev/null || true
    
    rm -rf /www/server/panel 2>/dev/null
    rm -f /etc/init.d/bt 2>/dev/null
    
    success "$(tr "宝塔面板卸载完成" "Baota uninstalled")"
    return_to_gui
}

cleanup_all_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "清理所有安装" "⚠ 警告：这将卸载所有通过本脚本安装的软件\n包括：\n1. Docker\n2. 1Panel面板\n3. 宝塔面板\n\n确定要清理所有安装吗？" 12 60; then
            return
        fi
    else
        if ! show_gui_yesno "Cleanup All Installs" "⚠ Warning: This will uninstall all software installed by this script\nIncludes:\n1. Docker\n2. 1Panel\n3. Baota\n\nCleanup all installs?" 12 60; then
            return
        fi
    fi
    
    exit_to_terminal
    warn "$(tr "开始清理所有安装..." "Starting cleanup of all installs...")"
    
    if check_1panel_installed; then
        warn "$(tr "卸载1Panel面板..." "Uninstalling 1Panel...")"
        systemctl stop 1panel 2>/dev/null
        rm -rf /opt/1panel 2>/dev/null
        rm -rf /usr/local/bin/1panel 2>/dev/null
        rm -f /etc/systemd/system/1panel.service 2>/dev/null
    fi
    
    if [ -f "/etc/init.d/bt" ]; then
        warn "$(tr "卸载宝塔面板..." "Uninstalling Baota...")"
        /etc/init.d/bt stop 2>/dev/null
        rm -rf /www/server/panel 2>/dev/null
        rm -f /etc/init.d/bt 2>/dev/null
    fi
    
    if check_docker_installed; then
        warn "$(tr "卸载Docker..." "Uninstalling Docker...")"
        systemctl stop docker 2>/dev/null
        apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null
        rm -rf /var/lib/docker 2>/dev/null
        rm -rf /etc/docker 2>/dev/null
    fi
    
    info "$(tr "清理临时文件..." "Cleaning temp files...")"
    rm -f quick_start.sh 2>/dev/null
    rm -f install_panel.sh 2>/dev/null
    find "$LOG_DIR" -type f -name "*.log" -mtime +7 -delete 2>/dev/null
    
    success "$(tr "所有安装清理完成" "All installs cleaned up")"
    return_to_gui
}

cleanup_temp_files_gui() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "清理临时文件" "确定要清理临时文件吗？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Cleanup Temp Files" "Cleanup temporary files?" 8 40; then
            return
        fi
    fi
    
    exit_to_terminal
    info "$(tr "清理临时文件..." "Cleaning temporary files...")"
    
    rm -f quick_start.sh 2>/dev/null
    rm -f install_panel.sh 2>/dev/null
    find "$LOG_DIR" -type f -name "*.log" -mtime +7 -delete 2>/dev/null
    
    log "$(tr "临时文件清理完成" "Temp files cleaned")"
    return_to_gui
}

language_menu_gui() {
    while true; do
        choice=$(show_gui_menu "$(tr "语言设置" "Language Settings")" 10 60 4 \
                  "1" "$(tr "切换语言 (当前: $CURRENT_LANG)" "Switch Language (Current: $CURRENT_LANG)")" \
                  "2" "$(tr "查看语言信息" "View Language Info")" \
                  "3" "$(tr "返回主菜单" "Back to Main Menu")")
        
        if [ -z "$choice" ]; then
            return
        fi
        
        case $choice in
            1)
                if [ "$CURRENT_LANG" = "zh" ]; then
                    CURRENT_LANG="en"
                else
                    CURRENT_LANG="zh"
                fi
                save_language_setting
                set_dialog_title
                if [ "$CURRENT_LANG" = "zh" ]; then
                    show_gui_msgbox "$(tr "提示" "Notice")" "$(tr "语言已设置为中文" "Language set to Chinese")" 8 40
                else
                    show_gui_msgbox "$(tr "提示" "Notice")" "Language set to English" 8 40
                fi
                ;;
            2)
                show_gui_msgbox "$(tr "语言信息" "Language Info")" "$(tr "当前语言: $CURRENT_LANG\n默认语言: zh\n支持: 中文/English" "Current language: $CURRENT_LANG\nDefault: zh\nSupported: Chinese/English")" 10 50
                ;;
            3)
                return
                ;;
        esac
    done
}

main_menu_gui() {
    while true; do
        choice=$(show_gui_menu "$(tr "主菜单 Pro版" "Main Menu Pro")" 25 70 11 \
                  "1" "$(tr "服务器应用安装" "Server App Installation")" \
                  "2" "$(tr "系统优化配置" "System Optimization")" \
                  "3" "$(tr "快速启动管理器" "Quick Start Manager")" \
                  "4" "$(tr "系统状态检查" "System Status Check")" \
                  "5" "$(tr "卸载工具" "Uninstall Tools")" \
                  "6" "$(tr "语言设置" "Language Settings")" \
                  "7" "$(tr "清理临时文件" "Cleanup Temp Files")" \
                  "0" "$(tr "退出程序" "Exit Program")")
        
        if [ -z "$choice" ]; then
            exit_program
            continue
        fi
        
        case $choice in
            1) server_app_install_menu ;;
            2) system_optimization_gui ;;
            3) quick_start_menu ;;
            4) system_integrity_check_gui ;;
            5) uninstall_menu_gui ;;
            6) language_menu_gui ;;
            7) cleanup_temp_files_gui ;;
            0) exit_program ;;
        esac
    done
}

exit_program() {
    if [ "$CURRENT_LANG" = "zh" ]; then
        if ! show_gui_yesno "退出程序" "确定要退出吗？" 8 40; then
            return
        fi
    else
        if ! show_gui_yesno "Exit Program" "Exit the program?" 8 40; then
            return
        fi
    fi
    
    clear
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${GREEN}感谢使用服务器部署工具 Pro版！${NC}"
        echo -e "${YELLOW}日志文件: $INSTALL_LOG${NC}"
    else
        echo -e "${GREEN}Thank you for using Server Deployment Tool Pro!${NC}"
        echo -e "${YELLOW}Log file: $INSTALL_LOG${NC}"
    fi
    exit 0
}

check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log "$(tr "使用root权限运行" "Running with root privileges")"
        return 0
    fi
    
    info "$(tr "检测到非root用户，尝试使用sudo..." "Non-root user detected, trying sudo...")"
    
    if ! command -v sudo &>/dev/null; then
        error "$(tr "未找到sudo命令，请以root用户运行此脚本" "sudo not found, run as root")"
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${YELLOW}可以使用以下方式：${NC}"
            echo "1. sudo bash $0"
            echo "2. su - root"
            echo "3. 切换到root用户"
        else
            echo -e "${YELLOW}Use one of these methods:${NC}"
            echo "1. sudo bash $0"
            echo "2. su - root"
            echo "3. Switch to root user"
        fi
        exit 1
    fi
    
    if ! sudo -n true 2>/dev/null; then
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${YELLOW}需要sudo权限来运行此脚本${NC}"
            echo "请输入密码继续..."
        else
            echo -e "${YELLOW}sudo privileges required to run this script${NC}"
            echo "Enter password to continue..."
        fi
        sudo echo "$(tr "sudo权限检查通过" "sudo privileges verified")" || {
            error "$(tr "sudo权限验证失败" "sudo verification failed")"
            exit 1
        }
    fi
    
    warn "$(tr "重新以sudo权限运行脚本..." "Re-running with sudo privileges...")"
    exec sudo bash "$0" "$@"
}

check_ubuntu_version() {
    if [ ! -f "/etc/os-release" ]; then
        error "$(tr "无法检测操作系统" "Cannot detect OS")"
        exit 1
    fi
    
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "$(tr "本脚本仅适用于Ubuntu系统！" "This script is for Ubuntu only!")"
        if [ "$CURRENT_LANG" = "zh" ]; then
            echo -e "${YELLOW}检测到的系统：${NC}"
        else
            echo -e "${YELLOW}Detected system:${NC}"
        fi
        grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2
        exit 1
    fi
    
    local version=$(grep "VERSION_ID" /etc/os-release | cut -d'"' -f2)
    log "$(tr "检测到 Ubuntu $version 系统 ✓" "Detected Ubuntu $version ✓")"
}

check_required_tools() {
    info "$(tr "检查必要工具..." "Checking required tools...")"
    
    local tools=("curl" "wget" "grep" "awk" "sed" "cut" "systemctl")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        warn "$(tr "缺少必要工具: ${missing[*]}" "Missing tools: ${missing[*]}")"
        info "$(tr "自动安装缺失工具..." "Auto-installing missing tools...")"
        
        apt-get update -y >/dev/null 2>&1
        for tool in "${missing[@]}"; do
            case $tool in
                "curl") apt-get install -y curl >/dev/null 2>&1 ;;
                "wget") apt-get install -y wget >/dev/null 2>&1 ;;
                *) apt-get install -y "$tool" >/dev/null 2>&1 ;;
            esac
            if [ $? -eq 0 ]; then
                log "$(tr "已安装 $tool" "Installed $tool")"
            else
                error "$(tr "安装 $tool 失败" "Failed to install $tool")"
            fi
        done
    else
        log "$(tr "所有必要工具已安装 ✓" "All required tools installed ✓")"
    fi
}

confirm_execution_gui() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo "║        Ubuntu 服务器部署脚本 Pro版 v$SCRIPT_VERSION       ║"
        echo "║             专业服务器部署方案管理器                     ║"
    else
        echo "║        Ubuntu Server Deployment Tool Pro v$SCRIPT_VERSION ║"
        echo "║             Professional Server Deployment Manager        ║"
    fi
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    
    if [ "$CURRENT_LANG" = "zh" ]; then
        echo -e "${CYAN}当前语言：${NC}"
        echo -e "  语言: $([ "$CURRENT_LANG" = "zh" ] && echo "中文" || echo "English")"
        echo -e "  自动恢复: $([ "$AUTO_RECOVERY" = true ] && echo "${GREEN}启用${NC}" || echo "${YELLOW}禁用${NC}")"
        echo ""
        echo -e "${CYAN}系统信息：${NC}"
        echo "  OS: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
        echo "   内核: $(uname -r)"
        echo "   架构: $(uname -m)"
        echo ""
        echo -e "${YELLOW}⚠  警告：本脚本将修改系统配置并安装软件${NC}"
        echo -e "${YELLOW}请确保您已经备份重要数据${NC}"
        echo ""
        echo -e "${CYAN}日志文件: ${INSTALL_LOG}${NC}"
        echo -e "${CYAN}备份目录: ${BACKUP_DIR}${NC}"
        echo ""
        read -p "按回车键进入主菜单，或按 Ctrl+C 退出... " dummy
    else
        echo -e "${CYAN}Current Settings:${NC}"
        echo -e "  Language: $([ "$CURRENT_LANG" = "zh" ] && echo "Chinese" || echo "English")"
        echo -e "  Auto Recovery: $([ "$AUTO_RECOVERY" = true ] && echo "${GREEN}Enabled${NC}" || echo "${YELLOW}Disabled${NC}")"
        echo ""
        echo -e "${CYAN}System Info:${NC}"
        echo "  OS: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
        echo "  Kernel: $(uname -r)"
        echo "  Arch: $(uname -m)"
        echo ""
        echo -e "${YELLOW}⚠  Warning: This script will modify system config and install software${NC}"
        echo -e "${YELLOW}Ensure you have backed up important data${NC}"
        echo ""
        echo -e "${CYAN}Log file: ${INSTALL_LOG}${NC}"
        echo -e "${CYAN}Backup dir: ${BACKUP_DIR}${NC}"
        echo ""
        read -p "Press Enter for main menu, or Ctrl+C to exit... " dummy
    fi
}

main() {
    load_language_setting
    set_dialog_title
    select_language_gui
    validate_access
    init_log_system
    check_sudo "$@"
    check_required_tools
    check_dialog
    check_ubuntu_version
    confirm_execution_gui
    
    local start_time=$(date +%s)
    log "$(tr "脚本开始执行 (v$SCRIPT_VERSION)" "Script started (v$SCRIPT_VERSION)")"
    
    main_menu_gui
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log "$(tr "脚本执行完成，总耗时: ${duration}秒" "Script completed, total time: ${duration} seconds")"
}

trap 'error "$(tr "脚本被中断" "Script interrupted")"; if [ "$CURRENT_LANG" = "zh" ]; then echo -e "${YELLOW}日志文件: ${INSTALL_LOG}${NC}"; else echo -e "${YELLOW}Log file: ${INSTALL_LOG}${NC}"; fi; exit 1' INT TERM

main "$@"

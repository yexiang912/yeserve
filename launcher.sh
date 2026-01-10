#!/bin/bash

LAUNCHER_VERSION="5.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

FORCE_CLI=false
SSH_SESSION=false
QUIET_MODE=false
GUI_ENABLED=false
CURRENT_LANG="zh"
CMD_LANG_SET=false

detect_ssh_session() {
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
        SSH_SESSION=true
        return 0
    fi
    if pstree -s $$ 2>/dev/null | grep -q "sshd"; then
        SSH_SESSION=true
        return 0
    fi
    local tty_type
    tty_type=$(tty 2>/dev/null)
    if [[ "$tty_type" == *"pts"* ]] && [ -z "$DISPLAY" ]; then
        SSH_SESSION=true
        return 0
    fi
    SSH_SESSION=false
    return 1
}

show_help() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}${BOLD}   YeServe 启动器 v${LAUNCHER_VERSION}${NC}"
    echo -e "${PURPLE}   YeServe Launcher${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${GREEN}用法 / Usage:${NC}"
    echo "  $0 [选项/options]"
    echo ""
    echo -e "${GREEN}选项 / Options:${NC}"
    echo "  -cli, --cli        强制使用终端模式 (Force terminal/CLI mode)"
    echo "  -gui, --gui        强制使用GUI模式 (Force GUI mode)"
    echo "  -h, --help         显示此帮助信息 (Show this help)"
    echo "  -v, --version      显示版本信息 (Show version)"
    echo "  -q, --quiet        静默模式 (Quiet mode)"
    echo ""
    echo -e "${GREEN}示例 / Examples:${NC}"
    echo "  $0                 # 自动检测模式"
    echo "  $0 -cli            # 终端模式运行"
    echo "  $0 --gui           # 强制GUI模式"
    echo ""
    echo -e "${YELLOW}注意 / Notes:${NC}"
    echo "  - SSH连接时自动启用终端模式"
    echo "  - Auto-enables CLI mode when connected via SSH"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

show_version() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}${BOLD}   YeServe 启动器${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}版本 / Version:${NC}  $LAUNCHER_VERSION"
    echo -e "  ${GREEN}GUI工具 / GUI:${NC}    Zenity"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -cli|--cli)
                FORCE_CLI=true
                shift
                ;;
            -gui|--gui)
                FORCE_CLI=false
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -q|--quiet)
                QUIET_MODE=true
                shift
                ;;
            -*)
                echo -e "${RED}未知选项: $1${NC}"
                echo "使用 $0 --help 查看帮助"
                exit 1
                ;;
            *)
                shift
                ;;
        esac
    done
}

check_and_prepare_gui() {
    if [ "$FORCE_CLI" = true ]; then
        GUI_ENABLED=false
        [ "$QUIET_MODE" != true ] && echo -e "${CYAN}终端模式已启用 (CLI Mode)${NC}"
        return 1
    fi
    detect_ssh_session
    if [ "$SSH_SESSION" = true ]; then
        GUI_ENABLED=false
        FORCE_CLI=true
        [ "$QUIET_MODE" != true ] && echo -e "${CYAN}检测到SSH连接，自动启用终端模式${NC}"
        return 1
    fi
    if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
        GUI_ENABLED=false
        [ "$QUIET_MODE" != true ] && echo -e "${YELLOW}无图形环境，使用终端模式${NC}"
        return 1
    fi
    if command -v zenity >/dev/null 2>&1; then
        GUI_ENABLED=true
        return 0
    else
        GUI_ENABLED=false
        [ "$QUIET_MODE" != true ] && echo -e "${YELLOW}zenity未安装，使用终端模式${NC}"
        return 1
    fi
}

install_chinese_packages() {
    echo -e "${CYAN}正在安装中文语言包...${NC}"
    
    apt-get update -y >/dev/null 2>&1
    apt-get install -y language-pack-zh-hans language-pack-en locales >/dev/null 2>&1
    locale-gen en_US.UTF-8 zh_CN.UTF-8 >/dev/null 2>&1
    update-locale LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 >/dev/null 2>&1
    
    grep -q 'export LANG=zh_CN.UTF-8' ~/.bashrc || echo 'export LANG=zh_CN.UTF-8' >> ~/.bashrc
    grep -q 'export LC_ALL=zh_CN.UTF-8' ~/.bashrc || echo 'export LC_ALL=zh_CN.UTF-8' >> ~/.bashrc
    source ~/.bashrc 2>/dev/null
    
    zenity --info --title="完成" --text="✅ 中文语言包安装完成！" --width=300 2>/dev/null
}

check_and_install_utf8() {
    if ! locale -a | grep -q "en_US.utf8\|zh_CN.utf8"; then
        install_chinese_packages
    fi
}

install_openssl() {
    if ! command -v openssl >/dev/null 2>&1; then
        echo -e "${YELLOW}安装openssl...${NC}"
        apt-get install -y openssl >/dev/null 2>&1
    fi
}

install_zenity() {
    if ! command -v zenity >/dev/null 2>&1; then
        echo -e "${YELLOW}安装zenity GUI工具...${NC}"
        apt-get install -y zenity >/dev/null 2>&1
    fi
}

show_menu() {
    if [ "$GUI_ENABLED" = true ]; then
        show_menu_gui
    else
        show_menu_cli
    fi
}

show_menu_cli() {
    while true; do
        clear
        echo -e "${PURPLE}╭──────────────────────────────────────────────╮${NC}"
        echo -e "${PURPLE}│  🚀 YeServe 启动器 v${LAUNCHER_VERSION}                    │${NC}"
        echo -e "${PURPLE}╰──────────────────────────────────────────────╯${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} ✅ 基础版 (yeserve.sh)"
        echo -e "  ${GREEN}2)${NC} ⚠️  GUI增强版 (serveui.sh)"
        echo -e "  ${GREEN}3)${NC} 🔴 专业版 (双版本选择)"
        echo -e "  ${GREEN}4)${NC} 🔧 系统工具"
        echo -e "  ${GREEN}0)${NC} 🚪 退出"
        echo ""
        echo -e "${CYAN}────────────────────────────────────────────────${NC}"
        echo -ne "  ${YELLOW}请选择 [0-4]:${NC} "
        read -r choice
        
        case $choice in
            1)
                run_script_cli "基础版" "yeserve.sh" "https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh"
                ;;
            2)
                run_script_cli "GUI增强版" "serveui.sh" "https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh"
                ;;
            3)
                run_pro_version_cli
                ;;
            4)
                system_tools_cli
                ;;
            0)
                clear
                echo -e "${GREEN}感谢使用！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选项${NC}"
                sleep 1
                ;;
        esac
    done
}

show_menu_gui() {
    while true; do
        choice=$(zenity --list \
            --title="🚀 YeServe 启动器 v$LAUNCHER_VERSION" \
            --text="选择要运行的版本：" \
            --column="ID" --column="版本" \
            "1" "✅ 基础版 (yeserve.sh)" \
            "2" "⚠️ GUI增强版 (serveui.sh)" \
            "3" "🔴 专业版 (双版本选择)" \
            "4" "🔧 系统工具" \
            "5" "🚪 退出" \
            --width=500 --height=350 2>/dev/null)
        
        if [ -z "$choice" ]; then
            if zenity --question --title="退出" --text="确定要退出吗？" --width=250 2>/dev/null; then
                clear
                echo -e "${GREEN}再见！${NC}"
                exit 0
            fi
            continue
        fi
        
        case $choice in
            1)
                run_script "基础版" "yeserve.sh" "https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh"
                ;;
            2)
                run_script "GUI增强版" "serveui.sh" "https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh"
                ;;
            3)
                run_pro_version
                ;;
            4)
                system_tools
                ;;
            5)
                clear
                echo -e "${GREEN}感谢使用！${NC}"
                exit 0
                ;;
        esac
    done
}

run_script() {
    if [ "$GUI_ENABLED" = true ]; then
        run_script_gui "$@"
    else
        run_script_cli "$@"
    fi
}

run_script_cli() {
    local name="$1"
    local filename="$2"
    local url="$3"
    
    echo ""
    echo -ne "  ${YELLOW}确定要运行 $name 吗? [y/N]:${NC} "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo -e "  ${CYAN}正在下载 $name...${NC}"
    wget -q -O "$filename" "$url"
    
    if [ -f "$filename" ]; then
        chmod +x "$filename" 2>/dev/null
        clear
        echo -e "${GREEN}开始运行 $name...${NC}"
        echo -e "${YELLOW}================================${NC}"
        bash "$filename"
        echo ""
        echo -e "${GREEN}✅ $name 执行完成！${NC}"
        echo -ne "${YELLOW}按回车继续...${NC}"
        read -r
    else
        echo -e "  ${RED}✗ 下载失败！${NC}"
        sleep 2
    fi
}

run_script_gui() {
    local name="$1"
    local filename="$2"
    local url="$3"
    
    if zenity --question --title="确认运行" --text="确定要运行 $name 吗？" --width=300 2>/dev/null; then
        (
            echo "10"; echo "# 下载 $name 脚本..."
            wget -q -O "$filename" "$url"
            echo "50"; echo "# 设置执行权限..."
            chmod +x "$filename" 2>/dev/null
            echo "100"; echo "# 准备完成"
        ) | zenity --progress --title="下载中" --text="正在下载..." --percentage=0 --auto-close --width=400 2>/dev/null
        
        if [ -f "$filename" ]; then
            clear
            echo -e "${GREEN}开始运行 $name...${NC}"
            echo -e "${YELLOW}================================${NC}"
            
            if bash "$filename"; then
                zenity --info --title="完成" --text="✅ $name 执行完成！" --width=300 2>/dev/null
            else
                zenity --error --title="错误" --text="❌ $name 执行失败" --width=300 2>/dev/null
            fi
        else
            zenity --error --title="错误" --text="❌ 下载失败！" --width=300 2>/dev/null
        fi
    fi
}

run_pro_version() {
    if [ "$GUI_ENABLED" = true ]; then
        run_pro_version_gui
    else
        run_pro_version_cli
    fi
}

run_pro_version_cli() {
    clear
    echo -e "${PURPLE}╭──────────────────────────────────────────────╮${NC}"
    echo -e "${PURPLE}│  🔴 专业版 - 版本选择                         │${NC}"
    echo -e "${PURPLE}╰──────────────────────────────────────────────╯${NC}"
    echo -e "${RED}⚠️  高风险警告：专业版需要授权密钥${NC}"
    echo ""
    echo -e "  ${GREEN}1)${NC} Zenity版 (功能更丰富/推荐)"
    echo -e "  ${GREEN}2)${NC} YAD版"
    echo -e "  ${GREEN}3)${NC} 经典版 (servepro.sh)"
    echo -e "  ${GREEN}0)${NC} 返回"
    echo ""
    echo -ne "  ${YELLOW}请选择 [0-3]:${NC} "
    read -r pro_choice
    
    case $pro_choice in
        1)
            download_and_run_pro_cli "servepro_zenity.sh" "Zenity版"
            ;;
        2)
            download_and_run_pro_cli "servepro_yad.sh" "YAD版"
            ;;
        3)
            download_and_run_pro_cli "servepro.sh" "经典版"
            ;;
        *)
            return
            ;;
    esac
}

select_run_params_cli() {
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────${NC}"
    echo -e "${GREEN}选择执行方式:${NC}"
    echo -e "  ${GREEN}1)${NC} 自动检测模式 (无参数)"
    echo -e "  ${GREEN}2)${NC} 强制终端模式 (-cli)"
    echo -e "  ${GREEN}3)${NC} 强制GUI模式 (-gui)"
    echo -e "  ${GREEN}4)${NC} 帮助信息 (--help)"
    echo -e "  ${GREEN}5)${NC} 版本信息 (--version)"
    echo -e "  ${GREEN}6)${NC} 静默模式 (-q)"
    echo -e "  ${GREEN}7)${NC} 自定义参数"
    echo -e "  ${GREEN}0)${NC} 取消执行"
    echo -e "${CYAN}────────────────────────────────────────────────${NC}"
    echo -ne "  ${YELLOW}请选择 [0-7]:${NC} "
    read -r param_choice
    
    case $param_choice in
        1) echo "" ;;
        2) echo "-cli" ;;
        3) echo "-gui" ;;
        4) echo "--help" ;;
        5) echo "--version" ;;
        6) echo "-q" ;;
        7)
            echo -ne "  ${YELLOW}请输入自定义参数:${NC} "
            read -r custom_params
            echo "$custom_params"
            ;;
        0) echo "CANCEL" ;;
        *) echo "" ;;
    esac
}

download_and_run_pro_cli() {
    local filename="$1"
    local version_name="$2"
    local base_url="https://raw.githubusercontent.com/yexiang912/yeserve/main"
    
    echo ""
    echo -ne "  ${YELLOW}确定要下载并运行专业版 ($version_name) 吗? [y/N]:${NC} "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi
    
    echo -e "  ${CYAN}正在下载 $version_name...${NC}"
    wget -q -O "$filename" "$base_url/$filename"
    
    if [ ! -f "$filename" ]; then
        echo -e "  ${RED}✗ 下载失败！请检查网络连接${NC}"
        sleep 2
        return
    fi
    
    sed -i 's/\r$//' "$filename" 2>/dev/null
    chmod +x "$filename"
    
    local run_params
    run_params=$(select_run_params_cli)
    
    if [ "$run_params" = "CANCEL" ]; then
        echo -e "  ${YELLOW}已取消执行${NC}"
        sleep 1
        return
    fi
    
    clear
    echo -e "${GREEN}开始运行专业版 ($version_name)...${NC}"
    echo -e "${YELLOW}================================${NC}"
    echo -e "${CYAN}执行命令: bash $filename $run_params${NC}"
    echo -e "${RED}⚠️  需要授权密钥${NC}"
    echo ""
    
    bash "$filename" $run_params
    
    echo ""
    echo -e "${GREEN}专业版脚本执行完成${NC}"
    echo -ne "${YELLOW}按回车继续...${NC}"
    read -r
}

run_pro_version_gui() {
    # 选择专业版版本
    local pro_choice=$(zenity --list \
        --title="🔴 专业版 - 版本选择" \
        --text="⚠️ 高风险警告：专业版需要授权密钥\n\n请选择GUI版本：" \
        --column="ID" --column="版本" --column="说明" \
        "1" "Zenity版" "使用zenity作为GUI (功能更丰富/推荐)" \
        "2" "YAD版" "使用yad作为GUI" \
        "3" "经典版" "原版servepro.sh" \
        "0" "返回" "返回主菜单" \
        --width=550 --height=300 2>/dev/null)
    
    case $pro_choice in
        1)
            download_and_run_pro "servepro_zenity.sh" "Zenity版"
            ;;
        2)
            download_and_run_pro "servepro_yad.sh" "YAD版"
            ;;
        3)
            download_and_run_pro "servepro.sh" "经典版"
            ;;
        *)
            return
            ;;
    esac
}

download_and_run_pro() {
    if [ "$GUI_ENABLED" = true ]; then
        download_and_run_pro_gui "$@"
    else
        download_and_run_pro_cli "$@"
    fi
}

select_run_params_gui() {
    local param_choice
    param_choice=$(zenity --list \
        --title="选择执行方式" \
        --text="请选择专业版的执行参数：" \
        --column="ID" --column="模式" --column="说明" \
        "1" "自动检测" "无参数，自动检测环境" \
        "2" "终端模式" "-cli 强制使用终端模式" \
        "3" "GUI模式" "-gui 强制使用GUI模式" \
        "4" "帮助信息" "--help 显示帮助" \
        "5" "版本信息" "--version 显示版本" \
        "6" "静默模式" "-q 减少输出" \
        "7" "自定义参数" "输入自定义参数" \
        --width=500 --height=350 2>/dev/null)
    
    case $param_choice in
        1) echo "" ;;
        2) echo "-cli" ;;
        3) echo "-gui" ;;
        4) echo "--help" ;;
        5) echo "--version" ;;
        6) echo "-q" ;;
        7)
            local custom
            custom=$(zenity --entry --title="自定义参数" --text="请输入执行参数：" --width=350 2>/dev/null)
            echo "$custom"
            ;;
        *) echo "CANCEL" ;;
    esac
}

download_and_run_pro_gui() {
    local filename="$1"
    local version_name="$2"
    local base_url="https://raw.githubusercontent.com/yexiang912/yeserve/main"
    
    if ! zenity --question --title="确认" --text="确定要下载并运行专业版 ($version_name) 吗？\n\n🔴 需要授权密钥" --width=350 2>/dev/null; then
        return
    fi
    
    (
        echo "10"; echo "# 下载 $version_name..."
        wget -q -O "$filename" "$base_url/$filename"
        echo "40"; echo "# 检查文件完整性..."
        sleep 0.5
        echo "60"; echo "# 修复格式问题..."
        if [ -f "$filename" ]; then
            sed -i 's/\r$//' "$filename" 2>/dev/null
            chmod +x "$filename"
        fi
        echo "100"; echo "# 准备完成"
    ) | zenity --progress --title="下载专业版" --text="正在下载..." --percentage=0 --auto-close --width=400 2>/dev/null
    
    if [ ! -f "$filename" ]; then
        zenity --error --title="错误" --text="❌ 下载失败！\n\n请检查网络连接" --width=300 2>/dev/null
        return
    fi
    
    local run_params
    run_params=$(select_run_params_gui)
    
    if [ "$run_params" = "CANCEL" ]; then
        zenity --info --title="取消" --text="已取消执行" --width=250 2>/dev/null
        return
    fi
    
    clear
    echo -e "${GREEN}开始运行专业版 ($version_name)...${NC}"
    echo -e "${YELLOW}================================${NC}"
    echo -e "${CYAN}执行命令: bash $filename $run_params${NC}"
    echo -e "${RED}⚠️  需要授权密钥${NC}"
    echo ""
    
    bash "$filename" $run_params
    
    echo ""
    echo -e "${GREEN}专业版脚本执行完成${NC}"
    zenity --info --title="完成" --text="✅ 专业版 ($version_name) 执行完成" --width=300 2>/dev/null
}

system_tools() {
    if [ "$GUI_ENABLED" = true ]; then
        system_tools_gui
    else
        system_tools_cli
    fi
}

system_tools_cli() {
    while true; do
        clear
        echo -e "${PURPLE}╭──────────────────────────────────────────────╮${NC}"
        echo -e "${PURPLE}│  🔧 系统工具                                │${NC}"
        echo -e "${PURPLE}╰──────────────────────────────────────────────╯${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 🔄 安装中文语言包"
        echo -e "  ${GREEN}2)${NC} 📊 系统信息"
        echo -e "  ${GREEN}3)${NC} 🌐 网络测试"
        echo -e "  ${GREEN}4)${NC} 🧹 清理下载文件"
        echo -e "  ${GREEN}5)${NC} 📦 安装GUI依赖"
        echo -e "  ${GREEN}0)${NC} 🔙 返回主菜单"
        echo ""
        echo -ne "  ${YELLOW}请选择 [0-5]:${NC} "
        read -r choice
        
        case $choice in
            1)
                install_chinese_packages
                echo -ne "${YELLOW}按回车继续...${NC}"
                read -r
                ;;
            2)
                local os_info=$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
                local kernel=$(uname -r)
                local arch=$(uname -m)
                local mem=$(free -h | awk '/Mem:/{print $2}')
                local disk=$(df -h / | awk 'NR==2{print $4}')
                
                echo ""
                echo -e "${CYAN}────────────────────────────────────────────────${NC}"
                echo -e "${GREEN}📊 系统信息${NC}"
                echo -e "${CYAN}────────────────────────────────────────────────${NC}"
                echo -e "  操作系统: ${WHITE}$os_info${NC}"
                echo -e "  内核版本: ${WHITE}$kernel${NC}"
                echo -e "  系统架构: ${WHITE}$arch${NC}"
                echo -e "  总内存:   ${WHITE}$mem${NC}"
                echo -e "  可用磁盘: ${WHITE}$disk${NC}"
                echo -e "  当前语言: ${WHITE}$LANG${NC}"
                echo -e "${CYAN}────────────────────────────────────────────────${NC}"
                echo -ne "${YELLOW}按回车继续...${NC}"
                read -r
                ;;
            3)
                echo ""
                echo -e "  ${CYAN}正在测试网络连接...${NC}"
                echo ""
                echo -ne "  GitHub: "
                if ping -c 2 github.com >/dev/null 2>&1; then
                    echo -e "${GREEN}✓ 连接正常${NC}"
                else
                    echo -e "${RED}✗ 连接失败${NC}"
                fi
                echo -ne "  Google: "
                if ping -c 2 google.com >/dev/null 2>&1; then
                    echo -e "${GREEN}✓ 连接正常${NC}"
                else
                    echo -e "${RED}✗ 连接失败${NC}"
                fi
                echo ""
                echo -ne "${YELLOW}按回车继续...${NC}"
                read -r
                ;;
            4)
                echo -ne "  ${YELLOW}确定要清理下载的脚本文件吗? [y/N]:${NC} "
                read -r confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    rm -f yeserve.sh serveui.sh servepro.sh servepro_zenity.sh servepro_yad.sh 2>/dev/null
                    echo -e "  ${GREEN}✓ 清理完成！${NC}"
                fi
                sleep 1
                ;;
            5)
                echo -e "  ${CYAN}正在安装GUI依赖...${NC}"
                apt-get update -y >/dev/null 2>&1
                apt-get install -y zenity yad xterm fonts-wqy-microhei fonts-wqy-zenhei >/dev/null 2>&1
                echo -e "  ${GREEN}✓ GUI依赖安装完成！${NC}"
                sleep 2
                ;;
            *)
                return
                ;;
        esac
    done
}

system_tools_gui() {
    while true; do
        local choice=$(zenity --list \
            --title="🔧 系统工具" \
            --text="选择工具：" \
            --column="ID" --column="工具" \
            "1" "🔄 安装中文语言包" \
            "2" "📊 系统信息" \
            "3" "🌐 网络测试" \
            "4" "🧹 清理下载文件" \
            "5" "📦 安装GUI依赖" \
            "0" "🔙 返回主菜单" \
            --width=450 --height=350 2>/dev/null)
        
        case $choice in
            1)
                install_chinese_packages
                ;;
            2)
                local os_info=$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)
                local kernel=$(uname -r)
                local arch=$(uname -m)
                local mem=$(free -h | awk '/Mem:/{print $2}')
                local disk=$(df -h / | awk 'NR==2{print $4}')
                
                zenity --info --title="📊 系统信息" --text="\n操作系统: $os_info\n内核版本: $kernel\n系统架构: $arch\n总内存: $mem\n可用磁盘: $disk\n当前语言: $LANG" --width=400 2>/dev/null
                ;;
            3)
                (
                    echo "20"; echo "# 测试 GitHub 连接..."
                    github_result=$(ping -c 2 github.com 2>&1)
                    echo "60"; echo "# 测试 Google 连接..."
                    google_result=$(ping -c 2 google.com 2>&1)
                    echo "100"; echo "# 测试完成"
                ) | zenity --progress --title="网络测试" --text="正在测试..." --percentage=0 --auto-close --width=350 2>/dev/null
                
                zenity --info --title="🌐 网络测试结果" --text="GitHub: $(echo "$github_result" | grep -q '0% packet loss' && echo '✅ 连接正常' || echo '❌ 连接失败')\nGoogle: $(echo "$google_result" | grep -q '0% packet loss' && echo '✅ 连接正常' || echo '❌ 连接失败')" --width=350 2>/dev/null
                ;;
            4)
                if zenity --question --title="确认清理" --text="确定要清理下载的脚本文件吗？\n\n将删除: yeserve.sh, serveui.sh, servepro*.sh" --width=350 2>/dev/null; then
                    rm -f yeserve.sh serveui.sh servepro.sh servepro_zenity.sh servepro_yad.sh 2>/dev/null
                    zenity --info --title="完成" --text="✅ 清理完成！" --width=250 2>/dev/null
                fi
                ;;
            5)
                (
                    echo "10"; echo "# 更新软件源..."
                    apt-get update -y >/dev/null 2>&1
                    echo "30"; echo "# 安装zenity..."
                    apt-get install -y zenity >/dev/null 2>&1
                    echo "50"; echo "# 安装yad..."
                    apt-get install -y yad >/dev/null 2>&1
                    echo "70"; echo "# 安装xterm..."
                    apt-get install -y xterm >/dev/null 2>&1
                    echo "90"; echo "# 安装中文字体..."
                    apt-get install -y fonts-wqy-microhei fonts-wqy-zenhei >/dev/null 2>&1
                    echo "100"; echo "# 安装完成"
                ) | zenity --progress --title="安装GUI依赖" --text="正在安装..." --percentage=0 --auto-close --width=400 2>/dev/null
                
                zenity --info --title="完成" --text="✅ GUI依赖安装完成！\n\n已安装: zenity, yad, xterm, 中文字体" --width=350 2>/dev/null
                ;;
            *)
                return
                ;;
        esac
    done
}

welcome() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                                              ║"
    echo "║       🚀 YeServe Launcher                   ║"
    echo "║               v$LAUNCHER_VERSION                         ║"
    echo "║                                              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    if [ "$GUI_ENABLED" = true ]; then
        echo -e "${DIM}[模式: GUI/Zenity] [Mode: GUI]${NC}"
    else
        echo -e "${DIM}[模式: CLI/终端] [Mode: CLI/Terminal]${NC}"
    fi
    echo ""
    
    if [ "$QUIET_MODE" != true ]; then
        echo -e "${CYAN}正在初始化环境...${NC}"
        check_and_install_utf8
        install_openssl
        if [ "$GUI_ENABLED" = true ]; then
            install_zenity
        fi
        echo -e "${GREEN}✅ 环境准备完成！${NC}"
        sleep 1
    fi
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}请使用sudo运行：${NC}"
        echo -e "${YELLOW}sudo bash $0${NC}"
        exit 1
    fi
}

main() {
    parse_arguments "$@"
    check_root
    check_and_prepare_gui
    welcome
    show_menu
}

main "$@"

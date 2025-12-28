#!/bin/bash

LAUNCHER_VERSION="3.1"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

install_utf8_packages() {
    clear
    echo -e "${CYAN}安装UTF-8语言包...${NC}"
    
    apt-get update -y
    
    local lang_packages=(
        "language-pack-en"
        "language-pack-zh-hans"
        "locales"
    )
    
    for pkg in "${lang_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            echo -e "${YELLOW}安装 $pkg ...${NC}"
            apt-get install -y "$pkg"
        fi
    done
    
    echo -e "${YELLOW}生成语言环境...${NC}"
    locale-gen en_US.UTF-8
    locale-gen zh_CN.UTF-8
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
    
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    
    echo -e "${GREEN}UTF-8语言包安装完成 ✓${NC}"
    echo ""
}

check_encoding() {
    if [ "$LANG" != "en_US.UTF-8" ] && [ "$LANG" != "zh_CN.UTF-8" ]; then
        install_utf8_packages
    fi
}

install_dependencies() {
    echo -e "${CYAN}检查系统依赖...${NC}"
    
    if ! command -v dialog >/dev/null 2>&1; then
        echo -e "${YELLOW}安装dialog工具...${NC}"
        apt-get install -y dialog
    fi
    
    if ! command -v wget >/dev/null 2>&1; then
        echo -e "${YELLOW}安装wget工具...${NC}"
        apt-get install -y wget
    fi
    
    echo -e "${GREEN}系统依赖检查完成 ✓${NC}"
    echo ""
}

check_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y dialog
    fi
}

show_main_menu() {
    while true; do
        choice=$(dialog --clear \
            --backtitle "🚀 YeServe 版本选择器 v$LAUNCHER_VERSION" \
            --title "请选择要运行的版本" \
            --menu "\n每个版本的风险等级和功能不同，请根据经验选择：" \
            20 60 6 \
            1 "✅ 基础版 (yeserve.sh) - 低风险，适合新手" \
            2 "⚠️ GUI增强版 (serveui.sh) - 中等风险，功能完整" \
            3 "🔴 专业版 (servepro.sh) - 高风险，需要授权" \
            4 "🛠️ 系统工具" \
            5 "🔄 重新安装依赖" \
            6 "🚪 退出" \
            3>&1 1>&2 2>&3)

        exit_code=$?
        
        if [ $exit_code -ne 0 ]; then
            clear
            echo -e "${GREEN}感谢使用 YeServe！${NC}"
            exit 0
        fi
        
        case $choice in
            1)
                run_basic_version
                ;;
            2)
                run_gui_version
                ;;
            3)
                run_pro_version
                ;;
            4)
                show_system_tools
                ;;
            5)
                reinstall_dependencies
                ;;
            6)
                clear
                echo -e "${GREEN}感谢使用 YeServe！${NC}"
                exit 0
                ;;
        esac
    done
}

run_basic_version() {
    dialog --clear \
        --backtitle "YeServe 基础版" \
        --title "风险确认" \
        --yesno "基础版风险等级：✅ 低风险\n\n功能：Docker + 1Panel + 宝塔面板\n\n确定要运行吗？" \
        10 60
    
    if [ $? -eq 0 ]; then
        clear
        echo -e "${CYAN}下载基础版脚本...${NC}"
        wget -O yeserve.sh https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh
        
        if [ -f "yeserve.sh" ]; then
            chmod +x yeserve.sh
            echo -e "${GREEN}下载完成！开始运行...${NC}"
            echo -e "${YELLOW}========================================${NC}"
            bash yeserve.sh
        else
            echo -e "${RED}下载失败！请检查网络连接${NC}"
            sleep 2
        fi
    fi
}

run_gui_version() {
    dialog --clear \
        --backtitle "YeServe GUI增强版" \
        --title "⚠️ 风险警告" \
        --yesno "GUI增强版风险等级：⚠️ 中等风险\n\n会修改系统配置和防火墙规则\n\n包含：Docker + 1Panel + 宝塔面板\n\n确定要继续吗？" \
        12 60
    
    if [ $? -eq 0 ]; then
        clear
        echo -e "${CYAN}下载GUI增强版脚本...${NC}"
        wget -O serveui.sh https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh
        
        if [ -f "serveui.sh" ]; then
            chmod +x serveui.sh
            echo -e "${GREEN}下载完成！开始运行...${NC}"
            echo -e "${YELLOW}========================================${NC}"
            bash serveui.sh
        else
            echo -e "${RED}下载失败！请检查网络连接${NC}"
            sleep 2
        fi
    fi
}

run_pro_version() {
    dialog --clear \
        --backtitle "YeServe 专业版" \
        --title "🔴 高风险警告" \
        --yesno "专业版风险等级：🔴 高风险\n\n⚠️ 会深度修改系统配置\n⚠️ 需要授权密钥\n⚠️ 仅推荐专业用户使用\n\n确定要继续吗？" \
        12 60
    
    if [ $? -eq 0 ]; then
        clear
        echo -e "${CYAN}下载专业版脚本...${NC}"
        wget -O servepro.sh https://raw.githubusercontent.com/yexiang912/yeserve/main/servepro.sh
        
        if [ ! -f "servepro.sh" ]; then
            echo -e "${RED}下载失败！${NC}"
            sleep 2
            return
        fi
        
        chmod +x servepro.sh
        
        fix_pro_script
        
        echo -e "${GREEN}下载完成！开始运行...${NC}"
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${RED}⚠️  专业版需要授权密钥${NC}"
        echo -e "${RED}⚠️  仅推荐专业用户使用${NC}"
        echo -e "${YELLOW}========================================${NC}"
        
        echo -e "${CYAN}3秒后开始运行...${NC}"
        sleep 3
        
        echo -e "${GREEN}正在启动专业版...${NC}"
        bash servepro.sh
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}专业版脚本执行完成！${NC}"
        else
            echo -e "${RED}专业版脚本执行失败${NC}"
        fi
        
        echo ""
        read -p "按回车键返回主菜单... "
    fi
}

fix_pro_script() {
    echo -e "${YELLOW}自动修复脚本...${NC}"
    
    if file servepro.sh | grep -q "CRLF"; then
        echo -e "${YELLOW}修复CRLF行结束符...${NC}"
        sed -i 's/\r$//' servepro.sh
    fi
    
    if ! head -1 servepro.sh | grep -q "^#!/bin/bash"; then
        echo -e "${YELLOW}修复shebang行...${NC}"
        sed -i '1s|^.*$|#!/bin/bash|' servepro.sh
    fi
    
    if ! grep -q "export LANG=" servepro.sh; then
        echo -e "${YELLOW}添加编码环境变量...${NC}"
        echo -e "\nexport LANG=en_US.UTF-8" >> servepro.sh
        echo -e "export LC_ALL=en_US.UTF-8" >> servepro.sh
    fi
    
    echo -e "${GREEN}脚本修复完成 ✓${NC}"
}

show_system_tools() {
    while true; do
        choice=$(dialog --clear \
            --backtitle "系统工具" \
            --title "系统工具菜单" \
            --menu "\n选择要使用的工具：" \
            15 50 7 \
            1 "🔄 安装UTF-8语言包" \
            2 "📊 查看系统信息" \
            3 "🔧 修复专业版脚本" \
            4 "🌐 测试网络连接" \
            5 "📁 清理临时文件" \
            6 "🛠️ 检查系统依赖" \
            7 "🔙 返回主菜单" \
            3>&1 1>&2 2>&3)
        
        exit_code=$?
        
        if [ $exit_code -ne 0 ] || [ "$choice" = "7" ]; then
            return
        fi
        
        case $choice in
            1)
                clear
                install_utf8_packages
                read -p "按回车键返回... "
                ;;
            2)
                clear
                show_system_info
                ;;
            3)
                clear
                fix_pro_script_tool
                ;;
            4)
                clear
                test_network
                read -p "按回车键返回... "
                ;;
            5)
                clear
                cleanup_temp_files
                read -p "按回车键返回... "
                ;;
            6)
                clear
                install_dependencies
                read -p "按回车键返回... "
                ;;
        esac
    done
}

show_system_info() {
    echo -e "${CYAN}系统信息：${NC}"
    echo "操作系统: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
    echo "内核版本: $(uname -r)"
    echo "系统架构: $(uname -m)"
    echo "主机名: $(hostname)"
    echo "当前用户: $(whoami)"
    echo "编码设置: LANG=$LANG"
    echo "内存使用: $(free -h | awk 'NR==2{print $3"/"$2}')"
    echo "磁盘空间: $(df -h / | awk 'NR==2{print $3"/"$2}')"
    echo ""
    read -p "按回车键返回... "
}

fix_pro_script_tool() {
    if [ -f "servepro.sh" ]; then
        echo -e "${CYAN}修复专业版脚本...${NC}"
        fix_pro_script
        echo -e "${GREEN}脚本修复完成 ✓${NC}"
    else
        echo -e "${RED}servepro.sh 文件不存在${NC}"
        echo -e "${YELLOW}请先下载专业版脚本${NC}"
    fi
    echo ""
    read -p "按回车键返回... "
}

test_network() {
    echo -e "${CYAN}测试网络连接...${NC}"
    
    local urls=(
        "github.com"
        "raw.githubusercontent.com"
        "download.docker.com"
    )
    
    for url in "${urls[@]}"; do
        echo -n "测试 $url ... "
        if ping -c 1 -W 2 "$url" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ 可用${NC}"
        else
            echo -e "${RED}✗ 不可用${NC}"
        fi
    done
}

cleanup_temp_files() {
    echo -e "${CYAN}清理临时文件...${NC}"
    
    rm -f yeserve.sh serveui.sh servepro.sh 2>/dev/null
    find /tmp -name "yeserve-*" -type f -delete 2>/dev/null
    find /tmp -name "*.sh" -type f -mtime +1 -delete 2>/dev/null
    
    echo -e "${GREEN}临时文件清理完成 ✓${NC}"
}

reinstall_dependencies() {
    clear
    echo -e "${CYAN}重新安装依赖...${NC}"
    install_utf8_packages
    install_dependencies
    read -p "按回车键返回主菜单... "
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}请使用 sudo 运行此脚本：${NC}"
        echo -e "${YELLOW}sudo ./gui-launcher.sh${NC}"
        exit 1
    fi
}

show_welcome() {
    clear
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════╗"
    echo "║                                                   ║"
    echo "║        🚀 YeServe GUI 启动器 v$LAUNCHER_VERSION        ║"
    echo "║         自动编码修复 + 依赖安装                   ║"
    echo "║                                                   ║"
    echo "╚═══════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}正在准备环境...${NC}"
    echo ""
}

main() {
    check_root
    show_welcome
    check_encoding
    install_dependencies
    show_main_menu
}

main

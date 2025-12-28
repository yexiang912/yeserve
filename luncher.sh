#!/bin/bash

LAUNCHER_VERSION="3.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

install_utf8_packages() {
    dialog --infobox "正在安装UTF-8语言包..." 6 40
    
    apt-get update -y > /dev/null 2>&1
    
    local lang_packages=(
        "language-pack-en"
        "language-pack-zh-hans"
        "locales"
        "fonts-noto-cjk"
    )
    
    for pkg in "${lang_packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            apt-get install -y "$pkg" > /dev/null 2>&1
        fi
    done
    
    locale-gen en_US.UTF-8 > /dev/null 2>&1
    locale-gen zh_CN.UTF-8 > /dev/null 2>&1
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 > /dev/null 2>&1
    
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
    
    dialog --msgbox "UTF-8语言包安装完成 ✓" 8 40
}

check_encoding() {
    if [ "$LANG" != "en_US.UTF-8" ] && [ "$LANG" != "zh_CN.UTF-8" ]; then
        dialog --yesno "检测到非UTF-8编码环境\n当前编码: $LANG\n\n是否自动安装UTF-8语言包？" 10 50
        if [ $? -eq 0 ]; then
            install_utf8_packages
        fi
    fi
}

check_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then
        dialog --msgbox "正在安装dialog工具..." 6 40
        apt-get update -y > /dev/null 2>&1
        apt-get install -y dialog > /dev/null 2>&1
    fi
}

show_main_menu() {
    while true; do
        choice=$(dialog --clear \
            --backtitle "🚀 YeServe 版本选择器 v$LAUNCHER_VERSION" \
            --title "请选择要运行的版本" \
            --menu "\n每个版本的风险等级和功能不同，请根据经验选择：" \
            20 60 5 \
            1 "✅ 基础版 (yeserve.sh) - 低风险，适合新手" \
            2 "⚠️ GUI增强版 (serveui.sh) - 中等风险，功能完整" \
            3 "🔴 专业版 (servepro.sh) - 高风险，需要授权" \
            4 "🛠️ 系统工具" \
            5 "🚪 退出" \
            3>&1 1>&2 2>&3)

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
                clear
                echo -e "${GREEN}感谢使用 YeServe！${NC}"
                exit 0
                ;;
            *)
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
            dialog --msgbox "下载失败！请检查网络连接" 8 40
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
            dialog --msgbox "下载失败！请检查网络连接" 8 40
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
            dialog --msgbox "下载失败！请检查网络连接" 8 40
            return
        fi
        
        chmod +x servepro.sh
        
        fix_pro_script
        
        echo -e "${GREEN}下载完成！准备运行...${NC}"
        echo -e "${YELLOW}========================================${NC}"
        echo -e "${RED}⚠️  专业版需要授权密钥${NC}"
        echo -e "${RED}⚠️  仅推荐专业用户使用${NC}"
        echo -e "${YELLOW}========================================${NC}"
        
        read -p "按回车键开始运行，或按 Ctrl+C 取消... "
        
        echo -e "${GREEN}正在启动专业版...${NC}"
        bash servepro.sh
    fi
}

fix_pro_script() {
    echo -e "${YELLOW}检查脚本完整性...${NC}"
    
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
}

show_system_tools() {
    while true; do
        choice=$(dialog --clear \
            --backtitle "系统工具" \
            --title "系统工具菜单" \
            --menu "\n选择要使用的工具：" \
            15 50 6 \
            1 "🔄 安装UTF-8语言包" \
            2 "📊 查看系统信息" \
            3 "🔧 修复专业版脚本" \
            4 "🌐 测试网络连接" \
            5 "📁 清理临时文件" \
            6 "🔙 返回主菜单" \
            3>&1 1>&2 2>&3)
        
        case $choice in
            1)
                install_utf8_packages
                ;;
            2)
                show_system_info
                ;;
            3)
                fix_pro_script_tool
                ;;
            4)
                test_network
                ;;
            5)
                cleanup_temp_files
                ;;
            6)
                return
                ;;
            *)
                return
                ;;
        esac
    done
}

show_system_info() {
    clear
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
        dialog --yesno "是否修复 servepro.sh 脚本？" 8 40
        if [ $? -eq 0 ]; then
            fix_pro_script
            dialog --msgbox "脚本修复完成 ✓" 8 40
        fi
    else
        dialog --msgbox "servepro.sh 文件不存在，请先下载专业版" 8 40
    fi
}

test_network() {
    dialog --infobox "测试网络连接..." 6 40
    
    local urls=(
        "https://github.com"
        "https://raw.githubusercontent.com"
        "https://download.docker.com"
    )
    
    local result="网络测试结果：\n"
    
    for url in "${urls[@]}"; do
        if wget --spider --timeout=5 --tries=1 "$url" 2>/dev/null; then
            result+="✅ $url\n"
        else
            result+="❌ $url\n"
        fi
    done
    
    dialog --msgbox "$result" 12 50
}

cleanup_temp_files() {
    dialog --yesno "清理临时文件？\n\n将清理：\n• 下载的脚本文件\n• 临时日志文件\n\n确定继续？" 12 50
    if [ $? -eq 0 ]; then
        rm -f yeserve.sh serveui.sh servepro.sh 2>/dev/null
        find /tmp -name "yeserve-*" -type f -delete 2>/dev/null
        dialog --msgbox "临时文件清理完成 ✓" 8 40
    fi
}

show_welcome() {
    dialog --clear \
        --backtitle "YeServe 启动器" \
        --title "欢迎使用 YeServe" \
        --msgbox "🚀 YeServe - Ubuntu 服务器一键部署工具集\n\n版本：v$LAUNCHER_VERSION\n\n🛠️ 新功能：\n• 自动UTF-8编码支持\n• 脚本自动修复\n• 系统工具集成\n\n⚠️ 重要提醒：\n运行脚本前请确保已备份重要数据！" \
        15 60
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        dialog --msgbox "请使用 sudo 运行此脚本：\n\nsudo ./gui-launcher.sh" 10 50
        exit 1
    fi
}

main() {
    check_root
    check_encoding
    check_dialog
    show_welcome
    show_main_menu
}

main

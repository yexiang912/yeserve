#!/bin/bash

LAUNCHER_VERSION="3.3"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 立即设置UTF-8环境
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

install_chinese_packages() {
    clear
    echo -e "${CYAN}正在安装中文语言包...${NC}"
    echo ""
    
    apt-get update -y >/dev/null 2>&1
    
    echo -e "${YELLOW}1. 安装语言包...${NC}"
    apt-get install -y language-pack-zh-hans language-pack-en locales >/dev/null 2>&1
    
    echo -e "${YELLOW}2. 生成语言环境...${NC}"
    locale-gen en_US.UTF-8 >/dev/null 2>&1
    locale-gen zh_CN.UTF-8 >/dev/null 2>&1
    
    echo -e "${YELLOW}3. 配置系统语言...${NC}"
    update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 >/dev/null 2>&1
    
    echo -e "${YELLOW}4. 设置环境变量...${NC}"
    echo 'export LANG=en_US.UTF-8' >> ~/.bashrc
    echo 'export LC_ALL=en_US.UTF-8' >> ~/.bashrc
    
    source ~/.bashrc
    
    echo ""
    echo -e "${GREEN}✅ 中文语言包安装完成！${NC}"
    echo ""
    
    sleep 2
}

check_and_install_utf8() {
    if ! locale -a | grep -q "en_US.utf8\|zh_CN.utf8"; then
        install_chinese_packages
    fi
}

install_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then
        echo -e "${YELLOW}安装dialog工具...${NC}"
        apt-get install -y dialog >/dev/null 2>&1
    fi
}

show_menu() {
    while true; do
        choice=$(dialog --clear \
            --backtitle "🚀 YeServe 启动器 v$LAUNCHER_VERSION" \
            --title "主菜单" \
            --menu "\n选择要运行的版本：" \
            20 60 5 \
            1 "✅ 基础版 (yeserve.sh)" \
            2 "⚠️  GUI增强版 (serveui.sh)" \
            3 "🔴 专业版 (servepro.sh)" \
            4 "🔧 系统工具" \
            5 "🚪 退出" \
            3>&1 1>&2 2>&3)
        
        exit_code=$?
        
        if [ $exit_code -ne 0 ]; then
            clear
            echo -e "${GREEN}再见！${NC}"
            exit 0
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
    local name="$1"
    local filename="$2"
    local url="$3"
    
    dialog --clear \
        --backtitle "YeServe $name" \
        --title "确认运行" \
        --yesno "确定要运行 $name 吗？" \
        8 40
    
    if [ $? -eq 0 ]; then
        clear
        echo -e "${CYAN}下载 $name 脚本...${NC}"
        wget -O "$filename" "$url"
        
        if [ -f "$filename" ]; then
            chmod +x "$filename"
            echo -e "${GREEN}开始运行 $name...${NC}"
            echo -e "${YELLOW}================================${NC}"
            
            # 关键修复：捕获脚本执行状态
            if bash "$filename"; then
                echo ""
                echo -e "${GREEN}✅ $name 执行完成！${NC}"
            else
                echo ""
                echo -e "${RED}❌ $name 执行失败${NC}"
            fi
            
            echo ""
            read -p "按回车键返回主菜单... "
        else
            echo -e "${RED}下载失败！${NC}"
            sleep 2
        fi
    fi
}

run_pro_version() {
    dialog --clear \
        --backtitle "YeServe 专业版" \
        --title "高风险警告" \
        --yesno "🔴 专业版风险等级：高风险\n\n需要授权密钥\n\n确定要继续吗？" \
        10 50
    
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
        
        # 自动修复专业版脚本
        echo -e "${YELLOW}检查脚本完整性...${NC}"
        
        if file servepro.sh | grep -q "CRLF"; then
            echo -e "${YELLOW}修复行结束符...${NC}"
            sed -i 's/\r$//' servepro.sh
        fi
        
        if ! head -1 servepro.sh | grep -q "^#!/bin/bash"; then
            echo -e "${YELLOW}修复shebang...${NC}"
            sed -i '1s|^.*$|#!/bin/bash|' servepro.sh
        fi
        
        echo -e "${GREEN}开始运行专业版...${NC}"
        echo -e "${YELLOW}================================${NC}"
        
        # 关键修复：确保脚本完全执行
        echo -e "${RED}⚠️  需要授权密钥${NC}"
        echo ""
        
        # 运行脚本并等待完成
        bash servepro.sh
        
        # 等待脚本完全执行
        wait $!
        
        echo ""
        echo -e "${GREEN}专业版脚本执行完成${NC}"
        echo ""
        read -p "按回车键返回主菜单... "
    fi
}

system_tools() {
    while true; do
        choice=$(dialog --clear \
            --backtitle "系统工具" \
            --title "工具菜单" \
            --menu "\n选择工具：" \
            15 50 5 \
            1 "🔄 安装中文语言包" \
            2 "📊 系统信息" \
            3 "🌐 网络测试" \
            4 "🧹 清理文件" \
            5 "🔙 返回" \
            3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ] || [ "$choice" = "5" ]; then
            return
        fi
        
        case $choice in
            1)
                clear
                install_chinese_packages
                read -p "按回车键继续... "
                ;;
            2)
                clear
                echo -e "${CYAN}系统信息：${NC}"
                echo "OS: $(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2)"
                echo "Kernel: $(uname -r)"
                echo "Arch: $(uname -m)"
                echo "Language: $LANG"
                echo ""
                read -p "按回车键继续... "
                ;;
            3)
                clear
                echo -e "${CYAN}网络测试：${NC}"
                ping -c 2 github.com
                echo ""
                read -p "按回车键继续... "
                ;;
            4)
                clear
                echo -e "${CYAN}清理临时文件...${NC}"
                rm -f yeserve.sh serveui.sh servepro.sh 2>/dev/null
                echo -e "${GREEN}清理完成！${NC}"
                echo ""
                read -p "按回车键继续... "
                ;;
        esac
    done
}

welcome() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                                              ║"
    echo "║          🚀 YeServe GUI Launcher            ║"
    echo "║               v$LAUNCHER_VERSION                        ║"
    echo "║                                              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}正在初始化环境...${NC}"
    echo ""
    
    # 安装必要组件
    check_and_install_utf8
    install_dialog
    
    echo -e "${GREEN}环境准备完成！${NC}"
    echo ""
    sleep 1
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}请使用sudo运行：${NC}"
        echo -e "${YELLOW}sudo bash $0${NC}"
        exit 1
    fi
}

main() {
    check_root
    welcome
    show_menu
}

main

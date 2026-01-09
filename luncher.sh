#!/bin/bash

LAUNCHER_VERSION="4.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

export LANG=zh_CN.UTF-8
export LC_ALL=zh_CN.UTF-8

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
    
    clear
    echo -e "${GREEN}开始运行专业版 ($version_name)...${NC}"
    echo -e "${YELLOW}================================${NC}"
    echo -e "${RED}⚠️  需要授权密钥${NC}"
    echo ""
    
    bash "$filename"
    
    echo ""
    echo -e "${GREEN}专业版脚本执行完成${NC}"
    zenity --info --title="完成" --text="✅ 专业版 ($version_name) 执行完成" --width=300 2>/dev/null
}

system_tools() {
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
    echo "║       🚀 YeServe Zenity Launcher            ║"
    echo "║               v$LAUNCHER_VERSION                         ║"
    echo "║                                              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}正在初始化环境...${NC}"
    
    check_and_install_utf8
    install_openssl
    install_zenity
    
    echo -e "${GREEN}✅ 环境准备完成！${NC}"
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

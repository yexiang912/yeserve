#!/bin/bash

# 设置UTF-8编码
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

LAUNCHER_VERSION="2.0"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

check_dialog() {
    if ! command -v dialog >/dev/null 2>&1; then
        dialog --msgbox "正在安装dialog工具..." 6 40
        apt-get update -y >/dev/null 2>&1
        apt-get install -y dialog >/dev/null 2>&1
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
            4 "📋 查看版本功能对比" \
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
                show_version_comparison
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
            return
        fi
        
        chmod +x servepro.sh
        
        # 修复可能的编码问题
        if file servepro.sh | grep -q "CRLF"; then
            echo -e "${YELLOW}修复CRLF行结束符...${NC}"
            sed -i 's/\r$//' servepro.sh
        fi
        
        # 确保shebang正确
        if ! head -1 servepro.sh | grep -q "^#!/bin/bash"; then
            echo -e "${YELLOW}修复shebang行...${NC}"
            sed -i '1s|^.*$|#!/bin/bash|' servepro.sh
        fi
        
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

show_version_comparison() {
    dialog --clear \
        --backtitle "版本功能对比" \
        --title "各版本功能对比表" \
        --msgbox "✅ 基础版 (低风险):
• Docker环境
• 1Panel面板
• 宝塔面板
• 基础运维工具

⚠️ GUI增强版 (中等风险):
• Docker完整环境
• 1Panel + 宝塔面板
• 系统优化配置
• 防火墙设置

🔴 专业版 (高风险):
• 多语言支持
• 小皮/AMH/Websoft9面板
• 完整开发环境
• 数据库服务
• Web服务器
• 需要授权密钥" \
        20 70
}

show_welcome() {
    dialog --clear \
        --backtitle "YeServe 启动器" \
        --title "欢迎使用 YeServe" \
        --msgbox "🚀 YeServe - Ubuntu 服务器一键部署工具集\n\n版本：v$LAUNCHER_VERSION\n\n⚠️ 重要提醒：\n运行脚本前请确保：\n1. 已备份重要数据\n2. 在测试环境验证过\n3. 了解脚本操作内容\n\n选择适合您经验水平的版本！" \
        15 60
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        dialog --msgbox "请使用 sudo 运行此脚本：\n\nsudo ./gui-launcher.sh" 10 50
        exit 1
    fi
}

check_encoding() {
    if [ "$LANG" != "en_US.UTF-8" ] && [ "$LANG" != "zh_CN.UTF-8" ]; then
        echo -e "${YELLOW}设置UTF-8编码环境...${NC}"
        export LANG=en_US.UTF-8
        export LC_ALL=en_US.UTF-8
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

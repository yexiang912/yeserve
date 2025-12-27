#!/bin/bash

check_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo "正在安装dialog..."
        apt-get update && apt-get install -y dialog
    fi
}

show_main_menu() {
    while true; do
        choice=$(dialog --clear \
            --backtitle "🚀 YeServe 版本选择器 - 作者：yx" \
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
                echo "感谢使用 YeServe！"
                exit 0
                ;;
            *)
                clear
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
        echo "正在拉取并运行基础版..."
        echo "========================================"
        sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh)"
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
        echo "正在拉取并运行GUI增强版..."
        echo "========================================"
        sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh)"
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
        echo "正在拉取专业版..."
        echo "========================================"
        sudo wget -O /tmp/servepro.sh https://raw.githubusercontent.com/yexiang912/yeserve/main/servepro.sh
        sudo chmod +x /tmp/servepro.sh
        
        echo "正在运行专业版..."
        echo "注意：需要授权密钥才能使用完整功能"
        echo "========================================"
        sudo /tmp/servepro.sh
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
        --msgbox "🚀 YeServe - Ubuntu 服务器一键部署工具集\n\n版本：v9.0\n原创作者：yx（改名字四亩）\n\n⚠️ 重要提醒：\n运行脚本前请确保：\n1. 已备份重要数据\n2. 在测试环境验证过\n3. 了解脚本操作内容\n\n选择适合您经验水平的版本！" \
        15 60
}

main() {
    if [ "$EUID" -ne 0 ]; then
        echo "请使用 sudo 运行此脚本："
        echo "sudo ./yeserve-launcher.sh"
        exit 1
    fi
    
    check_dialog
    show_welcome
    show_main_menu
}

main
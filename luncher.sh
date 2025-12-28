#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

check_wget() {
    if ! command -v wget &> /dev/null; then
        echo -e "${YELLOW}安装wget工具...${NC}"
        apt-get update && apt-get install -y wget
    fi
}

show_menu() {
    while true; do
        clear
        echo -e "${PURPLE}"
        echo "╔══════════════════════════════════════════════╗"
        echo "║      🚀 YeServe 版本选择启动器               ║"
        echo "║          作者：yx（改名字四亩）             ║"
        echo "╚══════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo ""
        echo -e "${CYAN}请选择要下载和运行的版本：${NC}"
        echo ""
        echo -e "  ${GREEN}1${NC}. 基础版 (yeserve.sh)"
        echo -e "     ${YELLOW}✅ 低风险，适合新手${NC}"
        echo ""
        echo -e "  ${GREEN}2${NC}. GUI增强版 (serveui.sh)"
        echo -e "     ${YELLOW}⚠️  中等风险，功能完整${NC}"
        echo ""
        echo -e "  ${GREEN}3${NC}. 专业版 (servepro.sh)"
        echo -e "     ${RED}🔴 高风险，需要授权${NC}"
        echo ""
        echo -e "  ${GREEN}4${NC}. 退出"
        echo ""
        echo -e "${CYAN}══════════════════════════════════════════════${NC}"
        
        read -p "请输入选择 (1-4): " choice
        
        case $choice in
            1)
                download_and_run "基础版" "yeserve.sh" "https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh"
                ;;
            2)
                download_and_run "GUI增强版" "serveui.sh" "https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh"
                ;;
            3)
                download_and_run "专业版" "servepro.sh" "https://raw.githubusercontent.com/yexiang912/yeserve/main/servepro.sh"
                ;;
            4)
                echo -e "${GREEN}感谢使用！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 1
                ;;
        esac
    done
}

download_and_run() {
    local version_name="$1"
    local script_name="$2"
    local script_url="$3"
    
    clear
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           下载 ${version_name}               ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════${NC}"
    echo ""
    
    if [ "$version_name" = "专业版" ]; then
        echo -e "${RED}⚠️  警告：专业版为高风险版本${NC}"
        echo -e "${RED}需要授权密钥才能使用完整功能${NC}"
        echo ""
    fi
    
    echo -e "${YELLOW}脚本名称: ${script_name}${NC}"
    echo -e "${YELLOW}下载地址: ${script_url}${NC}"
    echo ""
    
    read -p "是否继续？(y/n): " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}取消下载${NC}"
        sleep 1
        return
    fi
    
    echo ""
    echo -e "${BLUE}正在下载 ${version_name}...${NC}"
    
    if wget -O "$script_name" "$script_url"; then
        if [ -f "$script_name" ]; then
            echo -e "${GREEN}✅ 下载成功！${NC}"
            echo ""
            
            echo -e "${BLUE}设置执行权限...${NC}"
            chmod +x "$script_name"
            
            if [ "$version_name" = "专业版" ]; then
                echo -e "${RED}⚠️  专业版需要授权密钥${NC}"
                echo -e "${YELLOW}运行后请输入授权密钥${NC}"
                echo ""
            fi
            
            read -p "是否立即运行脚本？(y/n): " run_confirm
            
            if [[ "$run_confirm" =~ ^[Yy]$ ]]; then
                echo ""
                echo -e "${CYAN}══════════════════════════════════════════════${NC}"
                echo -e "${GREEN}           运行 ${version_name}               ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════${NC}"
                echo ""
                
                if [ "$version_name" = "专业版" ]; then
                    echo -e "${YELLOW}提示：专业版需要授权密钥${NC}"
                    echo -e "${YELLOW}如果无密钥，部分功能将受限${NC}"
                    echo ""
                    sleep 2
                fi
                
                ./"$script_name"
                
                echo ""
                echo -e "${CYAN}══════════════════════════════════════════════${NC}"
                echo -e "${GREEN}           脚本执行完成                      ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════${NC}"
                
                read -p "按回车键返回菜单..." dummy
            else
                echo -e "${YELLOW}脚本已保存为: ${script_name}${NC}"
                echo -e "${YELLOW}可手动运行: ./${script_name}${NC}"
                sleep 2
            fi
        else
            echo -e "${RED}❌ 下载失败：文件不存在${NC}"
            sleep 2
        fi
    else
        echo -e "${RED}❌ 下载失败：请检查网络连接${NC}"
        sleep 2
    fi
}

main() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}请使用 sudo 运行此脚本：${NC}"
        echo -e "${YELLOW}sudo ./luncher.sh${NC}"
        exit 1
    fi
    
    check_wget
    show_menu
}

main

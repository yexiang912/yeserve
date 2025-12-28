#!/bin/bash

LAUNCHER_VERSION="2.0"
PRO_SCRIPT_NAME="yeserve-pro.sh"
PRO_SCRIPT_URL="https://raw.githubusercontent.com/yexiang912/yeserve/main/servepro.sh"
PRO_SCRIPT_PATH="/tmp/$PRO_SCRIPT_NAME"
LOG_FILE="/var/log/yeserve-launcher.log"
PRO_LOG_FILE="/var/log/yeserve-pro-install.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

REQUIRED_PACKAGES=(
    "dialog"
    "curl"
    "wget"
    "git"
    "ca-certificates"
    "gnupg"
    "lsb-release"
    "apt-transport-https"
    "software-properties-common"
    "net-tools"
    "jq"
    "bc"
    "rsync"
    "unzip"
    "zip"
    "p7zip-full"
)

init_logging() {
    mkdir -p /var/log/yeserve 2>/dev/null
    > "$LOG_FILE"
    exec > >(tee -a "$LOG_FILE") 2>&1
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local color=""
    
    case $level in
        "INFO")    color="$BLUE" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARNING") color="$YELLOW" ;;
        "ERROR")   color="$RED" ;;
        *)         color="$WHITE" ;;
    esac
    
    echo -e "${color}[${timestamp}] [$level] $message${NC}"
    echo "[${timestamp}] [$level] $message" >> "$LOG_FILE"
}

show_banner() {
    clear
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║                                                          ║"
    echo "║           🚀 YeServe Pro Launcher v$LAUNCHER_VERSION          ║"
    echo "║           专业版脚本启动器（自动依赖安装）                ║"
    echo "║                                                          ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_message "ERROR" "请使用 root 或 sudo 权限运行此脚本"
        echo -e "${RED}请使用以下命令重新运行：${NC}"
        echo -e "${YELLOW}sudo bash $0${NC}"
        exit 1
    fi
    log_message "SUCCESS" "权限检查通过 (root)"
}

check_os() {
    if [ ! -f /etc/os-release ]; then
        log_message "ERROR" "无法检测操作系统"
        exit 1
    fi
    
    source /etc/os-release
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log_message "WARNING" "此脚本主要针对 Ubuntu/Debian 系统，当前系统: $NAME"
        read -p "是否继续？(y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_message "INFO" "操作系统: $NAME $VERSION"
}

install_dependencies() {
    log_message "INFO" "开始安装依赖包..."
    apt-get update -y > /dev/null 2>&1
    
    if [ $? -ne 0 ]; then
        log_message "WARNING" "更新软件包列表失败，尝试继续..."
    fi
    
    local missing_packages=()
    
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            missing_packages+=("$pkg")
        fi
    done
    
    if [ ${#missing_packages[@]} -eq 0 ]; then
        log_message "SUCCESS" "所有依赖包已安装"
        return 0
    fi
    
    log_message "INFO" "需要安装以下依赖包: ${missing_packages[*]}"
    apt-get install -y "${missing_packages[@]}" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        log_message "SUCCESS" "依赖包安装完成"
        for pkg in "${missing_packages[@]}"; do
            if dpkg -l | grep -q "^ii  $pkg "; then
                log_message "INFO" "✅ $pkg 安装成功"
            else
                log_message "WARNING" "⚠️  $pkg 可能安装失败"
            fi
        done
        return 0
    else
        log_message "ERROR" "依赖包安装失败"
        return 1
    fi
}

check_network_connection() {
    log_message "INFO" "检查网络连接..."
    local test_urls=(
        "https://raw.githubusercontent.com"
        "https://github.com"
        "https://download.docker.com"
        "https://hub.docker.com"
    )
    
    local connected=false
    
    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 5 --head "$url" > /dev/null 2>&1; then
            log_message "SUCCESS" "网络连接正常: $url"
            connected=true
            break
        else
            log_message "WARNING" "无法访问: $url"
        fi
    done
    
    if [ "$connected" = false ]; then
        log_message "ERROR" "网络连接失败，请检查网络后重试"
        return 1
    fi
    
    return 0
}

download_pro_script() {
    log_message "INFO" "下载专业版脚本..."
    rm -f "$PRO_SCRIPT_PATH" 2>/dev/null
    
    local download_methods=("curl" "wget")
    local download_success=false
    
    for method in "${download_methods[@]}"; do
        if command -v "$method" > /dev/null 2>&1; then
            log_message "INFO" "使用 $method 下载脚本..."
            
            case $method in
                "curl")
                    if curl -fsSL "$PRO_SCRIPT_URL" -o "$PRO_SCRIPT_PATH" --connect-timeout 30 --retry 3; then
                        download_success=true
                        break
                    fi
                    ;;
                "wget")
                    if wget -q -O "$PRO_SCRIPT_PATH" "$PRO_SCRIPT_URL" --timeout=30 --tries=3; then
                        download_success=true
                        break
                    fi
                    ;;
            esac
        fi
    done
    
    if [ "$download_success" = false ]; then
        log_message "ERROR" "下载专业版脚本失败"
        return 1
    fi
    
    if [ ! -s "$PRO_SCRIPT_PATH" ]; then
        log_message "ERROR" "下载的脚本文件为空"
        return 1
    fi
    
    if ! head -1 "$PRO_SCRIPT_PATH" | grep -q -E "^#!/bin/bash|^#!/usr/bin/env bash"; then
        log_message "ERROR" "下载的文件不是有效的bash脚本"
        return 1
    fi
    
    chmod +x "$PRO_SCRIPT_PATH"
    local file_size=$(du -h "$PRO_SCRIPT_PATH" | cut -f1)
    local line_count=$(wc -l < "$PRO_SCRIPT_PATH" 2>/dev/null || echo "未知")
    
    log_message "SUCCESS" "脚本下载完成"
    log_message "INFO" "文件位置: $PRO_SCRIPT_PATH"
    log_message "INFO" "文件大小: $file_size"
    log_message "INFO" "代码行数: $line_count"
    
    return 0
}

fix_pro_script_issues() {
    log_message "INFO" "检查并修复专业版脚本问题..."
    
    if [ ! -f "$PRO_SCRIPT_PATH" ]; then
        log_message "ERROR" "脚本文件不存在"
        return 1
    fi
    
    cp "$PRO_SCRIPT_PATH" "${PRO_SCRIPT_PATH}.backup" 2>/dev/null
    local fixes_applied=0
    
    if file "$PRO_SCRIPT_PATH" | grep -q "CRLF"; then
        log_message "INFO" "修复CRLF行结束符..."
        sed -i 's/\r$//' "$PRO_SCRIPT_PATH"
        ((fixes_applied++))
    fi
    
    if ! head -1 "$PRO_SCRIPT_PATH" | grep -q "^#!/bin/bash"; then
        log_message "INFO" "修复shebang行..."
        sed -i '1s|^.*$|#!/bin/bash|' "$PRO_SCRIPT_PATH"
        ((fixes_applied++))
    fi
    
    chmod +x "$PRO_SCRIPT_PATH"
    
    if ! grep -q "export CURRENT_LANG=" "$PRO_SCRIPT_PATH"; then
        log_message "INFO" "添加语言环境变量..."
        echo -e "\nexport CURRENT_LANG=\"zh\"" >> "$PRO_SCRIPT_PATH"
        ((fixes_applied++))
    fi
    
    if [ $fixes_applied -gt 0 ]; then
        log_message "SUCCESS" "应用了 $fixes_applied 个修复"
    else
        log_message "INFO" "未发现问题，无需修复"
    fi
    
    return 0
}

prepare_environment() {
    log_message "INFO" "准备运行环境..."
    mkdir -p /backup/yeserve 2>/dev/null
    mkdir -p /var/log/yeserve 2>/dev/null
    mkdir -p /tmp/yeserve 2>/dev/null
    
    export YESERVE_HOME="/opt/yeserve"
    export YESERVE_LOG_DIR="/var/log/yeserve"
    export YESERVE_BACKUP_DIR="/backup/yeserve"
    
    mkdir -p "$YESERVE_HOME" 2>/dev/null
    umask 022
    
    log_message "SUCCESS" "环境准备完成"
}

verify_pro_script() {
    log_message "INFO" "验证专业版脚本..."
    local checks_passed=0
    local total_checks=4
    
    if [ -f "$PRO_SCRIPT_PATH" ]; then
        log_message "INFO" "✅ 脚本文件存在"
        ((checks_passed++))
    else
        log_message "ERROR" "❌ 脚本文件不存在"
    fi
    
    if [ -x "$PRO_SCRIPT_PATH" ]; then
        log_message "INFO" "✅ 脚本文件可执行"
        ((checks_passed++))
    else
        log_message "WARNING" "⚠️ 脚本文件不可执行，尝试修复..."
        chmod +x "$PRO_SCRIPT_PATH"
        if [ -x "$PRO_SCRIPT_PATH" ]; then
            log_message "SUCCESS" "✅ 修复成功，现在可执行"
            ((checks_passed++))
        else
            log_message "ERROR" "❌ 修复失败"
        fi
    fi
    
    if [ -s "$PRO_SCRIPT_PATH" ]; then
        log_message "INFO" "✅ 脚本文件非空"
        ((checks_passed++))
    else
        log_message "ERROR" "❌ 脚本文件为空"
    fi
    
    if file "$PRO_SCRIPT_PATH" | grep -q "text"; then
        log_message "INFO" "✅ 脚本文件格式正确"
        ((checks_passed++))
    else
        log_message "WARNING" "⚠️ 脚本文件格式可能有问题"
    fi
    
    if [ $checks_passed -eq $total_checks ]; then
        log_message "SUCCESS" "✅ 脚本验证通过 ($checks_passed/$total_checks)"
        return 0
    else
        log_message "WARNING" "⚠️ 脚本验证部分通过 ($checks_passed/$total_checks)"
        return 1
    fi
}

check_pro_script_dependencies() {
    log_message "INFO" "检查专业版脚本依赖..."
    
    local pro_dependencies=()
    
    if [ -f "$PRO_SCRIPT_PATH" ]; then
        if grep -q "dialog" "$PRO_SCRIPT_PATH"; then
            pro_dependencies+=("dialog")
        fi
        
        if grep -q "curl" "$PRO_SCRIPT_PATH"; then
            pro_dependencies+=("curl")
        fi
        
        if grep -q "wget" "$PRO_SCRIPT_PATH"; then
            pro_dependencies+=("wget")
        fi
        
        if grep -q "docker" "$PRO_SCRIPT_PATH"; then
            pro_dependencies+=("docker.io" "docker-ce")
        fi
        
        if grep -q "systemctl" "$PRO_SCRIPT_PATH"; then
            pro_dependencies+=("systemd")
        fi
    fi
    
    if [ ${#pro_dependencies[@]} -gt 0 ]; then
        log_message "INFO" "检测到专业版脚本可能需要: ${pro_dependencies[*]}"
        
        for dep in "${pro_dependencies[@]}"; do
            if ! dpkg -l | grep -q "^ii  $dep " 2>/dev/null && ! command -v "$dep" > /dev/null 2>&1; then
                log_message "WARNING" "⚠️  专业版脚本可能需要: $dep"
            fi
        done
    fi
}

run_pro_script() {
    log_message "INFO" "准备运行专业版脚本..."
    
    if [ ! -f "$PRO_SCRIPT_PATH" ]; then
        log_message "ERROR" "专业版脚本不存在，无法运行"
        return 1
    fi
    
    if [ ! -x "$PRO_SCRIPT_PATH" ]; then
        log_message "WARNING" "脚本不可执行，尝试修复..."
        chmod +x "$PRO_SCRIPT_PATH"
        if [ ! -x "$PRO_SCRIPT_PATH" ]; then
            log_message "ERROR" "修复失败，无法运行脚本"
            return 1
        fi
    fi
    
    clear
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}                    启动 YeServe 专业版                        ${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}脚本位置: $PRO_SCRIPT_PATH${NC}"
    echo -e "${YELLOW}日志文件: $PRO_LOG_FILE${NC}"
    echo -e "${YELLOW}开始时间: $(date)${NC}"
    echo ""
    echo -e "${CYAN}注意：${NC}"
    echo -e "1. 专业版脚本可能需要授权码"
    echo -e "2. 安装过程可能需要较长时间"
    echo -e "3. 请确保网络连接稳定"
    echo -e "4. 按 Ctrl+C 可中断安装"
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    read -p "按回车键开始运行专业版脚本，或按 Ctrl+C 取消... " dummy
    
    echo ""
    log_message "INFO" "开始执行专业版脚本..."
    
    local start_time=$(date +%s)
    
    if bash "$PRO_SCRIPT_PATH" 2>&1 | tee -a "$PRO_LOG_FILE"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo ""
        echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}                  专业版脚本执行完成！                        ${NC}"
        echo -e "${GREEN}                    耗时: ${duration}秒                          ${NC}"
        echo -e "${GREEN}══════════════════════════════════════════════════════════════${NC}"
        log_message "SUCCESS" "专业版脚本执行成功，耗时: ${duration}秒"
        return 0
    else
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo ""
        echo -e "${RED}══════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}                  专业版脚本执行失败！                        ${NC}"
        echo -e "${RED}                    耗时: ${duration}秒                          ${NC}"
        echo -e "${RED}══════════════════════════════════════════════════════════════${NC}"
        log_message "ERROR" "专业版脚本执行失败，耗时: ${duration}秒"
        return 1
    fi
}

show_summary() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}                        安装摘要                               ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    echo -e "${YELLOW}📁 文件信息：${NC}"
    echo -e "   启动器日志: $LOG_FILE"
    echo -e "   专业版日志: $PRO_LOG_FILE"
    echo -e "   脚本位置: $PRO_SCRIPT_PATH"
    
    echo ""
    echo -e "${YELLOW}🔧 系统信息：${NC}"
    echo -e "   系统: $(lsb_release -ds 2>/dev/null || grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
    echo -e "   内核: $(uname -r)"
    echo -e "   时间: $(date)"
    
    echo ""
    echo -e "${YELLOW}📦 依赖状态：${NC}"
    for pkg in "${REQUIRED_PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            echo -e "   ✅ $pkg"
        else
            echo -e "   ❌ $pkg"
        fi
    done
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════════${NC}"
}

cleanup() {
    log_message "INFO" "清理临时文件..."
    rm -f "${PRO_SCRIPT_PATH}.backup" 2>/dev/null
    find /tmp -name "yeserve-*" -type f -mtime +1 -delete 2>/dev/null
}

main_menu() {
    while true; do
        show_banner
        
        echo -e "${CYAN}请选择操作：${NC}"
        echo "1. 安装依赖并运行专业版"
        echo "2. 仅安装依赖"
        echo "3. 仅下载专业版脚本"
        echo "4. 验证脚本文件"
        echo "5. 查看日志"
        echo "6. 显示系统信息"
        echo "7. 清理临时文件"
        echo "8. 退出"
        echo ""
        
        read -p "请输入选择 (1-8): " choice
        
        case $choice in
            1)
                install_dependencies
                if [ $? -eq 0 ]; then
                    check_network_connection
                    if [ $? -eq 0 ]; then
                        download_pro_script
                        if [ $? -eq 0 ]; then
                            fix_pro_script_issues
                            prepare_environment
                            check_pro_script_dependencies
                            verify_pro_script
                            run_pro_script
                        fi
                    fi
                fi
                ;;
            2)
                install_dependencies
                ;;
            3)
                check_network_connection
                if [ $? -eq 0 ]; then
                    download_pro_script
                fi
                ;;
            4)
                if [ -f "$PRO_SCRIPT_PATH" ]; then
                    verify_pro_script
                else
                    echo -e "${RED}脚本文件不存在，请先下载${NC}"
                fi
                ;;
            5)
                echo -e "${YELLOW}启动器日志：${NC}"
                tail -20 "$LOG_FILE" 2>/dev/null || echo "日志文件不存在"
                echo ""
                echo -e "${YELLOW}专业版日志：${NC}"
                tail -20 "$PRO_LOG_FILE" 2>/dev/null || echo "日志文件不存在"
                ;;
            6)
                show_summary
                ;;
            7)
                cleanup
                ;;
            8)
                echo -e "${GREEN}退出启动器${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择${NC}"
                ;;
        esac
        
        echo ""
        read -p "按回车键继续..." dummy
    done
}

main() {
    init_logging
    show_banner
    check_root
    check_os
    
    log_message "INFO" "启动器版本: $LAUNCHER_VERSION"
    log_message "INFO" "开始执行..."
    
    main_menu
}

trap 'echo -e "${RED}程序被中断${NC}"; exit 1' INT TERM

main

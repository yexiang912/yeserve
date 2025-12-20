#!/bin/bash

# =============================================
# Ubuntu 服务器一键部署脚本 (适配24.04+)
# 作者: yx原创
# 版本: 2.3
# =============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[警告] $1${NC}"
}

error() {
    echo -e "${RED}[错误] $1${NC}"
}

info() {
    echo -e "${BLUE}[信息] $1${NC}"
}

# 检测是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "请使用root用户运行此脚本！"
        exit 1
    fi
}

# 检测系统版本
check_ubuntu_version() {
    if ! grep -q "Ubuntu" /etc/os-release; then
        error "本脚本仅适用于Ubuntu系统！"
        exit 1
    fi
    
    local version=$(grep "VERSION_ID" /etc/os-release | cut -d'"' -f2)
    if [[ ! "$version" =~ ^24\.04 ]]; then
        warn "本脚本主要为Ubuntu 24.04设计，当前版本为 $version"
        read -p "是否继续？(y/n): " -n 1 user_confirm
        echo
        if [[ ! $user_confirm =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    log "检测到Ubuntu $version 系统"
}

# 显示标题
show_header() {
    clear
    echo "============================================="
    echo "    Ubuntu 服务器环境部署脚本"
    echo "             (yx原创)"
    echo "============================================="
    echo ""
}

# 创建一键切换源脚本
create_source_switch_script() {
    local script_path="/usr/local/bin/switch-ubuntu-source.sh"
    
    # 检查是否已存在
    if [ -f "$script_path" ]; then
        warn "切换源脚本已存在，跳过创建"
        return 0
    fi
    
    # 生成源文件内容
    local tsinghua_source="# 清华大学源
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse
deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse"
    
    local aliyun_source="# 阿里云源
deb https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-proposed main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-proposed main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse"
    
    local huawei_source="# 华为云源
deb https://repo.huaweicloud.com/ubuntu/ noble main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ noble main restricted universe multiverse
deb https://repo.huaweicloud.com/ubuntu/ noble-security main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ noble-security main restricted universe multiverse
deb https://repo.huaweicloud.com/ubuntu/ noble-updates main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ noble-updates main restricted universe multiverse
deb https://repo.huaweicloud.com/ubuntu/ noble-proposed main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ noble-proposed main restricted universe multiverse
deb https://repo.huaweicloud.com/ubuntu/ noble-backports main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ noble-backports main restricted universe multiverse"
    
    local ustc_source="# 中科大源
deb https://mirrors.ustc.edu.cn/ubuntu/ noble main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-security main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ noble-security main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-proposed main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ noble-proposed main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ noble-backports main restricted universe multiverse"
    
    cat > "$script_path" << 'EOF'
#!/bin/bash

# Ubuntu软件源一键切换脚本
# yx原创

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

show_menu() {
    clear
    echo "================================="
    echo "    Ubuntu软件源切换工具"
    echo "          (yx原创)"
    echo "================================="
    echo "1. 清华大学源"
    echo "2. 阿里云源"
    echo "3. 华为云源"
    echo "4. 中科大源"
    echo "5. 恢复官方源"
    echo "6. 查看当前源"
    echo "0. 退出"
    echo "================================="
}

backup_sources() {
    if [ ! -f /etc/apt/sources.list.bak ]; then
        cp /etc/apt/sources.list /etc/apt/sources.list.bak
        echo -e "${GREEN}已备份当前源文件${NC}"
    fi
}

set_tsinghua_source() {
    cat > /etc/apt/sources.list << TSINGHUA_EOF
# 清华大学源
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ noble-security main restricted universe multiverse
TSINGHUA_EOF
}

set_aliyun_source() {
    cat > /etc/apt/sources.list << ALIYUN_EOF
# 阿里云源
deb https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-proposed main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-proposed main restricted universe multiverse
deb https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
deb-src https://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse
ALIYUN_EOF
}

set_huawei_source() {
    cat > /etc/apt/sources.list << HUAWEI_EOF
# 华为云源
deb https://repo.huaweicloud.com/ubuntu/ noble main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ noble main restricted universe multiverse
deb https://repo.huaweicloud.com/ubuntu/ noble-security main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ noble-security main restricted universe multiverse
deb https://repo.huaweicloud.com/ubuntu/ noble-updates main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ noble-updates main restricted universe multiverse
deb https://repo.huaweicloud.com/ubuntu/ noble-proposed main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ noble-proposed main restricted universe multiverse
deb https://repo.huaweicloud.com/ubuntu/ noble-backports main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ noble-backports main restricted universe multiverse
HUAWEI_EOF
}

set_ustc_source() {
    cat > /etc/apt/sources.list << USTC_EOF
# 中科大源
deb https://mirrors.ustc.edu.cn/ubuntu/ noble main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ noble main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-security main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ noble-security main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ noble-updates main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-proposed main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ noble-proposed main restricted universe multiverse
deb https://mirrors.ustc.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
deb-src https://mirrors.ustc.edu.cn/ubuntu/ noble-backports main restricted universe multiverse
USTC_EOF
}

restore_official_source() {
    if [ -f /etc/apt/sources.list.bak ]; then
        cp /etc/apt/sources.list.bak /etc/apt/sources.list
        echo -e "${GREEN}已恢复官方源${NC}"
    else
        cat > /etc/apt/sources.list << OFFICIAL_EOF
# 官方源
deb http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ noble main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ noble-security main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ noble-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-proposed main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ noble-proposed main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
deb-src http://archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse
OFFICIAL_EOF
    fi
}

show_current_source() {
    echo -e "${YELLOW}当前使用的软件源：${NC}"
    echo "---------------------------------"
    head -15 /etc/apt/sources.list
    echo "---------------------------------"
}

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}请使用root用户运行此脚本！${NC}"
    exit 1
fi

# 主程序
main() {
    while true; do
        show_menu
        read -p "请选择操作 (0-6): " choice
        
        case $choice in
            1)
                backup_sources
                set_tsinghua_source
                echo -e "${GREEN}已切换为清华大学源${NC}"
                ;;
            2)
                backup_sources
                set_aliyun_source
                echo -e "${GREEN}已切换为阿里云源${NC}"
                ;;
            3)
                backup_sources
                set_huawei_source
                echo -e "${GREEN}已切换为华为云源${NC}"
                ;;
            4)
                backup_sources
                set_ustc_source
                echo -e "${GREEN}已切换为中科大源${NC}"
                ;;
            5)
                restore_official_source
                ;;
            6)
                show_current_source
                ;;
            0)
                echo "退出脚本"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请重新输入${NC}"
                sleep 1
                continue
                ;;
        esac
        
        if [[ $choice -ge 1 && $choice -le 5 ]]; then
            read -p "是否立即更新软件包列表？(y/n): " update_choice
            if [[ $update_choice == "y" || $update_choice == "Y" ]]; then
                apt-get update
            fi
        fi
        
        echo ""
        read -p "按回车键继续..."
    done
}

main
EOF

    chmod +x "$script_path"
    
    # 如果在桌面环境，创建桌面快捷方式
    if [ -d "/usr/share/applications" ] && [ ! -f "/usr/share/applications/switch-source.desktop" ]; then
        cat > /usr/share/applications/switch-source.desktop << EOF
[Desktop Entry]
Name=切换软件源
Comment=一键切换Ubuntu软件源工具 (yx原创)
Exec=/usr/local/bin/switch-ubuntu-source.sh
Icon=system-software-update
Terminal=true
Type=Application
Categories=System;
EOF
        chmod +x /usr/share/applications/switch-source.desktop
    fi
    
    log "已创建一键切换软件源脚本：$script_path"
    return 0
}

# 安全的命令执行函数
safe_command() {
    local max_retries=3
    local retry_count=0
    local description="$1"
    shift
    
    while [ $retry_count -lt $max_retries ]; do
        log "尝试 $description (第 $((retry_count+1)) 次)"
        
        # 直接执行命令
        if "$@"; then
            log "$description 成功"
            return 0
        fi
        
        retry_count=$((retry_count + 1))
        if [ $retry_count -lt $max_retries ]; then
            warn "$description 失败，${retry_count}秒后重试..."
            sleep $retry_count
        fi
    done
    
    error "$description 失败，已达最大重试次数"
    return 1
}

# 下载文件函数
download_file() {
    local url="$1"
    local output="$2"
    local description="${3:-下载文件}"
    
    safe_command "$description" wget --tries=3 --timeout=30 -O "$output" "$url"
}

# 系统优化配置
system_optimization() {
    info "开始系统优化配置..."
    
    # 更新系统
    log "更新软件包列表..."
    if ! apt-get update -y; then
        warn "软件包列表更新失败，继续执行..."
    fi
    
    # 安装必要软件
    log "安装必要软件..."
    local packages=(
        curl wget vim git net-tools htop iftop iotop screen tmux ufw
        ntpdate software-properties-common apt-transport-https ca-certificates
        gnupg lsb-release chrony
    )
    
    # 批量安装，减少apt调用次数
    local install_list=()
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            install_list+=("$pkg")
        fi
    done
    
    if [ ${#install_list[@]} -gt 0 ]; then
        log "需要安装的软件包: ${install_list[*]}"
        if ! apt-get install -y "${install_list[@]}"; then
            warn "部分软件包安装失败"
        fi
    else
        log "所有必要软件已安装"
    fi
    
    # 设置时区为上海
    timedatectl set-timezone Asia/Shanghai
    log "时区已设置为 Asia/Shanghai"
    
    # 配置时间同步
    systemctl stop systemd-timesyncd 2>/dev/null || true
    systemctl disable systemd-timesyncd 2>/dev/null || true
    systemctl restart chronyd || true
    systemctl enable chronyd || true
    log "时间同步已配置"
    
    # 配置SSH（如果已安装）
    if [ -f "/etc/ssh/sshd_config" ]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
        sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
        sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 60/' /etc/ssh/sshd_config
        if systemctl restart sshd; then
            log "SSH安全配置已更新"
        else
            warn "SSH服务重启失败"
        fi
    else
        warn "SSH未安装，跳过配置"
    fi
    
    # 配置防火墙（仅禁用，不启用）
    ufw --force disable || true
    log "防火墙已禁用（如需启用请手动配置）"
    
    # 优化内核参数
    if [ -f "/etc/sysctl.conf" ]; then
        cp /etc/sysctl.conf /etc/sysctl.conf.bak
    fi
    
    cat >> /etc/sysctl.conf << 'EOF'
# yx原创优化配置
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_no_metrics_save = 1
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_fastopen = 3
net.core.default_qdisc = fq
EOF
    
    if sysctl -p > /dev/null 2>&1; then
        log "内核参数优化完成"
    else
        warn "内核参数优化失败"
    fi
    
    # 创建日志目录
    mkdir -p /var/log/yx-script
    
    log "系统优化配置完成！"
    return 0
}

# Docker安装 - 方案1 (官方源)
install_docker_scheme1() {
    info "开始安装Docker（方案1：官方源）..."
    
    # 清理旧版本
    apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # 安装依赖
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg
    
    # 创建目录
    mkdir -p /etc/apt/keyrings
    
    # 下载并安装Docker官方GPG密钥
    if ! download_file "https://download.docker.com/linux/ubuntu/gpg" "/tmp/docker.gpg" "下载Docker GPG密钥"; then
        error "Docker GPG密钥下载失败"
        return 1
    fi
    
    # 安装密钥
    install -m 0644 /tmp/docker.gpg /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    rm -f /tmp/docker.gpg
    
    # 设置仓库
    local arch=$(dpkg --print-architecture)
    local codename=$(lsb_release -cs)
    echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $codename stable" > /etc/apt/sources.list.d/docker.list
    
    # 安装Docker
    apt-get update -y
    if ! apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; then
        error "Docker包安装失败"
        return 1
    fi
    
    # 启动Docker
    systemctl start docker
    systemctl enable docker
    
    # 测试安装
    sleep 3
    if docker --version &>/dev/null; then
        log "Docker方案1安装成功！版本: $(docker --version | cut -d' ' -f3 | tr -d ',')"
        return 0
    else
        error "Docker方案1安装验证失败！"
        return 1
    fi
}

# Docker安装 - 方案2 (阿里云镜像)
install_docker_scheme2() {
    info "开始安装Docker（方案2：阿里云镜像源）..."
    
    # 清理旧版本（更安全的方式）
    systemctl stop docker 2>/dev/null || true
    apt-get remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io 2>/dev/null || true
    apt-get purge -y docker-ce docker-ce-cli containerd.io 2>/dev/null || true
    
    # 谨慎删除数据目录（先备份再删除）
    if [ -d "/var/lib/docker" ]; then
        warn "发现Docker数据目录，将进行备份..."
        tar -czf /tmp/docker-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /var/lib docker 2>/dev/null || true
        rm -rf /var/lib/docker
    fi
    
    if [ -d "/var/lib/containerd" ]; then
        warn "发现containerd数据目录，将进行备份..."
        tar -czf /tmp/containerd-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /var/lib containerd 2>/dev/null || true
        rm -rf /var/lib/containerd
    fi
    
    # 清理配置目录
    rm -rf /etc/docker
    rm -rf /etc/containerd
    
    # 安装依赖
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg
    
    # 创建目录
    mkdir -p /etc/apt/keyrings
    
    # 使用阿里云镜像安装
    if ! download_file "https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg" "/tmp/docker-aliyun.gpg" "下载阿里云Docker GPG密钥"; then
        error "阿里云Docker GPG密钥下载失败"
        return 1
    fi
    
    # 安装密钥
    install -m 0644 /tmp/docker-aliyun.gpg /etc/apt/keyrings/docker-aliyun.asc
    chmod a+r /etc/apt/keyrings/docker-aliyun.asc
    rm -f /tmp/docker-aliyun.gpg
    
    # 添加阿里云Docker仓库
    local arch=$(dpkg --print-architecture)
    local codename=$(lsb_release -cs)
    echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker-aliyun.asc] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $codename stable" > /etc/apt/sources.list.d/docker-aliyun.list
    
    # 安装Docker
    apt-get update -y
    if ! apt-get install -y docker-ce docker-ce-cli containerd.io; then
        error "Docker包安装失败"
        return 1
    fi
    
    # 配置阿里云镜像加速器
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
    
    # 启动Docker
    systemctl daemon-reload
    systemctl restart docker
    systemctl enable docker
    
    # 测试安装
    sleep 3
    if docker --version &>/dev/null; then
        log "Docker方案2安装成功！版本: $(docker --version | cut -d' ' -f3 | tr -d ',')"
        return 0
    else
        error "Docker方案2安装验证失败！"
        return 1
    fi
}

# Docker安装主函数
install_docker() {
    info "开始安装Docker..."
    
    # 检查是否已安装Docker
    if command -v docker &>/dev/null && docker --version &>/dev/null; then
        warn "Docker已经安装: $(docker --version)"
        read -p "是否重新安装？(y/n): " -n 1 docker_reinstall
        echo
        if [[ ! $docker_reinstall =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    # 尝试方案1
    if install_docker_scheme1; then
        docker_installed=1
    else
        warn "Docker方案1失败，尝试方案2..."
        
        # 尝试方案2
        if install_docker_scheme2; then
            docker_installed=1
        else
            error "两种Docker安装方案都失败了！"
            return 1
        fi
    fi
    
    if [ $docker_installed -eq 1 ]; then
        # 安装docker-compose（如果方案1没有安装）
        if ! command -v docker-compose &>/dev/null; then
            log "安装docker-compose..."
            local compose_url="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
            if download_file "$compose_url" "/usr/local/bin/docker-compose" "下载docker-compose"; then
                chmod +x /usr/local/bin/docker-compose
                if docker-compose --version &>/dev/null; then
                    log "docker-compose安装成功：$(docker-compose --version | cut -d' ' -f3 | tr -d ',')"
                else
                    warn "docker-compose安装可能有问题"
                fi
            else
                warn "docker-compose安装失败"
            fi
        else
            log "docker-compose已安装：$(docker-compose --version | cut -d' ' -f3 | tr -d ',')"
        fi
        
        # 添加当前用户到docker组（如果存在非root用户）
        if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
            if ! getent group docker | grep -q "\b$SUDO_USER\b"; then
                usermod -aG docker "$SUDO_USER"
                log "已将用户 $SUDO_USER 添加到docker组，需要重新登录生效"
            else
                log "用户 $SUDO_USER 已在docker组中"
            fi
        fi
        
        info "Docker安装完成！"
        return 0
    fi
    
    return 1
}

# 安装宝塔面板
install_baota() {
    info "开始安装宝塔面板..."
    
    # 检查是否已安装
    if command -v bt &>/dev/null; then
        warn "宝塔面板已经安装！"
        return 0
    fi
    
    # 检查系统内存（宝塔需要至少1GB内存）
    local mem_total=$(free -m | awk '/^Mem:/{print $2}')
    if [ $mem_total -lt 1024 ]; then
        warn "系统内存较低（${mem_total}MB），宝塔面板可能需要至少1GB内存"
        read -p "是否继续安装？(y/n): " -n 1 baota_mem_confirm
        echo
        if [[ ! $baota_mem_confirm =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # 下载宝塔安装脚本
    log "下载宝塔安装脚本..."
    if ! download_file "https://download.bt.cn/install/install-ubuntu_6.0.sh" "install_bt.sh" "下载宝塔安装脚本"; then
        error "宝塔安装脚本下载失败！"
        return 1
    fi
    
    chmod +x install_bt.sh
    
    # 安装宝塔
    log "正在安装宝塔面板，这可能需要几分钟..."
    log "安装过程日志保存在：/tmp/bt_install.log"
    
    # 使用expect处理交互（如果可用）
    if command -v expect &>/dev/null; then
        cat > /tmp/bt_install.exp << 'EXP_EOF'
#!/usr/bin/expect
set timeout 1200
spawn ./install_bt.sh
expect {
    "Do you want to install Bt-Panel to the * directory?" {
        send "y\r"
        exp_continue
    }
    "Do you want to install Bt-Panel to the * directory?" {
        send "y\r"
        exp_continue
    }
    eof
}
EXP_EOF
        chmod +x /tmp/bt_install.exp
        /tmp/bt_install.exp > /tmp/bt_install.log 2>&1
        rm -f /tmp/bt_install.exp
    else
        # 使用echo传递多个y
        echo -e "y\ny\ny\ny\ny\n" | ./install_bt.sh > /tmp/bt_install.log 2>&1
    fi
    
    # 等待安装完成
    sleep 10
    
    # 检查安装结果
    if [ -f "/etc/init.d/bt" ]; then
        # 等待服务启动
        local bt_started=0
        for i in {1..10}; do
            if /etc/init.d/bt status &>/dev/null; then
                bt_started=1
                break
            fi
            sleep 3
        done
        
        if [ $bt_started -eq 1 ]; then
            log "宝塔面板安装完成！"
            echo "============================================="
            echo "宝塔面板安装完成！"
            echo "访问地址: https://服务器IP:8888"
            
            # 尝试获取默认信息
            if [ -f "/www/server/panel/default.pl" ]; then
                local bt_info=$(cat /www/server/panel/default.pl 2>/dev/null | head -1)
                if [ -n "$bt_info" ]; then
                    local bt_user=$(echo "$bt_info" | cut -d'|' -f1)
                    local bt_pass=$(echo "$bt_info" | cut -d'|' -f2)
                    echo "默认用户名: $bt_user"
                    echo "默认密码: $bt_pass"
                fi
            else
                echo "用户名和密码请查看: /www/server/panel/default.pl"
            fi
            echo "============================================="
        else
            warn "宝塔面板已安装但服务未启动，请手动启动"
        fi
        return 0
    else
        error "宝塔面板安装失败！"
        echo "请查看安装日志: /tmp/bt_install.log"
        return 1
    fi
}

# 安装1Panel面板
install_1panel() {
    info "开始安装1Panel面板..."
    
    # 检查是否已安装
    if command -v 1pctl &>/dev/null; then
        warn "1Panel面板已经安装！"
        return 0
    fi
    
    # 检查系统内存
    local mem_total=$(free -m | awk '/^Mem:/{print $2}')
    if [ $mem_total -lt 1024 ]; then
        warn "系统内存较低（${mem_total}MB），1Panel面板可能需要至少1GB内存"
        read -p "是否继续安装？(y/n): " -n 1 panel_mem_confirm
        echo
        if [[ ! $panel_mem_confirm =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    # 下载安装脚本
    log "下载1Panel安装脚本..."
    if ! download_file "https://resource.fit2cloud.com/1panel/package/quick_start.sh" "install_1panel.sh" "下载1Panel安装脚本"; then
        error "1Panel安装脚本下载失败！"
        return 1
    fi
    
    chmod +x install_1panel.sh
    
    # 自动安装
    log "正在安装1Panel面板，这可能需要几分钟..."
    log "安装过程日志保存在：/tmp/1panel_install.log"
    
    # 安装并捕获输出
    echo -e "y\ny\n" | ./install_1panel.sh > /tmp/1panel_install.log 2>&1
    
    # 等待安装完成
    sleep 15
    
    # 检查安装结果
    if systemctl is-active --quiet 1panel 2>/dev/null; then
        log "1Panel面板安装完成！"
        echo "============================================="
        echo "1Panel面板安装完成！"
        echo "访问地址: https://服务器IP:8080"
        echo "初始账号: admin"
        echo "运行 '1pctl user-info' 查看登录信息"
        echo "============================================="
        return 0
    else
        # 检查服务是否存在
        if systemctl list-unit-files | grep -q "1panel"; then
            # 尝试启动服务
            systemctl start 1panel
            sleep 5
            if systemctl is-active --quiet 1panel; then
                log "1Panel面板启动成功！"
                echo "============================================="
                echo "1Panel面板安装完成！"
                echo "访问地址: https://服务器IP:8080"
                echo "初始账号: admin"
                echo "运行 '1pctl user-info' 查看登录信息"
                echo "============================================="
                return 0
            fi
        fi
        
        error "1Panel面板安装失败！"
        echo "请查看安装日志: /tmp/1panel_install.log"
        return 1
    fi
}

# 安装面板
install_panel() {
    while true; do
        echo ""
        echo "请选择要安装的面板："
        echo "1. 宝塔面板 (适合新手)"
        echo "2. 1Panel面板 (现代化面板)"
        echo "3. 两个都安装"
        echo "4. 都不安装"
        echo ""
        
        read -p "请输入选择 (1-4): " panel_choice
        
        case $panel_choice in
            1)
                install_baota
                break
                ;;
            2)
                install_1panel
                break
                ;;
            3)
                install_baota
                if [ $? -eq 0 ]; then
                    echo ""
                    read -p "宝塔安装完成，是否继续安装1Panel？(y/n): " -n 1 continue_1panel
                    echo
                    if [[ $continue_1panel =~ ^[Yy]$ ]]; then
                        install_1panel
                    fi
                else
                    echo ""
                    read -p "宝塔安装失败，是否继续安装1Panel？(y/n): " -n 1 continue_anyway
                    echo
                    if [[ $continue_anyway =~ ^[Yy]$ ]]; then
                        install_1panel
                    fi
                fi
                break
                ;;
            4)
                log "跳过面板安装"
                break
                ;;
            *)
                warn "无效选择，请重新输入"
                ;;
        esac
    done
}

# 一键清除Docker
clean_docker() {
    info "开始清除Docker..."
    
    # 确认操作
    read -p "警告：这将删除所有Docker容器、镜像和数据！是否继续？(y/n): " -n 1 docker_clean_confirm
    echo
    if [[ ! $docker_clean_confirm =~ ^[Yy]$ ]]; then
        log "用户取消清除Docker"
        return 0
    fi
    
    # 停止所有运行的容器
    log "停止所有Docker容器..."
    docker stop $(docker ps -q) 2>/dev/null || true
    
    # 删除所有容器
    log "删除所有Docker容器..."
    docker rm -f $(docker ps -aq) 2>/dev/null || true
    
    # 删除所有镜像
    log "删除所有Docker镜像..."
    docker rmi -f $(docker images -q) 2>/dev/null || true
    
    # 删除所有卷
    log "删除所有Docker卷..."
    docker volume rm -f $(docker volume ls -q) 2>/dev/null || true
    
    # 删除所有网络
    log "清理Docker网络..."
    docker network prune -f 2>/dev/null || true
    
    # 清理系统
    log "清理Docker系统..."
    docker system prune -a -f --volumes 2>/dev/null || true
    
    # 停止Docker服务
    log "停止Docker服务..."
    systemctl stop docker 2>/dev/null || true
    systemctl stop containerd 2>/dev/null || true
    
    # 备份并删除数据目录
    if [ -d "/var/lib/docker" ]; then
        warn "备份Docker数据目录..."
        local backup_dir="/tmp/docker_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        cp -r /var/lib/docker "$backup_dir/" 2>/dev/null || true
        rm -rf /var/lib/docker
        log "Docker数据已备份到: $backup_dir"
    fi
    
    if [ -d "/var/lib/containerd" ]; then
        rm -rf /var/lib/containerd
    fi
    
    # 删除配置文件
    rm -rf /etc/docker
    rm -rf /etc/containerd
    
    # 卸载Docker软件包
    log "卸载Docker软件包..."
    apt-get remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    apt-get purge -y docker* containerd.io 2>/dev/null || true
    apt-get autoremove -y
    
    # 删除残留文件
    find /usr/local/bin -name "docker*" -type f -delete 2>/dev/null || true
    find /usr/local/bin -name "docker-compose*" -type f -delete 2>/dev/null || true
    
    # 删除用户组
    sed -i '/docker/d' /etc/group 2>/dev/null || true
    
    log "Docker清除完成！"
    return 0
}

# 一键清除宝塔面板
clean_baota() {
    info "开始清除宝塔面板..."
    
    # 确认操作
    read -p "警告：这将删除宝塔面板及其所有数据！是否继续？(y/n): " -n 1 baota_clean_confirm
    echo
    if [[ ! $baota_clean_confirm =~ ^[Yy]$ ]]; then
        log "用户取消清除宝塔面板"
        return 0
    fi
    
    # 停止宝塔服务
    log "停止宝塔服务..."
    if [ -f "/etc/init.d/bt" ]; then
        /etc/init.d/bt stop 2>/dev/null || true
    fi
    
    # 备份网站数据（如果有）
    if [ -d "/www/wwwroot" ]; then
        warn "备份网站数据..."
        local backup_dir="/tmp/baota_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        cp -r /www/wwwroot "$backup_dir/" 2>/dev/null || true
        cp -r /www/backup "$backup_dir/" 2>/dev/null || true
        log "宝塔数据已备份到: $backup_dir"
    fi
    
    # 运行宝塔卸载脚本（如果存在）
    if [ -f "/www/server/panel/install.sh" ]; then
        log "运行宝塔卸载脚本..."
        cd /www/server/panel && bash install.sh uninstall 2>/dev/null || true
    fi
    
    # 删除宝塔目录
    log "删除宝塔文件..."
    rm -rf /www/server/panel
    rm -rf /www/server/btpanel
    rm -rf /tmp/panel*
    rm -rf /tmp/bt*
    
    # 删除服务文件
    rm -f /etc/init.d/bt
    rm -f /etc/systemd/system/bt.service 2>/dev/null || true
    rm -f /usr/lib/systemd/system/bt.service 2>/dev/null || true
    
    # 删除命令
    rm -f /usr/bin/bt
    rm -f /usr/local/bin/bt
    
    # 删除计划任务
    crontab -l | grep -v "www/server/panel" | crontab - 2>/dev/null || true
    
    # 删除环境变量
    sed -i '/\/www\/server\/panel/d' /etc/profile 2>/dev/null || true
    sed -i '/\/www\/server\/panel/d' /etc/bash.bashrc 2>/dev/null || true
    
    # 清理残留进程
    pkill -9 -f "python.*panel" 2>/dev/null || true
    pkill -9 -f "bt-panel" 2>/dev/null || true
    
    log "宝塔面板清除完成！"
    return 0
}

# 一键清除1Panel面板
clean_1panel() {
    info "开始清除1Panel面板..."
    
    # 确认操作
    read -p "警告：这将删除1Panel面板及其所有数据！是否继续？(y/n): " -n 1 panel_clean_confirm
    echo
    if [[ ! $panel_clean_confirm =~ ^[Yy]$ ]]; then
        log "用户取消清除1Panel面板"
        return 0
    fi
    
    # 停止1Panel服务
    log "停止1Panel服务..."
    systemctl stop 1panel 2>/dev/null || true
    systemctl stop 1panel-daemon 2>/dev/null || true
    
    # 备份数据（如果有）
    if [ -d "/opt/1panel" ]; then
        warn "备份1Panel数据..."
        local backup_dir="/tmp/1panel_backup_$(date +%Y%m%d_%H%M%S)"
        mkdir -p "$backup_dir"
        cp -r /opt/1panel "$backup_dir/" 2>/dev/null || true
        log "1Panel数据已备份到: $backup_dir"
    fi
    
    # 运行1Panel卸载脚本（如果存在）
    if command -v 1pctl &>/dev/null; then
        log "运行1Panel卸载命令..."
        1pctl uninstall 2>/dev/null || true
    fi
    
    # 删除1Panel目录
    log "删除1Panel文件..."
    rm -rf /opt/1panel
    rm -rf /usr/local/bin/1panel
    rm -rf /usr/local/bin/1pctl
    
    # 删除服务文件
    systemctl disable 1panel 2>/dev/null || true
    systemctl disable 1panel-daemon 2>/dev/null || true
    rm -f /etc/systemd/system/1panel.service
    rm -f /etc/systemd/system/1panel-daemon.service
    systemctl daemon-reload
    
    # 删除用户和组
    userdel -r 1panel 2>/dev/null || true
    groupdel 1panel 2>/dev/null || true
    
    # 清理残留进程
    pkill -9 -f "1panel" 2>/dev/null || true
    pkill -9 -f "1panel-daemon" 2>/dev/null || true
    
    # 删除防火墙规则
    ufw delete allow 8080/tcp 2>/dev/null || true
    ufw delete allow 8081/tcp 2>/dev/null || true
    
    log "1Panel面板清除完成！"
    return 0
}

# 一键清除所有面板和Docker
clean_all() {
    info "开始清除所有面板和Docker..."
    
    # 确认操作
    echo "警告：这将执行以下操作："
    echo "1. 清除Docker（所有容器、镜像、数据）"
    echo "2. 清除宝塔面板"
    echo "3. 清除1Panel面板"
    echo "4. 清理相关残留文件"
    echo ""
    read -p "这是危险操作！是否继续？(输入'YES'继续): " confirm_input
    
    if [ "$confirm_input" != "YES" ]; then
        log "用户取消清除操作"
        return 0
    fi
    
    # 清除1Panel
    if systemctl list-unit-files | grep -q "1panel" || [ -f "/opt/1panel" ]; then
        clean_1panel
    else
        log "1Panel未安装，跳过清除"
    fi
    
    # 清除宝塔
    if [ -f "/etc/init.d/bt" ] || command -v bt &>/dev/null; then
        clean_baota
    else
        log "宝塔未安装，跳过清除"
    fi
    
    # 清除Docker
    if command -v docker &>/dev/null || [ -d "/var/lib/docker" ]; then
        clean_docker
    else
        log "Docker未安装，跳过清除"
    fi
    
    # 清理系统
    log "清理系统残留..."
    apt-get autoremove -y
    apt-get autoclean -y
    
    log "所有面板和Docker清除完成！"
    echo "============================================="
    echo "重要提示："
    echo "1. 备份文件保存在 /tmp/ 目录下"
    echo "2. 建议重启系统以确保完全清理"
    echo "3. 如需重新安装，请运行本脚本"
    echo "============================================="
    return 0
}

# 系统完整性检查
system_integrity_check() {
    info "开始系统完整性检查..."
    
    local errors=0
    local warnings=0
    
    echo ""
    echo "============================================="
    echo "             系统完整性检查报告"
    echo "             (yx原创脚本检测)"
    echo "============================================="
    
    # 检查必要软件
    echo ""
    echo "1. 必要软件检查："
    local essential_tools=("curl" "wget" "vim" "git" "htop")
    
    for tool in "${essential_tools[@]}"; do
        if command -v $tool &>/dev/null; then
            echo -e "   ✓ $tool 已安装"
        else
            echo -e "   ✗ $tool 未安装"
            ((warnings++))
        fi
    done
    
    # 检查Docker状态
    echo ""
    echo "2. Docker服务检查："
    if command -v docker &>/dev/null; then
        if systemctl is-active --quiet docker; then
            echo "   ✓ Docker服务运行正常"
            echo "   ✓ Docker版本: $(docker --version | cut -d' ' -f3 | tr -d ',')"
            
            # 检查docker-compose
            if command -v docker-compose &>/dev/null; then
                echo "   ✓ docker-compose: $(docker-compose --version | cut -d' ' -f3 | tr -d ',')"
            else
                echo "   ⚠ docker-compose 未安装或未找到"
                ((warnings++))
            fi
        else
            echo "   ✗ Docker服务未运行"
            ((errors++))
        fi
    else
        echo "   ✗ Docker 未安装"
        ((warnings++))
    fi
    
    # 检查面板服务
    echo ""
    echo "3. 面板服务检查："
    
    # 检查宝塔
    if [ -f "/etc/init.d/bt" ]; then
        if /etc/init.d/bt status &>/dev/null; then
            echo "   ✓ 宝塔面板运行正常"
            if [ -f "/www/server/panel/default.pl" ]; then
                local bt_default=$(cat /www/server/panel/default.pl 2>/dev/null | head -1)
                if [ -n "$bt_default" ]; then
                    echo "   📋 默认用户名: $(echo "$bt_default" | cut -d'|' -f1)"
                fi
            fi
        else
            echo "   ✗ 宝塔面板未运行"
            ((warnings++))
        fi
    else
        echo "   ℹ 宝塔面板未安装"
    fi
    
    # 检查1Panel
    if systemctl list-unit-files | grep -q "1panel"; then
        if systemctl is-active --quiet 1panel; then
            echo "   ✓ 1Panel面板运行正常"
        else
            echo "   ✗ 1Panel面板未运行"
            ((warnings++))
        fi
    else
        echo "   ℹ 1Panel面板未安装"
    fi
    
    # 检查系统资源
    echo ""
    echo "4. 系统资源检查："
    local mem_info=$(free -h | awk '/^Mem:/{print $2 " 可用:" $7}')
    local disk_info=$(df -h / | awk 'NR==2 {print $4 "/" $2 " 可用 (" $5 " 已用)"}')
    local load_info=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
    
    echo "   ✓ 内存: $mem_info"
    echo "   ✓ 磁盘: $disk_info"
    echo "   ✓ 系统负载: $load_info"
    
    # 检查网络连接
    echo ""
    echo "5. 网络连接检查："
    if timeout 5 ping -c 2 -W 2 mirrors.aliyun.com &>/dev/null; then
        echo "   ✓ 外网连接正常"
    else
        echo "   ✗ 外网连接异常"
        ((warnings++))
    fi
    
    # 检查时区
    echo ""
    echo "6. 系统配置检查："
    local current_timezone=$(timedatectl | grep "Time zone" | cut -d':' -f2 | xargs)
    if [ "$current_timezone" = "Asia/Shanghai" ]; then
        echo "   ✓ 时区设置正确: $current_timezone"
    else
        echo "   ⚠ 时区设置可能不正确: $current_timezone"
        ((warnings++))
    fi
    
    # 检查防火墙状态
    echo ""
    echo "7. 防火墙状态："
    if systemctl is-active --quiet ufw; then
        echo "   ⚠ 防火墙已启用，请确认规则配置"
        ((warnings++))
    else
        echo "   ℹ 防火墙未启用（建议根据需要配置）"
    fi
    
    # 检查内核参数
    echo ""
    echo "8. 内核参数检查："
    if grep -q "yx原创优化配置" /etc/sysctl.conf; then
        echo "   ✓ 内核优化配置已应用"
    else
        echo "   ℹ 内核优化配置未应用"
    fi
    
    # 总结报告
    echo ""
    echo "============================================="
    echo "检查完成！"
    echo ""
    
    if [ $errors -gt 0 ]; then
        echo -e "${RED}❌ 发现 $errors 个严重错误，需要立即处理！${NC}"
    fi
    
    if [ $warnings -gt 0 ]; then
        echo -e "${YELLOW}⚠️  发现 $warnings 个警告，建议检查${NC}"
    fi
    
    if [ $errors -eq 0 ] && [ $warnings -eq 0 ]; then
        echo -e "${GREEN}✅ 所有检查通过，系统状态良好！${NC}"
    fi
    
    echo ""
    echo "============================================="
    echo "重要提示："
    echo "1. 请及时修改面板的默认密码"
    echo "2. 建议配置防火墙规则"
    echo "3. 定期更新系统和软件"
    echo "4. 使用 'switch-ubuntu-source.sh' 切换软件源"
    echo "============================================="
    
    read -p "按回车键返回主菜单..."
    return 0
}

# 确认执行
confirm_execution() {
    show_header
    echo "警告：本脚本将修改系统配置并安装软件。"
    echo "请确保您已经备份重要数据。"
    echo ""
    read -p "是否继续执行？(y/n): " -n 1 start_confirm
    echo
    if [[ ! $start_confirm =~ ^[Yy]$ ]]; then
        log "用户取消执行"
        exit 0
    fi
}

# 主菜单
main_menu() {
    while true; do
        show_header
        
        echo "请选择要执行的操作："
        echo "1. 系统优化配置 + 切换软件源"
        echo "2. 安装Docker"
        echo "3. 安装面板"
        echo "4. 完整安装（全部执行）"
        echo "5. 仅运行系统完整性检查"
        echo "6. 创建桌面切换源脚本"
        echo "7. 清理工具（清除面板/Docker）"
        echo "0. 退出"
        echo ""
        
        read -p "请输入选择 (0-7): " choice
        
        case $choice in
            1)
                create_source_switch_script
                system_optimization
                ;;
            2)
                install_docker
                ;;
            3)
                install_panel
                ;;
            4)
                create_source_switch_script
                system_optimization
                install_docker
                install_panel
                ;;
            5)
                system_integrity_check
                continue
                ;;
            6)
                create_source_switch_script
                ;;
            7)
                cleanup_menu
                continue
                ;;
            0)
                log "感谢使用！再见！"
                exit 0
                ;;
            *)
                error "无效选择！"
                sleep 2
                continue
                ;;
        esac
        
        echo ""
        read -p "操作完成，按回车键返回主菜单..."
    done
}

# 清理菜单
cleanup_menu() {
    while true; do
        show_header
        
        echo "清理工具 - 请选择要清理的项目："
        echo "1. 清除Docker（所有容器、镜像、数据）"
        echo "2. 清除宝塔面板"
        echo "3. 清除1Panel面板"
        echo "4. 清除所有面板和Docker"
        echo "5. 返回主菜单"
        echo "0. 退出"
        echo ""
        
        read -p "请输入选择 (0-5): " cleanup_choice
        
        case $cleanup_choice in
            1)
                clean_docker
                ;;
            2)
                clean_baota
                ;;
            3)
                clean_1panel
                ;;
            4)
                clean_all
                ;;
            5)
                return 0
                ;;
            0)
                log "感谢使用！再见！"
                exit 0
                ;;
            *)
                error "无效选择！"
                sleep 2
                continue
                ;;
        esac
        
        echo ""
        read -p "清理完成，按回车键继续..."
    done
}

# 主函数
main() {
    # 检查权限和系统版本
    check_root
    check_ubuntu_version
    
    # 确认执行
    confirm_execution
    
    # 创建日志目录
    mkdir -p /var/log/yx-script
    
    # 记录开始时间
    local start_time=$(date +%s)
    log "脚本开始执行"
    
    # 显示主菜单
    main_menu
    
    # 记录结束时间
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    log "脚本执行完成，总耗时: ${duration}秒"
}

# 设置异常处理
trap 'error "脚本被中断"; exit 1' INT TERM

# 执行主函数
main "$@"
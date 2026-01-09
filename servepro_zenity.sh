#!/bin/bash

auto_install_deps() {
    local pkgm=""
    if command -v apt &> /dev/null; then
        pkgm="apt"
    elif command -v yum &> /dev/null; then
        pkgm="yum"
    elif command -v dnf &> /dev/null; then
        pkgm="dnf"
    elif command -v pacman &> /dev/null; then
        pkgm="pacman"
    elif command -v zypper &> /dev/null; then
        pkgm="zypper"
    else
        echo "错误：找不到包管理器"
        exit 1
    fi
    echo "正在安装依赖..."
    local result=0
    case $pkgm in
        apt) sudo apt update >/dev/null 2>&1 && sudo apt install -y openssl coreutils >/dev/null 2>&1 ;;
        yum) sudo yum install -y openssl coreutils >/dev/null 2>&1 ;;
        dnf) sudo dnf install -y openssl coreutils >/dev/null 2>&1 ;;
        pacman) sudo pacman -Sy --noconfirm openssl coreutils >/dev/null 2>&1 ;;
        zypper) sudo zypper install -y openssl coreutils >/dev/null 2>&1 ;;
    esac
    result=$?
    if [ $result -eq 0 ] && command -v openssl &> /dev/null && command -v base64 &> /dev/null; then
        echo "依赖安装成功！"
        return 0
    else
        echo "依赖安装失败"
        echo "需要：openssl, base64"
        exit 1
    fi
}

check_and_install_deps() {
    if ! command -v openssl &> /dev/null || ! command -v base64 &> /dev/null; then
        echo "正在检查并安装必要依赖..."
        auto_install_deps
    fi
}

check_enc() {
    grep -q "^# ENC_DATA_START$" "$0" && grep -q "^# ENC_DATA_END$" "$0"
}

decrypt_run() {
    check_and_install_deps
    local tries=0
    local max_tries=3
    local pass=""
    clear
    echo "========================================"
    echo "         文件解密器"
    echo "========================================"
    echo ""
    while [ $tries -lt $max_tries ]; do
        tries=$((tries + 1))
        echo "输入解密密码（尝试 ${tries}/3）："
        read -sp "密码: " pass
        echo ""
        if [ -z "$pass" ]; then
            echo "密码不能为空！"
            sleep 1
            continue
        fi
        local start_line end_line
        start_line=$(grep -n "^# ENC_DATA_START$" "$0" | head -1 | cut -d: -f1)
        end_line=$(grep -n "^# ENC_DATA_END$" "$0" | head -1 | cut -d: -f1)
        if [ -z "$start_line" ] || [ -z "$end_line" ]; then
            echo "错误：数据损坏！"
            exit 1
        fi
        start_line=$((start_line + 1))
        end_line=$((end_line - 1))
        if [ $start_line -ge $end_line ]; then
            echo "错误：数据为空！"
            exit 1
        fi
        TEMP_FILE=$(mktemp /tmp/dec_XXXXXXXX)
        if sed -n "${start_line},${end_line}p" "$0" | base64 -d 2>/dev/null | \
           openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -d -salt -pass pass:"$pass" -out "$TEMP_FILE" 2>/dev/null; then
            if [ -s "$TEMP_FILE" ]; then
                echo "✓ 密码正确！"
                echo "----------------------------------------"
                echo ""
                if head -n 1 "$TEMP_FILE" | grep -q "^#"; then
                    tail -n +2 "$TEMP_FILE" > "${TEMP_FILE}_clean"
                    mv "${TEMP_FILE}_clean" "$TEMP_FILE"
                fi
                if head -n 1 "$TEMP_FILE" 2>/dev/null | grep -q "^#!"; then
                    chmod +x "$TEMP_FILE"
                    echo "正在执行解密后的文件..."
                    echo "========================================"
                    exec bash "$TEMP_FILE" "$@"
                else
                    echo "解密成功！内容已加载到内存。"
                    echo ""
                    echo "========================================"
                    echo "文件内容预览："
                    echo "========================================"
                    if file "$TEMP_FILE" | grep -q -i "text\|ascii"; then
                        cat "$TEMP_FILE"
                    else
                        echo "二进制文件，无法显示内容。"
                        echo "文件信息："
                        file "$TEMP_FILE"
                    fi
                    echo "========================================"
                    rm -f "$TEMP_FILE" 2>/dev/null
                    echo ""
                    echo "按 Enter 退出..."
                    read
                    exit 0
                fi
            fi
        fi
        rm -f "$TEMP_FILE" 2>/dev/null
        if [ $tries -lt $max_tries ]; then
            echo "✗ 密码错误！"
            echo "剩余尝试：$((max_tries - tries))"
            echo ""
            sleep 1
        fi
    done
    echo "========================================"
    echo "     密码验证失败！超过最大尝试次数"
    echo "========================================"
    echo ""
    exit 1
}

main_self_decrypt() {
    if check_enc; then
        decrypt_run "$@"
    else
        echo "错误：这不是有效的加密文件！"
        echo ""
        echo "这是一个自解密文件，请直接运行它并输入密码。"
        exit 1
    fi
}

main_self_decrypt "$@"

# ENC_DATA_START
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

# ENC_DATA_END

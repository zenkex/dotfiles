#!/bin/bash

# ==========================================
# 函数: 显示帮助信息
# ==========================================
show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Description:
    此脚本用于在中国大陆快速安装 Rust 开发环境。
    它会自动配置 USTC (中科大) 的镜像源来加速：
    1. rustup 工具链的下载
    2. cargo 依赖包 (crates.io) 的下载

Options:
    -h, --help      显示此帮助信息并退出

Examples:
    ./install_rust.sh

Notes:
    安装完成后，脚本会自动写入 ~/.cargo/config 配置文件。
    如果该文件已存在，旧文件会被重命名为 config.bak。
EOF
}

# ==========================================
# 主逻辑
# ==========================================

# 1. 检查参数
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

echo ">> 正在准备安装 Rust 环境..."

# 2. 配置 Rustup 安装源 (用于下载编译器本身)
export RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
export RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static

echo ">>以此镜像源开始下载并安装 rustup (自动确认默认选项)..."

# 使用 -y 参数进行非交互式安装 (静默安装)
if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y; then
    echo ">> Rustup 安装成功！"
else
    echo ">> Rustup 安装失败，请检查网络连接。"
    exit 1
fi

# 3. 配置 Cargo 镜像源 (用于下载第三方依赖)
echo ">> 正在配置 Cargo 镜像源 (USTC)..."

CARGO_DIR="$HOME/.cargo"
CONFIG_FILE="$CARGO_DIR/config"

# 确保 .cargo 目录存在
if [ ! -d "$CARGO_DIR" ]; then
    mkdir -p "$CARGO_DIR"
fi

# 备份旧配置 (如果存在)
if [ -f "$CONFIG_FILE" ]; then
    echo ">> 检测到已存在配置文件，正在备份为 config.bak ..."
    cp "$CONFIG_FILE" "$CONFIG_FILE.bak"
fi

# 写入新的国内源配置
# 这里使用 sparse 协议 (sparse+https) 也可以，但 git 协议兼容性最好
cat > "$CONFIG_FILE" <<EOF
[source.crates-io]
replace-with = 'ustc'

[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"
EOF

echo ">> Cargo 镜像源配置完成。"

# 4. 结尾提示
# source 环境变量以便在当前脚本后续（如果有）能用，
# 但对父 Shell 需要用户手动 source
source "$HOME/.cargo/env"

echo "===================================================="
echo "  Rust 安装及国内加速配置已全部完成！"
echo ""
echo "  请执行以下命令使环境变量立即生效："
echo "  source $HOME/.cargo/env"
echo "===================================================="
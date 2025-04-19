#!/bin/bash

# 检查是否安装了必要的工具
if ! command -v swift &> /dev/null; then
    echo "错误: 未安装 Swift"
    echo "请先安装 Xcode 和 Swift"
    exit 1
fi

# 显示帮助信息
show_help() {
    echo "使用方法: $0 [选项]"
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -r, --run      编译并运行项目"
    echo "  -b, --build    仅编译生成二进制文件"
    echo "默认选项: --run"
}

# 设置默认动作
ACTION="run"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -r|--run)
            ACTION="run"
            shift
            ;;
        -b|--build)
            ACTION="build"
            shift
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 解析依赖
echo "正在解析依赖..."
swift package resolve

# 编译项目（发布模式）
echo "正在编译项目（发布模式）..."
swift build -c release

# 如果编译成功
if [ $? -eq 0 ]; then
    echo "编译成功！"
    
    # 创建 dist 目录（如果不存在）
    mkdir -p dist
    
    # 复制二进制文件到 dist 目录
    cp .build/release/AppleVision dist/apple-vision
    
    # 复制静态文件到 dist 目录
    echo "正在复制静态文件..."
    mkdir -p dist/Public
    cp -r Public/* dist/Public/
    
    echo "二进制文件已生成: dist/apple-vision"
    
    # 根据动作执行不同操作
    if [ "$ACTION" = "run" ]; then
        echo "正在启动服务器..."
        cd dist && ./apple-vision
    else
        echo "使用方法："
        echo "1. 直接运行: dist/apple-vision"
    fi
else
    echo "编译失败，请检查错误信息"
    exit 1
fi 
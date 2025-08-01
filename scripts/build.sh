#!/bin/bash

set -e # 遇到错误立即退出

echo "🚀 开始 Vercel 构建流程..."

# 读取 HASH 文件确定要拉取的 commit
if [ ! -f "HASH" ]; then
    echo "❌ 未找到 HASH 文件"
    exit 1
fi

TARGET_COMMIT=$(cat HASH | tr -d '\n\r')
echo "🎯 目标 commit/branch: $TARGET_COMMIT"

# 1. 使用 git 拉取 innei-dev/shiroi 仓库到当前目录，不要文件夹
echo "📦 克隆 innei-dev/shiroi 仓库..."

rm -rf .git
# 初始化空的 git 仓库
git init
# 添加远程仓库
if [ -n "$GH_TOKEN" ]; then
    echo "🔑 使用 GitHub Token 进行身份验证..."
    git remote add origin https://$GH_TOKEN@github.com/innei-dev/shiroi.git
else
    echo "⚠️  未设置 GH_TOKEN，使用公开访问（可能会失败于私有仓库）"
    git remote add origin https://github.com/innei-dev/shiroi.git
fi
# 获取远程信息
git fetch origin
# 拉取指定的 commit/branch 到当前目录
git checkout "$TARGET_COMMIT" || git checkout "origin/$TARGET_COMMIT"

# 2. 启动 git lfs
echo "🔧 启动 Git LFS..."
git lfs install
git lfs pull

# 3. 运行 shiroi 的构建
echo "🏗️  开始构建 shiroi..."

# 检查是否存在 package.json
if [ ! -f "package.json" ]; then
    echo "❌ 未找到 package.json 文件"
    exit 1
fi

# 安装依赖 (优先使用 pnpm，其次 npm)
echo "📦 安装依赖..."
if command -v pnpm &>/dev/null; then
    echo "使用 pnpm 安装依赖..."
    pnpm install
elif command -v npm &>/dev/null; then
    echo "使用 npm 安装依赖..."
    npm install
else
    echo "❌ 未找到 pnpm 或 npm"
    exit 1
fi

# 运行构建命令
echo "🔨 执行构建..."
if command -v pnpm &>/dev/null; then
    pnpm run build
elif command -v npm &>/dev/null; then
    npm run build
else
    echo "❌ 未找到包管理器"
    exit 1
fi

echo "✅ 构建完成！"

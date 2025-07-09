#!/bin/bash

echo "=== 双仓库部署测试脚本 ==="

# 检查public目录的Git配置
echo "1. 检查部署配置..."

if [ -d "public/.git" ]; then
    echo "✓ public目录确实是独立的Git仓库"
    
    cd public
    echo "Pages仓库远程URL:"
    git remote -v
    
    # 提取Pages仓库信息
    PAGES_REMOTE=$(git remote get-url origin 2>/dev/null)
    echo "Pages仓库: $PAGES_REMOTE"
    
    if [[ $PAGES_REMOTE =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
        USERNAME="${BASH_REMATCH[1]}"
        REPO="${BASH_REMATCH[2]}"
        
        echo "GitHub用户名: $USERNAME"
        echo "Pages仓库名: $REPO"
        
        # 生成GitHub Pages URL
        if [ "$REPO" = "${USERNAME}.github.io" ]; then
            # 用户主页仓库
            GITHUB_PAGES_URL="https://${USERNAME}.github.io/"
        else
            # 项目页面仓库
            GITHUB_PAGES_URL="https://${USERNAME}.github.io/${REPO}/"
        fi
        
        echo "GitHub Pages URL: $GITHUB_PAGES_URL"
    fi
    
    # 检查当前分支
    echo "当前分支: $(git branch --show-current)"
    
    # 检查最后提交
    echo "最后提交: $(git log --oneline -1)"
    
    cd ..
else
    echo "❌ public目录不是Git仓库！"
    echo "需要设置public目录为Pages仓库"
    exit 1
fi

echo ""
echo "2. 检查主仓库配置:"
echo "主仓库远程URL:"
git remote -v
echo "当前baseURL: $(grep 'baseURL' config/_default/hugo.toml)"

echo ""
echo "选择测试模式："
echo "a. 使用GitHub Pages URL测试并部署"
echo "b. 使用自定义域名测试并部署"
echo "c. 对比不同URL的构建结果"
echo "d. 检查当前Pages部署状态"
echo "e. 重新设置public仓库"

read -p "输入选择 (a/b/c/d/e): " choice

case $choice in
    a)
        echo ""
        echo "使用GitHub Pages URL测试..."
        
        if [ -z "$GITHUB_PAGES_URL" ]; then
            read -p "请输入您的GitHub Pages URL: " GITHUB_PAGES_URL
        fi
        
        # 备份配置
        cp config/_default/hugo.toml config/_default/hugo.toml.backup
        echo "✓ 配置已备份"
        
        # 修改baseURL
        sed -i.tmp "s|baseURL = \".*\"|baseURL = \"$GITHUB_PAGES_URL\"|" config/_default/hugo.toml
        echo "✓ baseURL已更改为: $GITHUB_PAGES_URL"
        
        # 构建
        echo "构建网站..."
        rm -rf public/* public/.*[^.] 2>/dev/null || true  # 清理但保留.git
        hugo --minify
        
        if [ $? -eq 0 ]; then
            echo "✓ 构建成功"
            
            # 检查生成的链接
            echo ""
            echo "检查生成的资源链接:"
            echo "CSS: $(grep -o "href=\"[^\"]*\.css[^\"]*\"" public/index.html | head -1)"
            echo "JS: $(grep -o "src=\"[^\"]*\.js[^\"]*\"" public/index.html | head -1)"
            
            # 部署到Pages仓库
            echo ""
            read -p "是否部署到GitHub Pages? (y/n): " deploy
            if [ "$deploy" = "y" ]; then
                cd public
                
                # 检查是否有变更
                git add .
                if git diff --cached --quiet; then
                    echo "没有变更需要部署"
                else
                    git commit -m "Deploy with GitHub Pages URL: $(date '+%Y-%m-%d %H:%M:%S')"
                    git push origin main
                    echo "✓ 已部署到GitHub Pages"
                    echo "请等待几分钟，然后访问: $GITHUB_PAGES_URL"
                fi
                
                cd ..
            fi
        else
            echo "✗ 构建失败"
        fi
        ;;
        
    b)
        echo ""
        echo "使用自定义域名测试..."
        
        # 确保使用原始配置
        if [ -f "config/_default/hugo.toml.backup" ]; then
            cp config/_default/hugo.toml.backup config/_default/hugo.toml
        fi
        
        echo "当前baseURL: $(grep 'baseURL' config/_default/hugo.toml)"
        
        # 构建
        echo "构建网站..."
        rm -rf public/* public/.*[^.] 2>/dev/null || true
        hugo --minify
        
        if [ $? -eq 0 ]; then
            echo "✓ 构建成功"
            
            # 检查/创建CNAME文件
            if [ ! -f "public/CNAME" ]; then
                echo "boyi-wang.com" > public/CNAME
                echo "✓ 创建CNAME文件"
            else
                echo "✓ CNAME文件已存在: $(cat public/CNAME)"
            fi
            
            # 部署
            read -p "是否部署到GitHub Pages? (y/n): " deploy
            if [ "$deploy" = "y" ]; then
                cd public
                git add .
                if git diff --cached --quiet; then
                    echo "没有变更需要部署"
                else
                    git commit -m "Deploy with custom domain: $(date '+%Y-%m-%d %H:%M:%S')"
                    git push origin main
                    echo "✓ 已部署到GitHub Pages"
                    echo "访问: https://boyi-wang.com"
                fi
                cd ..
            fi
        fi
        ;;
        
    c)
        echo ""
        echo "对比不同URL的构建结果..."
        
        # 创建临时目录
        mkdir -p deployment_test
        
        # 测试1: GitHub Pages URL
        if [ -n "$GITHUB_PAGES_URL" ]; then
            echo "构建GitHub Pages版本..."
            sed "s|baseURL = \".*\"|baseURL = \"$GITHUB_PAGES_URL\"|" config/_default/hugo.toml > config/_default/hugo_github.toml
            hugo --config config/_default/hugo_github.toml --destination deployment_test/github_pages
            
            echo "GitHub Pages版本CSS链接:"
            grep -o "href=\"[^\"]*\.css[^\"]*\"" deployment_test/github_pages/index.html | head -1
        fi
        
        # 测试2: 自定义域名
        echo "构建自定义域名版本..."
        hugo --destination deployment_test/custom_domain
        
        echo "自定义域名版本CSS链接:"
        grep -o "href=\"[^\"]*\.css[^\"]*\"" deployment_test/custom_domain/index.html | head -1
        
        echo ""
        echo "对比文件保存在 deployment_test/ 目录"
        
        # 清理
        rm -f config/_default/hugo_github.toml
        ;;
        
    d)
        echo ""
        echo "检查当前Pages部署状态..."
        
        cd public
        echo "Pages仓库状态:"
        git status
        
        echo ""
        echo "最近的提交:"
        git log --oneline -5
        
        echo ""
        echo "检查CNAME文件:"
        if [ -f "CNAME" ]; then
            echo "✓ CNAME文件存在: $(cat CNAME)"
        else
            echo "❌ CNAME文件不存在"
        fi
        
        echo ""
        echo "检查index.html:"
        if [ -f "index.html" ]; then
            echo "✓ index.html存在"
            echo "CSS链接: $(grep -o "href=\"[^\"]*\.css[^\"]*\"" index.html | head -1)"
        else
            echo "❌ index.html不存在"
        fi
        
        cd ..
        
        if [ -n "$GITHUB_PAGES_URL" ]; then
            echo ""
            echo "测试访问:"
            if command -v curl >/dev/null 2>&1; then
                echo "GitHub Pages响应:"
                curl -I "$GITHUB_PAGES_URL" 2>/dev/null | head -3 || echo "无法访问"
                
                echo "自定义域名响应:"
                curl -I "https://boyi-wang.com/" 2>/dev/null | head -3 || echo "无法访问"
            fi
        fi
        ;;
        
    e)
        echo ""
        echo "重新设置public仓库..."
        echo "⚠️  这将删除public目录的所有内容！"
        read -p "确定要继续吗? (y/n): " confirm
        
        if [ "$confirm" = "y" ]; then
            read -p "请输入您的GitHub Pages仓库URL: " pages_repo_url
            
            # 删除并重新克隆
            rm -rf public/
            git clone "$pages_repo_url" public
            
            echo "✓ public仓库已重新设置"
            echo "现在可以重新构建和部署"
        fi
        ;;
        
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo ""
echo "=== 测试完成 ==="
#!/bin/bash

echo "=== URL路径问题测试脚本 ==="

# 备份原始配置
echo "1. 备份原始配置..."
cp config/_default/hugo.toml config/_default/hugo.toml.backup
echo "✓ 原始配置已备份为 hugo.toml.backup"

# 显示当前baseURL
echo -e "\n2. 当前配置："
grep "baseURL" config/_default/hugo.toml

echo -e "\n选择测试模式："
echo "a. 测试相对路径（用于本地预览）"
echo "b. 测试localhost路径"
echo "c. 恢复生产路径"
echo "d. 对比所有版本"

read -p "输入选择 (a/b/c/d): " choice

case $choice in
    a)
        echo -e "\n使用相对路径进行测试..."
        # 修改为相对路径
        sed -i.tmp 's|baseURL = "https://boyi-wang.com/"|baseURL = "/"|' config/_default/hugo.toml
        echo "✓ baseURL已改为相对路径"
        
        # 构建
        echo "构建网站..."
        rm -rf public/ resources/
        hugo --minify
        
        if [ $? -eq 0 ]; then
            echo "✓ 构建成功"
            
            # 检查生成的URL
            echo -e "\n检查生成的CSS链接："
            grep -o 'href="[^"]*\.css[^"]*"' public/index.html | head -2
            
            echo -e "\n检查生成的JS链接："
            grep -o 'src="[^"]*\.js[^"]*"' public/index.html | head -2
            
            echo -e "\n检查图片链接："
            grep -o 'src="[^"]*\(jpg\|png\|webp\)[^"]*"' public/index.html | head -2
            
            echo -e "\n现在可以测试："
            echo "1. 直接打开：open public/index.html"
            echo "2. 本地服务器：cd public && python3 -m http.server 8080"
            
            read -p "是否启动本地服务器测试？(y/n): " start_server
            if [ "$start_server" = "y" ]; then
                echo "启动本地服务器..."
                cd public
                echo "预览地址：http://localhost:8080"
                python3 -m http.server 8080
            fi
        else
            echo "✗ 构建失败"
        fi
        ;;
        
    b)
        echo -e "\n使用localhost路径进行测试..."
        # 修改为localhost路径
        sed -i.tmp 's|baseURL = "https://boyi-wang.com/"|baseURL = "http://localhost:8080/"|' config/_default/hugo.toml
        echo "✓ baseURL已改为localhost路径"
        
        # 构建
        echo "构建网站..."
        rm -rf public/ resources/
        hugo --minify
        
        if [ $? -eq 0 ]; then
            echo "✓ 构建成功"
            
            # 检查生成的URL
            echo -e "\n检查生成的CSS链接："
            grep -o 'href="[^"]*\.css[^"]*"' public/index.html | head -2
            
            echo -e "\n启动服务器..."
            cd public
            echo "预览地址：http://localhost:8080"
            echo "所有资源链接都指向localhost:8080，应该能正常显示"
            python3 -m http.server 8080
        else
            echo "✗ 构建失败"
        fi
        ;;
        
    c)
        echo -e "\n恢复生产环境配置..."
        # 恢复原始配置
        if [ -f "config/_default/hugo.toml.backup" ]; then
            cp config/_default/hugo.toml.backup config/_default/hugo.toml
            echo "✓ 已恢复原始配置"
            
            # 构建生产版本
            echo "构建生产版本..."
            rm -rf public/ resources/
            HUGO_ENV=production hugo --minify --gc
            
            if [ $? -eq 0 ]; then
                echo "✓ 生产版本构建成功"
                echo "检查生成的CSS链接："
                grep -o 'href="[^"]*\.css[^"]*"' public/index.html | head -2
                echo "✓ 已恢复为生产环境路径"
            fi
        else
            echo "✗ 找不到备份文件"
        fi
        ;;
        
    d)
        echo -e "\n对比不同baseURL的效果..."
        
        # 创建测试目录
        mkdir -p url_test
        
        # 测试1：相对路径
        echo "测试1：相对路径"
        sed 's|baseURL = "https://boyi-wang.com/"|baseURL = "/"|' config/_default/hugo.toml > config/_default/hugo_relative.toml
        hugo --config config/_default/hugo_relative.toml --destination url_test/relative
        echo "相对路径CSS链接："
        grep -o 'href="[^"]*\.css[^"]*"' url_test/relative/index.html | head -1
        
        # 测试2：localhost路径
        echo -e "\n测试2：localhost路径"
        sed 's|baseURL = "https://boyi-wang.com/"|baseURL = "http://localhost:8080/"|' config/_default/hugo.toml > config/_default/hugo_localhost.toml
        hugo --config config/_default/hugo_localhost.toml --destination url_test/localhost
        echo "localhost路径CSS链接："
        grep -o 'href="[^"]*\.css[^"]*"' url_test/localhost/index.html | head -1
        
        # 测试3：生产路径
        echo -e "\n测试3：生产路径"
        hugo --config config/_default/hugo.toml --destination url_test/production
        echo "生产路径CSS链接："
        grep -o 'href="[^"]*\.css[^"]*"' url_test/production/index.html | head -1
        
        echo -e "\n所有版本已生成在url_test/目录下"
        echo "可以分别测试每个版本"
        
        # 清理临时文件
        rm -f config/_default/hugo_relative.toml config/_default/hugo_localhost.toml
        ;;
        
    *)
        echo "无效选择"
        exit 1
        ;;
esac

echo -e "\n=== 测试完成 ==="
echo "记住测试后恢复生产配置！"
#!/bin/bash

echo "=== 设置Hugo Modules配置 ==="

# 清理现有配置和主题
rm -rf themes/ config/ hugo.toml

# 初始化模块
echo "初始化Hugo模块..."
hugo mod init github.com/yourusername/boyi-site

# 创建配置目录
mkdir -p config/_default

# 创建使用模块的hugo.toml
cat > config/_default/hugo.toml << 'EOF'
baseURL = "https://boyi-wang.com/"
languageCode = "en-us"
title = "BOYI WANG"

# 不需要theme行，使用模块代替

[module]
  [[module.imports]]
    path = "github.com/jpanther/congo/v2"

[pagination]
  pagerSize = 20

[outputs]
  home = ["HTML", "RSS", "JSON"]

[taxonomies]
  author = "authors"
EOF

# 创建module.toml（模块特定配置）
cat > config/_default/module.toml << 'EOF'
[[imports]]
  path = "github.com/jpanther/congo/v2"
EOF

# 创建params.toml
cat > config/_default/params.toml << 'EOF'
colorScheme = "auto"
defaultAppearance = "light"

[homepage]
  layout = "profile"
  showRecent = false
  showRecentItems = 0

[article]
  showDate = true
  showAuthor = true
  showBreadcrumbs = false
  showReadingTime = true
  showTableOfContents = false
  showTaxonomies = false
  sharingLinks = false

[list]
  showBreadcrumbs = false
  showSummary = false
  showTableOfContents = false
  groupByYear = true
EOF

# 创建languages.en.toml
cat > config/_default/languages.en.toml << 'EOF'
title = "BOYI WANG"

[params]
  isoCode = "en"
  rtl = false
  dateFormat = "2 January 2006"

  [params.author]
    name = "BOYI WANG"
    image = "avatar.jpg"
    headline = "Postdoctoral researcher @ MPI-PKS"
    bio = "Postdoc @ MPI-PKS"
    links = [
      { google-scholar = "https://scholar.google.com/citations?user=04a2hB8AAAAJ&hl=zh-CN&authuser=1&oi=sra" },
      { ResearchGate = "https://www.researchgate.net/profile/Boyi-Wang-4"},
      { orcid = "https://orcid.org/0000-0003-1107-7591" },
      { email = "mailto:boyiw@pks.mpg.de" },
      { file-pdf = "/CV_WANG.pdf" }
    ]
EOF

# 创建menus.en.toml
cat > config/_default/menus.en.toml << 'EOF'
[[main]]
  identifier = "cv"
  name = "CV"
  pageRef = "/cv"
  weight = 10

[[main]]
  identifier = "publications"
  name = "Publications"
  pageRef = "/publications"
  weight = 30
EOF

# 创建markup.toml
cat > config/_default/markup.toml << 'EOF'
[goldmark]
  [goldmark.renderer]
    unsafe = true

[highlight]
  lineNos = false
  lineNumbersInTable = false
  noClasses = false

[tableOfContents]
  startLevel = 2
  endLevel = 4
EOF

# 确保内容文件存在
mkdir -p content
cat > content/_index.md << 'EOF'
---
title: "BOYI WANG"
draft: false
---
EOF

mkdir -p content/cv
cat > content/cv/index.md << 'EOF'
---
title: "CV"
draft: false
---

# Curriculum Vitae

[Download PDF](/CV_WANG.pdf)
EOF

mkdir -p content/publications
cat > content/publications/index.md << 'EOF'
---
title: "Publications"
draft: false
---

# Publications

My research publications will be listed here.
EOF

echo "配置文件已创建"

# 下载模块
echo "下载Congo主题模块..."
hugo mod get

# 检查模块状态
echo "模块信息："
hugo mod graph

# 构建网站
echo "构建网站..."
rm -rf public/ resources/
hugo --minify

if [ $? -eq 0 ]; then
    echo "✓ 构建成功！"
    
    if [ -f "public/index.html" ]; then
        echo "检查主页："
        if grep -q "congo\|profile" public/index.html; then
            echo "✓ Congo主题已正确应用"
        fi
        
        # 显示CSS链接
        echo "CSS文件："
        grep -o 'href="[^"]*\.css[^"]*"' public/index.html | head -3
    fi
else
    echo "构建失败，错误信息："
    hugo --minify
fi

echo "=== 完成 ==="
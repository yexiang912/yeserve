🚀 YeServe - Ubuntu 服务器一键部署工具集（yx原创）
<div align="center">
https://img.shields.io/badge/YeServe-Pro-blue?style=for-the-badge
https://img.shields.io/badge/%E7%89%88%E6%9C%AC-8.0_Pro-green?style=for-the-badge
https://img.shields.io/badge/%E7%B3%BB%E7%BB%9F-Ubuntu-orange?style=for-the-badge
https://img.shields.io/badge/%E5%8E%9F%E5%88%9B-yx-red?style=for-the-badge

让服务器部署更简单 | 专业级自动化工具集

https://img.shields.io/github/stars/yexiang912/yeserve?style=social
https://img.shields.io/github/downloads/yexiang912/yeserve/total?color=blue

</div>
📖 目录
🎯 项目简介

📦 三个核心脚本

🖥️ 界面特色

⚡ 快速开始

🔧 技术特点

📁 功能模块

🛠️ 使用指南

📞 联系支持

⚠️ 重要声明

🎯 项目简介
YeServe 是由 yx（改名字四亩）原创开发的一套专业级Ubuntu服务器自动化部署工具集。项目包含三个不同定位的GUI脚本，全部采用 dialog 工具创建美观的终端图形界面，让服务器部署变得简单直观。

✨ 核心优势
✅ 完全原创 - 所有代码、界面设计均为 yx 独立开发

✅ 图形界面 - 告别命令行，操作更直观

✅ 智能部署 - 自动检测环境，智能优化配置

✅ 专业稳定 - 经过严格测试，企业级可靠性

✅ 持续更新 - 定期维护，功能不断完善

📦 三个核心脚本
1. 基础版 - yeserve.sh
定位：快速入门，基础功能

bash
# 一键拉取运行（yx原创界面）
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh)"
适合人群：

新手用户

快速部署测试环境

基础服务器配置

核心功能：

基础系统优化

Docker环境安装

常用工具包

基础面板安装

2. GUI增强版 - serveui.sh
定位：完整功能，最佳体验

bash
# 一键拉取运行（yx原创完整UI）
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh)"
适合人群：

常规用户

生产环境部署

需要完整功能

核心功能：

完整图形界面

多面板支持（1Panel/宝塔/小皮/AMH）

开发环境部署

数据库安装

Web服务器配置

3. 专业版 - pro.sh
定位：高级功能，需要授权

bash
# 一键拉取运行（yx原创Pro版）
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/pro.sh)"
适合人群：

专业运维人员

企业级部署

需要高级功能

核心功能：

🔒 访问验证系统 - 专业授权机制

📊 服务监控 - 实时状态监控

🔄 自动恢复 - 服务异常自动恢复

🛡️ 安全加固 - 专业级安全配置

📈 性能优化 - 深度内核调优

🖥️ 界面特色（yx原创设计）
🎨 视觉设计
text
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║        Ubuntu 服务器部署脚本 Pro版 v8.0                 ║
║             专业服务器部署方案管理器                     ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
🌈 色彩方案
红色 - 错误提示、重要警告

绿色 - 成功状态、正常操作

黄色 - 警告信息、注意提示

蓝色 - 信息展示、普通内容

紫色 - 标题装饰、特殊功能

青色 - 分隔线、界面装饰

📱 界面组件
分层菜单系统 - 逻辑清晰的操作流程

状态显示区域 - 实时反馈操作状态

进度可视化 - 安装过程可视化展示

错误处理界面 - 友好的错误提示

确认对话框 - 防止误操作

日志查看器 - 详细操作记录

⚡ 快速开始
方式一：直接运行（推荐）
bash
# 选择你需要的版本直接运行

# 基础版：简洁快速
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh)"

# GUI版：功能完整
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh)"

# Pro版：专业功能（需密钥）
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/pro.sh)"
方式二：下载运行
bash
# 1. 下载脚本
wget https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh

# 2. 赋予执行权限
chmod +x serveui.sh

# 3. 运行脚本
sudo ./serveui.sh
方式三：Git Clone
bash
# 克隆整个仓库
git clone https://github.com/yexiang912/yeserve.git

# 进入目录
cd yeserve

# 运行脚本
sudo bash serveui.sh
🔧 技术特点（yx原创实现）
1. GUI框架设计
bash
# 基于 dialog 的自定义界面框架
dialog --backtitle "服务器专业部署工具" --title "主菜单" --menu "请选择操作" 20 60 10
特点：

统一的界面风格和操作逻辑

智能的终端状态恢复机制

响应式布局，适应不同终端

键盘快捷键支持

2. 智能部署系统
🔍 自动检测 - 系统版本、架构、网络状态

⚙️ 智能配置 - 根据环境自动优化参数

🛡️ 错误恢复 - 失败操作自动回滚

📝 日志记录 - 详细的操作日志和错误追踪

3. 模块化架构
text
yeserve/
├── 核心框架
│   ├── 界面引擎
│   ├── 日志系统
│   ├── 错误处理
│   └── 配置管理
├── 功能模块
│   ├── 系统优化
│   ├── 容器部署
│   ├── 面板管理
│   └── 服务监控
└── 工具模块
    ├── 网络检测
    ├── 磁盘检查
    ├── 权限验证
    └── 备份恢复
📁 功能模块
🛠️ 系统优化模块
软件包管理 - 更新、升级、清理

内核调优 - TCP优化、内存管理、网络参数

安全加固 - SSH配置、防火墙、用户权限

资源限制 - 文件描述符、进程限制

🐳 Docker环境
Docker CE - 最新版本安装

镜像加速 - 国内源自动配置

Compose - Docker编排工具

容器管理 - 启动、停止、监控

🎛️ 面板管理
1Panel - 现代化服务器管理面板

宝塔面板 - 国内流行面板

小皮面板 - PHP集成环境

AMH面板 - 轻量级面板

Websoft9 - 应用管理器

💻 开发环境
Node.js - JavaScript运行环境

Python - Python开发环境

Java - Java运行环境

PHP - PHP运行环境

数据库 - MySQL、PostgreSQL、Redis、MongoDB

🌐 Web服务器
Nginx - 高性能Web服务器

Apache - 稳定Web服务器

SSL配置 - HTTPS支持

虚拟主机 - 多站点管理

🔄 服务管理
状态监控 - 服务运行状态检查

快速启动 - 一键启动所有服务

自动恢复 - 服务异常自动重启

日志查看 - 系统和服务日志

🛠️ 使用指南
系统要求
✅ 操作系统: Ubuntu 18.04/20.04/22.04

✅ 内存: 至少 1GB RAM

✅ 磁盘: 至少 10GB 可用空间

✅ 网络: 稳定的互联网连接

✅ 权限: root 或 sudo 权限

安装步骤
准备环境

bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装必要工具
sudo apt install -y curl wget git
选择版本

新手 → serveui.sh（推荐）

测试 → yeserve.sh

专业 → pro.sh

运行脚本

bash
# 首次运行会有验证过程
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh)"
按需配置

选择需要安装的组件

配置系统参数

设置安全选项

常见问题
Q: 脚本运行失败怎么办？
A: 检查以下项目：

网络连接是否正常

系统是否为Ubuntu

是否有root权限

查看日志文件：/var/log/server-deploy-pro/

Q: 如何卸载安装的软件？
A: 使用脚本的卸载功能：

重新运行脚本

进入"卸载工具"菜单

选择需要卸载的组件

Q: 如何获取Pro版授权？
A: 联系作者获取授权密钥

📞 联系支持
作者信息
作者: yx (改名字四亩)

邮箱: 2064179125@qq.com

GitHub: yexiang912

项目地址: https://github.com/yexiang912/yeserve

支持方式
问题反馈: GitHub Issues

功能建议: 邮箱联系

紧急问题: 邮件优先

合作咨询: 邮件详谈

更新计划
更多面板支持

Kubernetes集成

备份恢复系统

监控报警功能

移动端管理

⚠️ 重要声明
版权声明
本项目所有代码、界面设计和功能实现均为 yx 原创作品，保留所有权利。

使用条款
允许：

个人学习使用

非商业项目部署

二次开发（需注明出处）

禁止：

商业用途（需授权）

冒名顶替声称原创

恶意修改和分发

免责声明
text
本人郑重声明：
1. 本工具仅供学习和合法用途
2. 使用者需对部署操作负责
3. 作者不对数据丢失承担责任
4. 生产环境请先测试验证

改名说自己做的死全家
原创标识

# 所有脚本均包含原创标识
SCRIPT_NAME="server-deploy-pro"
SCRIPT_VERSION="8.0-Pro"
AUTHOR="yx (改名字四亩)"
🌟 Star History
如果这个项目对您有帮助，请给一个 ⭐️ 支持！



<div align="center">
感谢使用 YeServe！ 🚀

让服务器部署更简单


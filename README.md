# 🚀 YeServe - Ubuntu 服务器一键部署工具集 v9.0（yx原创）

<div align="center">

![YeServe Logo](https://img.shields.io/badge/YeServe-专业部署-blue?style=for-the-badge)
![版本](https://img.shields.io/badge/版本-v9.0_Pro-green?style=for-the-badge)
![系统](https://img.shields.io/badge/系统-Ubuntu-orange?style=for-the-badge)
![原创](https://img.shields.io/badge/原创-yx-red?style=for-the-badge)

**让服务器部署更简单 | 专业级自动化工具集**

[![GitHub stars](https://img.shields.io/github/stars/yexiang912/yeserve?style=social)](https://github.com/yexiang912/yeserve)
[![下载量](https://img.shields.io/github/downloads/yexiang912/yeserve/total?color=blue)](https://github.com/yexiang912/yeserve)

</div>

---

## ⚠️ **重要安全提示**

**警告：脚本在生产级服务器上使用有一定风险！**

> 🚨 **风险提示**：如果您不熟悉此脚本的操作，请在**测试环境**中先进行验证，**不要直接在重要生产服务器上运行**。脚本会修改系统配置、安装软件、调整防火墙等操作。

**安全建议：**
1. **备份重要数据**：运行脚本前请备份所有重要数据
2. **测试环境验证**：先在虚拟机或测试服务器上测试
3. **了解操作内容**：阅读脚本功能说明，了解会执行的操作
4. **责任自负**：使用者需对自己的操作负责

---

## 🎯 v9.0 更新亮点

### ✨ 新增功能
- 🌍 **Pro版多语言支持** - 专业版新增中英文切换
- 🎛️ **Pro版更多面板** - 专业版支持更多面板选项
- 🛠️ **Pro版更多工具** - 专业版扩展运维工具集合
- 🌐 **网站部署示例** - 111.229.143.188:51854示例网站

---

## 📦 三个核心脚本

### 1. **基础版 - `yeserve.sh`** ✅ **无风险版本**
**定位：快速入门，基础功能 - 适合新手**

```bash
# 一键拉取运行（yx原创界面）
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh)"
```

**核心功能（安全基础功能）：**
- 基础系统优化
- Docker环境部署
- 基本运维工具
- 1Panel面板安装
- 宝塔面板安装

**风险等级：低** - 仅安装基础软件，不进行深度系统修改

---

### 2. **GUI增强版 - `serveui.sh`** ⚠️ **有一定风险**
**定位：完整功能，最佳体验 - 适合熟悉Linux的用户**

```bash
# 一键拉取运行（yx原创完整UI）
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh)"
```

**核心功能（风险提示：会修改系统配置）：**
- 🐳 **Docker容器引擎** - 完整Docker环境
- 🎛️ **面板管理** - 1Panel面板、宝塔面板
- ⚙️ **系统优化** - 内核优化、防火墙配置
- 🔧 **基础运维** - 常用工具安装

**⚠️ 注意：**
- 仅包含 Docker、1Panel、宝塔面板
- **不包含**：小皮面板、AMH、Websoft9、多语言等高级功能
- 会修改系统配置和防火墙规则

---

### 3. **专业版 - `servepro.sh`** 🔴 **高风险 - 需要授权**
**定位：高级功能，企业级 - 仅适合专业用户**

```bash
# 拉取运行双语言高级版（需要授权密钥）
sudo wget -O /tmp/servepro.sh https://raw.githubusercontent.com/yexiang912/yeserve/main/servepro.sh
sudo chmod +x /tmp/servepro.sh
sudo /tmp/servepro.sh
```

**专业版独有功能（风险较高）：**
- 🌍 **多语言支持** - 中英文专业界面
- 🎛️ **更多面板** - 小皮面板、AMH面板、Websoft9等
- 🛠️ **更多工具** - 扩展运维工具集合
- 🔒 **访问验证** - 专业授权机制
- 📊 **服务监控** - 实时状态监控
- 🛡️ **安全加固** - 深度安全配置
- 💻 **开发环境** - Node.js/Python/Java/PHP
- 🗄️ **数据库** - MySQL/PostgreSQL/Redis/MongoDB
- 🌍 **Web服务器** - Nginx/Apache

**🔴 风险警告：**
- 会深度修改系统配置
- 安装大量软件和服务
- 调整内核参数和安全设置
- **仅推荐在熟悉的环境中使用**

---

## ⚡ 快速使用指南

### 新手用户（推荐）
```bash
# 使用基础版 - 无风险，功能简单
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh)"
```

### 熟悉Linux的用户
```bash
# 使用GUI增强版 - 功能完整，有一定风险
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/serveui.sh)"
```

### 专业用户（需要授权）
```bash
# 使用专业版 - 功能全面，高风险
# 需要联系作者获取授权密钥
```

---

## 🎛️ 各版本功能对比

| 功能模块 | 基础版 (yeserve.sh) | GUI增强版 (serveui.sh) | 专业版 (servepro.sh) |
|---------|-------------------|----------------------|---------------------|
| **风险等级** | ✅ 低风险 | ⚠️ 中等风险 | 🔴 高风险 |
| **Docker支持** | ✅ 有 | ✅ 有 | ✅ 有 |
| **1Panel面板** | ✅ 有 | ✅ 有 | ✅ 有 |
| **宝塔面板** | ✅ 有 | ✅ 有 | ✅ 有 |
| **小皮面板** | ❌ 无 | ❌ 无 | ✅ 有 |
| **AMH面板** | ❌ 无 | ❌ 无 | ✅ 有 |
| **Websoft9** | ❌ 无 | ❌ 无 | ✅ 有 |
| **多语言支持** | ❌ 无 | ❌ 无 | ✅ 有 |
| **开发环境** | ❌ 无 | ❌ 无 | ✅ 有 |
| **数据库** | ❌ 无 | ❌ 无 | ✅ 有 |
| **Web服务器** | ❌ 无 | ❌ 无 | ✅ 有 |
| **监控工具** | ❌ 无 | ❌ 无 | ✅ 有 |
| **授权验证** | ❌ 无 | ❌ 无 | ✅ 需要 |

---

## 🛠️ GUI增强版功能详解

### **主要功能（serveui.sh）**
1. **🐳 Docker容器引擎**
   - Docker CE完整安装
   - Docker Compose编排
   - 容器管理基础

2. **🎛️ 面板管理**
   - **1Panel面板**：现代化云原生面板
   - **宝塔面板**：国内流行全能面板
   - **仅此两种面板**，不包含其他面板

3. **⚙️ 系统优化**
   - 基础系统更新
   - 常用工具安装
   - 防火墙基础配置
   - SSH安全优化

4. **🔧 运维工具**
   - 基础监控工具
   - 网络诊断工具
   - 文件管理工具

### **⚠️ 重要限制**
- ❌ **不包含**：小皮面板、AMH面板、Websoft9
- ❌ **不包含**：多语言界面支持
- ❌ **不包含**：Node.js/Python/Java/PHP开发环境
- ❌ **不包含**：MySQL/PostgreSQL/Redis/MongoDB数据库
- ❌ **不包含**：Nginx/Apache Web服务器

这些高级功能仅在 **专业版 (servepro.sh)** 中提供

---

## 🌐 网站部署示例

### 示例地址（仅供演示）
```
http://111.229.143.188:51854
```

### 部署说明
- 该示例展示YeServe部署的网站效果
- 使用基础版或GUI版可部署类似网站
- 具体配置参数需要根据实际情况调整

---

## 🚨 风险控制建议

### 安全使用指南
1. **新手用户**
   ```bash
   # 仅使用基础版
   sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/yexiang912/yeserve/main/yeserve.sh)"
   ```

2. **测试环境验证**
   ```bash
   # 在虚拟机中测试
   # 确认功能符合预期后再在生产环境使用
   ```

3. **备份策略**
   ```bash
   # 运行脚本前备份重要数据
   sudo tar -czf backup_before_yeserve.tar.gz /etc/nginx /etc/mysql /var/www
   ```

4. **逐步部署**
   ```bash
   # 不要一次性安装所有功能
   # 先安装Docker，验证后再安装面板
   ```

### 紧急恢复
如果脚本运行出现问题：
```bash
# 1. 停止所有服务
sudo systemctl stop docker
sudo systemctl stop nginx
sudo systemctl stop mysql

# 2. 查看日志定位问题
sudo journalctl -xe
tail -f /var/log/syslog

# 3. 恢复备份
sudo tar -xzf backup_before_yeserve.tar.gz -C /
```

---

## 📞 技术支持

### 作者信息
- **作者**：yx (改名字四亩)
- **邮箱**：2064179125@qq.com
- **GitHub**：[https://github.com/yexiang912/yeserve](https://github.com/yexiang912/yeserve)

### 问题处理流程
1. **基础问题**：查看脚本运行日志
2. **功能问题**：检查版本功能限制
3. **紧急问题**：停止脚本运行，恢复备份
4. **专业支持**：专业版用户联系作者

### 版本历史
- **v9.0** - 明确风险提示，区分版本功能
- **v8.0** - 专业版发布，增加授权系统
- **v2.0** - GUI增强版发布
- **v1.0** - 基础版发布（无风险版本）

---

## ⚠️ 免责声明

### **重要声明**
```
使用本脚本即表示您同意以下条款：

1. 风险自担：您需对使用脚本产生的所有后果负责
2. 数据安全：运行前请备份所有重要数据
3. 测试先行：请在测试环境验证后再用于生产
4. 了解功能：确保了解脚本会执行的操作
5. 专业建议：如有疑问请咨询专业人士

作者不对以下情况负责：
- 数据丢失或损坏
- 系统崩溃或服务中断
- 安全漏洞或被攻击
- 业务损失或法律问题
```

### 责任划分
- ✅ **基础版**：低风险，适合新手，作者提供基础支持
- ⚠️ **GUI增强版**：中等风险，需要一定Linux知识
- 🔴 **专业版**：高风险，仅适合专业用户，需签署授权协议

---

<div align="center">

## 🎯 版本选择建议

### 根据经验水平选择：
- **Linux新手** → 使用 **基础版 (yeserve.sh)**
- **有一定经验** → 使用 **GUI增强版 (serveui.sh)**
- **专业运维** → 使用 **专业版 (servepro.sh)**（需授权）

---

## 🌟 支持原创

如果这个项目对您有帮助，请给项目点个 **Star** ⭐

**您的支持是我持续更新的动力！**

---

> **yx原创** - 让服务器部署更简单但更安全

**© 2024 yx (改名字四亩) 版权所有**

</div>

#!/bin/bash

# Jupyter MCP Server 完整清理脚本
# 作者: 根据用户配置定制
# 用途: 彻底移除Jupyter MCP Server及相关组件

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🗑️ Jupyter MCP Server 完整清理工具${NC}"
echo "========================================"
echo -e "${YELLOW}⚠️  警告: 此脚本将彻底移除Jupyter MCP Server及相关组件${NC}"
echo -e "${YELLOW}请确保已备份重要数据！${NC}"
echo ""

# 确认操作
read -p "确定要继续吗？(y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}操作已取消${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}开始清理过程...${NC}"

# 第一步：停止服务
echo -e "${YELLOW}📋 第一步: 停止所有运行的服务${NC}"

echo "停止MCP Server容器..."
docker stop $(docker ps -q --filter ancestor=datalayer/jupyter-mcp-server) 2>/dev/null || echo "没有运行中的MCP Server容器"
docker rm -f $(docker ps -aq --filter ancestor=datalayer/jupyter-mcp-server) 2>/dev/null || echo "没有MCP Server容器需要删除"

echo "停止Jupyter服务..."
systemctl --user stop jupyter 2>/dev/null || echo "Jupyter服务未运行"
systemctl --user disable jupyter 2>/dev/null || echo "Jupyter服务未启用"

# 第二步：移除Docker镜像
echo -e "${YELLOW}📋 第二步: 移除Docker镜像和资源${NC}"

echo "删除MCP Server镜像..."
docker rmi datalayer/jupyter-mcp-server:latest 2>/dev/null || echo "镜像不存在或已删除"

# 删除所有相关镜像
echo "删除所有相关镜像..."
docker images | grep jupyter-mcp-server | awk '{print $3}' | xargs -r docker rmi 2>/dev/null || echo "没有其他相关镜像"

echo "清理Docker资源..."
docker container prune -f 2>/dev/null
docker image prune -f 2>/dev/null
docker network prune -f 2>/dev/null
docker volume prune -f 2>/dev/null

# 第三步：移除systemd服务
echo -e "${YELLOW}📋 第三步: 移除systemd服务配置${NC}"

echo "删除服务文件..."
rm -f ~/.config/systemd/user/jupyter.service
systemctl --user daemon-reload 2>/dev/null
systemctl --user reset-failed 2>/dev/null

# 第四步：卸载Python包
echo -e "${YELLOW}📋 第四步: 卸载Python依赖包${NC}"

echo "激活conda环境..."
source /home/cpu/miniforge3/bin/activate 2>/dev/null || echo "无法激活conda环境"

echo "卸载MCP相关包..."
pip uninstall datalayer_pycrdt -y 2>/dev/null || echo "datalayer_pycrdt未安装"
conda remove jupyter-collaboration -y 2>/dev/null || echo "jupyter-collaboration未安装"

# 可选：重新安装标准pycrdt
read -p "是否重新安装标准pycrdt？(y/N): " install_pycrdt
if [[ $install_pycrdt =~ ^[Yy]$ ]]; then
    conda install pycrdt -c conda-forge -y 2>/dev/null || echo "安装pycrdt失败"
fi

# 第五步：清理配置文件
echo -e "${YELLOW}📋 第五步: 清理配置文件和数据${NC}"

echo "删除项目配置文件..."
rm -f claude_desktop_config.json
rm -f vscode_mcp_config.json
rm -f cursor_mcp_config.json
rm -f start_mcp_server.sh
rm -f DEPLOYMENT_GUIDE.md
rm -f QUICK_REFERENCE.md
rm -f notebook.ipynb

echo "删除测试notebook..."
rm -f /home/cpu/notebook.ipynb

# 可选：清理Jupyter配置
read -p "是否备份并清理Jupyter配置？(y/N): " clean_jupyter
if [[ $clean_jupyter =~ ^[Yy]$ ]]; then
    echo "备份Jupyter配置..."
    cp -r ~/.jupyter ~/.jupyter.backup.$(date +%Y%m%d) 2>/dev/null || echo "没有Jupyter配置需要备份"
    
    echo "清理Jupyter运行时目录..."
    rm -rf ~/.local/share/jupyter/runtime/* 2>/dev/null || echo "运行时目录已清空"
fi

# 第六步：验证清理结果
echo -e "${YELLOW}📋 第六步: 验证清理结果${NC}"

echo "检查残留进程..."
jupyter_processes=$(ps aux | grep jupyter | grep -v grep | wc -l)
if [ $jupyter_processes -eq 0 ]; then
    echo -e "${GREEN}✅ 没有残留的Jupyter进程${NC}"
else
    echo -e "${RED}⚠️  发现 $jupyter_processes 个Jupyter进程仍在运行${NC}"
fi

echo "检查Docker容器..."
docker_containers=$(docker ps -a | grep jupyter | wc -l)
if [ $docker_containers -eq 0 ]; then
    echo -e "${GREEN}✅ 没有残留的Docker容器${NC}"
else
    echo -e "${RED}⚠️  发现 $docker_containers 个相关Docker容器${NC}"
fi

echo "检查Docker镜像..."
docker_images=$(docker images | grep jupyter-mcp-server | wc -l)
if [ $docker_images -eq 0 ]; then
    echo -e "${GREEN}✅ 没有残留的Docker镜像${NC}"
else
    echo -e "${RED}⚠️  发现 $docker_images 个相关Docker镜像${NC}"
fi

echo "检查systemd服务..."
systemd_services=$(systemctl --user list-unit-files | grep jupyter | wc -l)
if [ $systemd_services -eq 0 ]; then
    echo -e "${GREEN}✅ 没有残留的systemd服务${NC}"
else
    echo -e "${RED}⚠️  发现 $systemd_services 个相关systemd服务${NC}"
fi

echo "检查端口占用..."
port_8888=$(netstat -tlnp 2>/dev/null | grep :8888 | wc -l)
port_4040=$(netstat -tlnp 2>/dev/null | grep :4040 | wc -l)
if [ $port_8888 -eq 0 ] && [ $port_4040 -eq 0 ]; then
    echo -e "${GREEN}✅ 端口8888和4040未被占用${NC}"
else
    echo -e "${RED}⚠️  端口仍被占用 (8888: $port_8888, 4040: $port_4040)${NC}"
fi

# 完成清理
echo ""
echo -e "${GREEN}🎉 清理完成！${NC}"
echo "========================================"
echo -e "${YELLOW}📝 后续手动操作提醒:${NC}"
echo "1. 检查并清理客户端配置文件中的MCP相关配置:"
echo "   - Claude Desktop: ~/.config/claude/claude_desktop_config.json"
echo "   - VS Code: ~/.vscode/settings.json 或 .vscode/mcp.json"
echo "   - Cursor: ~/.cursor/mcp.json"
echo ""
echo "2. 如果需要完全卸载Jupyter，请手动运行:"
echo "   conda remove jupyterlab jupyter jupyter_server ipykernel -y"
echo ""
echo "3. 如果将来需要重新安装，请参考COMPLETE_DEPLOYMENT_GUIDE.md"
echo ""
echo -e "${BLUE}感谢使用Jupyter MCP Server！${NC}"

#!/bin/bash

# Jupyter MCP Server 启动脚本
# 作者: 根据用户配置定制

set -e

# 配置变量
JUPYTER_TOKEN="ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359"
JUPYTER_URL="http://127.0.0.1:8888"
NOTEBOOK_PATH="notebook.ipynb"
MCP_PORT="4040"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 启动 Jupyter MCP Server${NC}"
echo "=================================="

# 检查Docker是否运行
if ! docker info >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker 未运行，请先启动 Docker${NC}"
    exit 1
fi

# 检查Jupyter服务是否运行
echo -e "${YELLOW}📋 检查 Jupyter 服务状态...${NC}"
if systemctl --user is-active --quiet jupyter; then
    echo -e "${GREEN}✅ Jupyter 服务正在运行${NC}"
else
    echo -e "${RED}❌ Jupyter 服务未运行，请先启动服务${NC}"
    echo "运行: systemctl --user start jupyter"
    exit 1
fi

# 验证Jupyter API访问
echo -e "${YELLOW}🔍 验证 Jupyter API 访问...${NC}"
if curl -s "${JUPYTER_URL}/api?token=${JUPYTER_TOKEN}" >/dev/null; then
    echo -e "${GREEN}✅ Jupyter API 访问正常${NC}"
else
    echo -e "${RED}❌ 无法访问 Jupyter API${NC}"
    exit 1
fi

# 检查notebook文件是否存在
if [ ! -f "/home/cpu/${NOTEBOOK_PATH}" ]; then
    echo -e "${YELLOW}⚠️  Notebook 文件不存在，创建示例文件...${NC}"
    cp notebook.ipynb "/home/cpu/${NOTEBOOK_PATH}"
fi

# 选择启动模式
echo -e "${BLUE}请选择启动模式:${NC}"
echo "1) stdio 模式 (适用于 Claude Desktop)"
echo "2) HTTP 模式 (适用于测试和远程访问)"
read -p "请输入选择 (1 或 2): " mode

case $mode in
    1)
        echo -e "${YELLOW}🔄 启动 stdio 模式...${NC}"
        docker run -i --rm \
          -e DOCUMENT_URL="${JUPYTER_URL}" \
          -e DOCUMENT_ID="${NOTEBOOK_PATH}" \
          -e DOCUMENT_TOKEN="${JUPYTER_TOKEN}" \
          -e RUNTIME_URL="${JUPYTER_URL}" \
          -e START_NEW_RUNTIME=true \
          -e RUNTIME_TOKEN="${JUPYTER_TOKEN}" \
          --network=host \
          datalayer/jupyter-mcp-server:latest
        ;;
    2)
        echo -e "${YELLOW}🔄 启动 HTTP 模式...${NC}"
        echo -e "${GREEN}📡 MCP Server 将在 http://localhost:${MCP_PORT} 启动${NC}"
        echo -e "${GREEN}🔗 健康检查: curl http://localhost:${MCP_PORT}/api/healthz${NC}"
        docker run -i --rm \
          -e DOCUMENT_URL="${JUPYTER_URL}" \
          -e DOCUMENT_ID="${NOTEBOOK_PATH}" \
          -e DOCUMENT_TOKEN="${JUPYTER_TOKEN}" \
          -e RUNTIME_URL="${JUPYTER_URL}" \
          -e START_NEW_RUNTIME=true \
          -e RUNTIME_TOKEN="${JUPYTER_TOKEN}" \
          --network=host \
          -p ${MCP_PORT}:${MCP_PORT} \
          datalayer/jupyter-mcp-server:latest \
          --transport streamable-http
        ;;
    *)
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
        ;;
esac

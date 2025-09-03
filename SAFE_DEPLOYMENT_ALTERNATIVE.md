# 🛡️ 安全的Jupyter MCP Server部署方案

## ⚠️ 包冲突问题分析

### 问题根源
- `jupyter-server-ydoc` 依赖标准的 `pycrdt`
- `jupyter-mcp-server` 需要 `datalayer_pycrdt`
- 两个包功能重叠，同时安装会导致冲突

### 当前风险
1. **功能异常**: Jupyter协作功能可能不稳定
2. **导入冲突**: 包导入时可能出现版本不匹配
3. **依赖破坏**: 可能影响其他依赖pycrdt的包

## 🔧 安全解决方案

### 方案一：独立虚拟环境（推荐）

#### 1. 创建专用环境
```bash
# 创建MCP专用环境
conda create -n jupyter-mcp python=3.12 -y

# 激活环境
conda activate jupyter-mcp

# 安装基础Jupyter组件
conda install jupyterlab=4.4.1 ipykernel -c conda-forge -y

# 安装MCP专用依赖
pip install datalayer_pycrdt==0.12.17
```

#### 2. 修改systemd服务
```ini
[Unit]
Description=Jupyter Notebook Server
After=network.target

[Service]
Type=simple
ExecStart=/home/cpu/miniforge3/bin/conda run -n jupyter-mcp jupyter notebook --no-browser --ip=127.0.0.1 --port=8889 --NotebookApp.token=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359
WorkingDirectory=/home/cpu
Restart=always
Environment="JUPYTER_CONFIG_DIR=/home/cpu/.jupyter"
Environment="JUPYTER_RUNTIME_DIR=/home/cpu/.local/share/jupyter/runtime"

[Install]
WantedBy=default.target
```

#### 3. 更新MCP Server配置
```bash
# 使用新端口8889
docker run -i --rm \
  -e DOCUMENT_URL=http://127.0.0.1:8889 \
  -e DOCUMENT_ID=notebook.ipynb \
  -e DOCUMENT_TOKEN=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359 \
  -e RUNTIME_URL=http://127.0.0.1:8889 \
  -e START_NEW_RUNTIME=true \
  -e RUNTIME_TOKEN=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359 \
  --network=host \
  datalayer/jupyter-mcp-server:latest
```

### 方案二：恢复标准配置

#### 1. 恢复标准pycrdt
```bash
# 激活base环境
source /home/cpu/miniforge3/bin/activate

# 卸载datalayer版本
pip uninstall datalayer_pycrdt -y

# 重新安装标准版本
conda install pycrdt -c conda-forge -y
```

#### 2. 测试Jupyter功能
```bash
# 测试导入
python -c "import pycrdt; print(f'pycrdt version: {pycrdt.__version__}')"

# 测试Jupyter协作
jupyter lab --version
```

#### 3. 使用Docker内置依赖
```bash
# 让MCP Server使用Docker内部的依赖，不依赖宿主机
docker run -i --rm \
  -e DOCUMENT_URL=http://host.docker.internal:8888 \
  -e DOCUMENT_ID=notebook.ipynb \
  -e DOCUMENT_TOKEN=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359 \
  -e RUNTIME_URL=http://host.docker.internal:8888 \
  -e START_NEW_RUNTIME=true \
  -e RUNTIME_TOKEN=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359 \
  datalayer/jupyter-mcp-server:latest
```

### 方案三：版本兼容性测试

#### 1. 检查当前状态
```bash
# 检查包依赖
pip check

# 测试Jupyter功能
python -c "
import jupyter_server_ydoc
import pycrdt
print('All imports successful')
print(f'pycrdt version: {pycrdt.__version__}')
"
```

#### 2. 功能验证脚本
```bash
#!/bin/bash
echo "测试Jupyter协作功能..."

# 启动临时Jupyter实例
jupyter lab --port=8899 --no-browser --ip=127.0.0.1 &
JUPYTER_PID=$!

sleep 5

# 测试API访问
if curl -s "http://127.0.0.1:8899/api" > /dev/null; then
    echo "✅ Jupyter API正常"
else
    echo "❌ Jupyter API异常"
fi

# 清理
kill $JUPYTER_PID
```

## 🎯 推荐方案

### 立即行动建议

1. **检查当前功能**：
```bash
# 测试当前Jupyter是否正常
systemctl --user status jupyter
curl "http://127.0.0.1:8888/api?token=ac87b951248e6cc6d5c58af49c043fe55412c3928f7df359"
```

2. **如果功能正常**：
   - 继续使用当前配置
   - 定期监控功能状态
   - 准备回滚方案

3. **如果出现问题**：
   - 立即使用方案二恢复标准配置
   - 或采用方案一的隔离环境

### 长期建议

1. **使用独立环境**：避免包冲突的最佳方案
2. **定期更新**：关注官方更新，解决兼容性问题
3. **功能监控**：定期测试Jupyter协作功能
4. **备份配置**：保存工作配置以便快速恢复

## 🚨 风险评估

### 低风险情况
- 只使用基本Jupyter功能
- 不需要实时协作
- 单用户环境

### 高风险情况
- 多用户协作环境
- 依赖Jupyter扩展
- 生产环境使用

## 🔄 回滚方案

如果出现问题，可以快速回滚：

```bash
# 停止服务
systemctl --user stop jupyter

# 恢复标准包
pip uninstall datalayer_pycrdt -y
conda install pycrdt -c conda-forge -y

# 重启服务
systemctl --user start jupyter
```

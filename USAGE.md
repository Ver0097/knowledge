# 使用指南

## 快速开始

### Windows系统

1. **配置DeepSeek API**（已自动配置，如需修改请编辑`.env`文件）
2. 双击运行 `start.bat` 脚本
3. 等待依赖安装完成（首次运行需要下载模型，可能需要几分钟）
4. 浏览器访问 http://localhost:8000

> **注意**：系统已自动配置DeepSeek API密钥。如果看到"✅ 已成功初始化DeepSeek API"提示，说明配置成功。

### Linux/Mac系统

1. 给脚本添加执行权限：
   ```bash
   chmod +x start.sh
   ```

2. 运行启动脚本：
   ```bash
   ./start.sh
   ```

3. 浏览器访问 http://localhost:8000

### 手动启动

如果自动脚本无法运行，可以手动执行：

```bash
# 1. 安装依赖
pip install -r requirements.txt

# 2. 启动服务
python app/main.py
# 或
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

## 使用流程

### 第一步：上传文档

1. 打开Web界面（http://localhost:8000）
2. 点击"选择文件"按钮或拖拽文件到上传区域
3. 支持的文件格式：
   - PDF (.pdf)
   - Word文档 (.docx)
   - 文本文件 (.txt)
4. 等待上传和处理完成（会显示切片数量）

### 第二步：提问

1. 在问答输入框中输入问题
2. 点击"提问"按钮或按 Enter 键
3. 系统会基于已上传的文档内容生成答案
4. 答案下方会显示参考来源

## 示例问题

- "文档的主要内容是什么？"
- "请总结一下文档的要点"
- "文档中提到了哪些关键概念？"
- "根据文档内容，XXX是什么？"

## API使用示例

### 使用curl上传文档

```bash
curl -X POST "http://localhost:8000/api/upload" \
  -F "file=@your_document.pdf" \
  -F "collection_name=default"
```

### 使用curl提问

```bash
curl -X POST "http://localhost:8000/api/ask" \
  -H "Content-Type: application/json" \
  -d '{
    "question": "文档的主要内容是什么？",
    "collection_name": "default"
  }'
```

### 使用Python请求

```python
import requests

# 上传文档
with open("document.pdf", "rb") as f:
    response = requests.post(
        "http://localhost:8000/api/upload",
        files={"file": f},
        data={"collection_name": "default"}
    )
print(response.json())

# 提问
response = requests.post(
    "http://localhost:8000/api/ask",
    json={
        "question": "文档的主要内容是什么？",
        "collection_name": "default"
    }
)
print(response.json())
```

## 注意事项

1. **首次运行**：首次运行需要下载嵌入模型（约400MB），请确保网络连接正常
2. **内存要求**：建议至少2GB可用内存
3. **文档大小**：建议单个文档不超过50MB
4. **处理时间**：大文档的处理可能需要几分钟，请耐心等待
5. **DeepSeek API**：系统已自动配置DeepSeek API，启动时会显示初始化状态
   - 如果看到"✅ 已成功初始化DeepSeek API"，说明配置成功
   - 如果看到"⚠️ 提示：未配置DEEPSEEK_API_KEY"，请检查`.env`文件或参考`CONFIG.md`
6. **API费用**：DeepSeek API按使用量计费，请查看[价格页面](https://platform.deepseek.com/pricing)

## 故障排除

### 问题1：模型下载失败

**解决方案**：
- 检查网络连接
- 使用VPN或代理
- 手动下载模型到本地

### 问题2：端口被占用

**解决方案**：
- 修改 `app/main.py` 中的端口号
- 或使用命令：`uvicorn app.main:app --port 8001`

### 问题3：导入错误

**解决方案**：
- 确保已安装所有依赖：`pip install -r requirements.txt`
- 检查Python版本（需要3.8+）

### 问题4：问答效果不佳

**解决方案**：
- 确保文档已正确上传和处理
- 尝试更具体的问题
- 检查文档内容是否与问题相关
- 考虑使用更强大的LLM模型

## 高级配置

### 更换嵌入模型

编辑 `app/services/document_service.py`：

```python
self.embeddings = HuggingFaceEmbeddings(
    model_name="your-preferred-model",
    model_kwargs={'device': 'cpu'}  # 或 'cuda'
)
```

### 调整切片大小

编辑 `app/services/document_service.py`：

```python
self.text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1000,    # 增大切片大小
    chunk_overlap=100,  # 增大重叠
)
```

### DeepSeek API配置

系统已集成DeepSeek API，配置方法：

**方式1：使用.env文件（推荐，已自动创建）**

项目根目录的`.env`文件已包含API密钥配置：
```env
DEEPSEEK_API_KEY=sk-103b2634aed4409a972a2754dba7e0f6
```

**方式2：修改模型类型**

如需使用思考模式，编辑 `app/services/qa_service.py`：

```python
self.llm = ChatOpenAI(
    model="deepseek-reasoner",  # 改为思考模式
    openai_api_key=deepseek_api_key,
    openai_api_base="https://api.deepseek.com",
    temperature=0.7,
)
```

**方式3：使用其他OpenAI兼容API**

DeepSeek API与OpenAI API完全兼容，可以替换为其他服务：

```python
self.llm = ChatOpenAI(
    model="gpt-3.5-turbo",
    openai_api_key="your-openai-key",
    # 不设置openai_api_base，使用默认OpenAI地址
)
```

# 智能知识库问答系统

基于 Python + LangChain + FastAPI + Chroma 的智能文档问答系统，支持文档上传、自动切片、向量化存储和智能问答功能。

## 📋 功能特性

- ✅ **文档上传**：支持 PDF、DOCX、TXT 格式文档上传
- ✅ **智能切片**：自动将文档切分为适合向量化的片段
- ✅ **向量化存储**：使用 Chroma 向量数据库存储文档向量
- ✅ **智能问答**：基于向量检索和 LLM 的智能问答
- ✅ **Web界面**：JSP 前端页面，友好的用户交互体验

## 🛠️ 技术栈

- **后端框架**：FastAPI
- **AI框架**：LangChain
- **向量数据库**：Chroma
- **嵌入模型**：BAAI/bge-small-zh-v1.5
- **LLM API**：DeepSeek API（与OpenAI API兼容，[文档](https://api-docs.deepseek.com/zh-cn/)）
- **文档处理**：PyPDF, python-docx
- **前端**：JSP + HTML + CSS + JavaScript

## 📦 安装步骤

### 1. 环境要求

- Python 3.8+
- pip
- DeepSeek API密钥（可选，用于智能问答，[获取地址](https://platform.deepseek.com/api_keys)）

### 2. 安装依赖

```bash
# 安装Python依赖
pip install -r requirements.txt
```

### 3. 配置DeepSeek API（已自动配置）

系统已集成DeepSeek API，用于生成更智能的答案。**API密钥已自动配置**，启动服务即可使用。

如需修改配置，请参考：[CONFIG.md](CONFIG.md)

> **注意**：如果未配置API密钥，系统会使用基于检索的简化问答模式（直接返回相关文档片段）。

### 4. 下载嵌入模型（首次运行会自动下载）

系统使用 `BAAI/bge-small-zh-v1.5` 模型，首次运行时会自动下载（约 100MB）。

### 5. 启动服务

```bash
# 方式1：使用模块方式运行（推荐）
python -m app.main

# 方式2：直接运行（已修复路径问题）
python app/main.py

# 方式3：使用uvicorn
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

服务启动后，访问：http://localhost:8000

## 🚀 使用说明

### 1. 上传文档

1. 在Web界面点击"选择文件"或拖拽文件到上传区域
2. 支持的文件格式：PDF、DOCX、TXT
3. 系统会自动进行文档切片和向量化处理
4. 处理完成后会显示切片数量

### 2. 智能问答

1. 在问答区域输入问题
2. 点击"提问"按钮或按 Enter 键
3. 系统会基于已上传的文档内容生成答案
4. 答案下方会显示参考来源

### 3. API接口

#### 上传文档
```bash
POST /api/upload
Content-Type: multipart/form-data

参数：
- file: 文件对象
- collection_name: 知识库集合名称（可选，默认：default）
```

#### 智能问答
```bash
POST /api/ask
Content-Type: application/json

请求体：
{
  "question": "你的问题",
  "collection_name": "default"
}

响应：
{
  "answer": "答案内容",
  "sources": ["来源1", "来源2"]
}
```

#### 获取集合列表
```bash
GET /api/collections
```

#### 删除集合
```bash
DELETE /api/collection/{collection_name}
```

## 📁 项目结构

```
langchain-demo/
├── app/
│   ├── __init__.py
│   ├── main.py                 # FastAPI主应用
│   └── services/
│       ├── __init__.py
│       ├── document_service.py # 文档处理服务
│       └── qa_service.py       # 问答服务
├── static/
│   └── index.jsp              # 前端页面
├── uploads/                   # 上传文件存储目录（自动创建）
├── chroma_db/                 # Chroma向量数据库存储目录（自动创建）
├── requirements.txt           # Python依赖
└── README.md                  # 项目说明文档
```

## ⚙️ 配置说明

### 文档切片参数

在 `app/services/document_service.py` 中可以调整切片参数：

```python
self.text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,      # 每个切片字符数
    chunk_overlap=50,    # 切片重叠字符数
)
```

### 嵌入模型

默认使用 BGE 中文模型，支持中英文。如需更换模型，修改 `document_service.py` 中的模型名称：

```python
self.embeddings = HuggingFaceEmbeddings(
    model_name="your-model-name",
    model_kwargs={'device': 'cpu'}  # 或 'cuda' 如果有GPU
)
```

### LLM配置

系统已集成 **DeepSeek API**（与OpenAI API兼容），配置简单：

1. **配置API密钥**（已在代码中配置，如需修改）：
   - 在项目根目录创建 `.env` 文件
   - 添加：`DEEPSEEK_API_KEY=your-api-key`
   - 或设置环境变量：`export DEEPSEEK_API_KEY=your-api-key`

2. **使用其他LLM**：
   - 修改 `app/services/qa_service.py` 中的LLM初始化代码
   - 支持所有与OpenAI API兼容的服务
   - 参考 [DeepSeek API文档](https://api-docs.deepseek.com/zh-cn/)

3. **模型选择**：
   - `deepseek-chat`：标准对话模式（默认）
   - `deepseek-reasoner`：思考模式，适合复杂推理

## 🔧 常见问题

### 1. 模型下载慢

首次运行需要下载嵌入模型，如果下载慢可以：
- 使用国内镜像源
- 手动下载模型到本地

### 2. 内存不足

如果处理大文档时内存不足：
- 减小 `chunk_size` 参数
- 使用更小的嵌入模型

### 3. 问答效果不佳

- 确保文档已正确上传和处理
- 尝试调整检索的文档片段数量（`search_kwargs={"k": 3}`）
- 使用更强大的LLM模型

## 📝 开发说明

### 添加新的文档格式支持

在 `document_service.py` 的 `load_document` 方法中添加新的加载器：

```python
elif file_ext == ".md":
    from langchain_community.document_loaders import UnstructuredMarkdownLoader
    loader = UnstructuredMarkdownLoader(file_path)
    documents = loader.load()
```

### 自定义提示词

在 `qa_service.py` 中修改 `prompt_template` 来自定义问答提示词。

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

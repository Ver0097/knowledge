"""
FastAPI主应用入口
提供文档上传、向量化存储和智能问答功能
"""
import sys
import os
from pathlib import Path

# 添加项目根目录到Python路径，确保可以导入app模块
project_root = Path(__file__).parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import uvicorn

from app.services.document_service import DocumentService
from app.services.qa_service import QAService

# 创建FastAPI应用实例
app = FastAPI(
    title="智能知识库问答系统",
    description="基于LangChain和Chroma的文档问答系统",
    version="1.0.0"
)

# 配置CORS，允许跨域请求（前端JSP页面需要）
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境应限制具体域名
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 静态文件目录（用于存放JSP页面）
app.mount("/static", StaticFiles(directory="static"), name="static")

# 初始化服务
document_service = DocumentService()
qa_service = QAService()


class QuestionRequest(BaseModel):
    """问答请求模型"""
    question: str
    collection_name: Optional[str] = "default"


class QuestionResponse(BaseModel):
    """问答响应模型"""
    answer: str
    sources: List[str]


@app.get("/", response_class=HTMLResponse)
async def root():
    """根路径，返回主页面"""
    try:
        # 使用绝对路径，确保能找到文件
        jsp_path = project_root / "static" / "index.jsp"
        
        if not jsp_path.exists():
            return HTMLResponse(content="<h1>页面文件未找到</h1><p>请确保static/index.jsp文件存在</p>", status_code=404)
        
        with open(jsp_path, "r", encoding="utf-8") as f:
            content = f.read()
            return HTMLResponse(content=content, status_code=200)
    except Exception as e:
        return HTMLResponse(content=f"<h1>加载页面出错</h1><p>{str(e)}</p>", status_code=500)


@app.post("/api/upload")
async def upload_document(
    file: UploadFile = File(...),
    collection_name: str = "default"
):
    """
    上传文档接口
    支持PDF、DOCX等格式，自动进行切片和向量化
    """
    try:
        # 检查文件类型
        allowed_extensions = [".pdf", ".docx", ".txt"]
        file_ext = os.path.splitext(file.filename)[1].lower()
        
        if file_ext not in allowed_extensions:
            raise HTTPException(
                status_code=400,
                detail=f"不支持的文件格式。支持格式：{', '.join(allowed_extensions)}"
            )
        
        # 保存上传的文件
        upload_dir = "uploads"
        os.makedirs(upload_dir, exist_ok=True)
        file_path = os.path.join(upload_dir, file.filename)
        
        with open(file_path, "wb") as f:
            content = await file.read()
            f.write(content)
        
        # 处理文档：切片和向量化
        result = await document_service.process_document(
            file_path=file_path,
            collection_name=collection_name
        )
        
        return JSONResponse(content={
            "message": "文档上传并处理成功",
            "filename": file.filename,
            "chunks_count": result["chunks_count"],
            "collection_name": collection_name
        })
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"处理文档时出错：{str(e)}")


@app.post("/api/ask", response_model=QuestionResponse)
async def ask_question(request: QuestionRequest):
    """
    智能问答接口
    基于向量数据库检索相关文档片段，生成答案
    """
    try:
        if not request.question or not request.question.strip():
            raise HTTPException(status_code=400, detail="问题不能为空")
        
        # 执行问答
        result = await qa_service.answer_question(
            question=request.question,
            collection_name=request.collection_name
        )
        
        return QuestionResponse(
            answer=result["answer"],
            sources=result["sources"]
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"问答处理出错：{str(e)}")


@app.get("/api/collections")
async def list_collections():
    """获取所有知识库集合列表"""
    try:
        collections = await document_service.list_collections()
        return JSONResponse(content={"collections": collections})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取集合列表出错：{str(e)}")


@app.get("/api/chunks/{collection_name}")
async def get_document_chunks(collection_name: str = "default", limit: int = 10, offset: int = 0):
    """
    获取指定集合的文档片段内容
    用于调试和查看已上传文档的具体内容
    """
    try:
        if limit > 50:  # 限制最大返回数量
            limit = 50
            
        chunks_data = document_service.get_document_chunks(
            collection_name=collection_name,
            limit=limit,
            offset=offset
        )
        
        return JSONResponse(content=chunks_data)
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取文档片段失败：{str(e)}")


@app.delete("/api/collection/{collection_name}")
async def delete_collection(collection_name: str):
    """删除指定的知识库集合"""
    try:
        await document_service.delete_collection(collection_name)
        return JSONResponse(content={"message": f"集合 {collection_name} 已删除"})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"删除集合出错：{str(e)}")


@app.get("/api/documents/{collection_name}")
async def get_documents_list(collection_name: str = "default"):
    """
    获取指定集合中的所有文档列表（按文件名分组）
    用于文档管理功能
    """
    try:
        documents_data = document_service.get_documents_list(collection_name=collection_name)
        return JSONResponse(content=documents_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"获取文档列表失败：{str(e)}")


if __name__ == "__main__":
    # 启动服务
    # 使用127.0.0.1确保本地访问，同时允许外部访问
    uvicorn.run(
        "app.main:app",
        host="127.0.0.1",  # 使用127.0.0.1确保本地访问
        port=8000,
        reload=False  # 关闭reload模式，避免连接问题
    )

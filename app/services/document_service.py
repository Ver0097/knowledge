"""
文档处理服务
负责文档上传、切片、向量化和存储到Chroma数据库
"""
import os
from typing import List, Dict
from pathlib import Path

from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader, TextLoader, Docx2txtLoader
# 导入Chroma - 优先使用新的langchain-chroma包
try:
    from langchain_chroma import Chroma  # type: ignore
except ImportError:
    # 如果新包不可用，则回退到旧版本
    from langchain_community.vectorstores import Chroma
try:
    from langchain_huggingface import HuggingFaceEmbeddings
except ImportError:
    # 兼容旧版本，如果langchain-huggingface未安装
    try:
        from langchain_community.embeddings import HuggingFaceEmbeddings
    except ImportError:
        raise ImportError("Please install langchain-huggingface: pip install langchain-huggingface")
from langchain_core.documents import Document


class DocumentService:
    """文档处理服务类"""
    
    def __init__(self):
        """初始化文档服务"""
        # 初始化嵌入模型（使用本地模型，无需API密钥）
        # 使用中文友好的多语言模型
        self.embeddings = HuggingFaceEmbeddings(
            model_name="BAAI/bge-small-zh-v1.5",
            model_kwargs={'device': 'cpu'}  # 如果有GPU可改为'cuda'
        )
        
        # 向量数据库存储路径
        self.persist_directory = "./chroma_db"
        os.makedirs(self.persist_directory, exist_ok=True)
        
        # 文本分割器配置
        self.text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=500,  # 每个切片500字符
            chunk_overlap=50,  # 切片之间重叠50字符，保持上下文连贯
            length_function=len,
        )
    
    def load_document(self, file_path: str) -> List[Document]:
        """
        根据文件类型加载文档
        
        Args:
            file_path: 文件路径
            
        Returns:
            Document对象列表
        """
        file_ext = Path(file_path).suffix.lower()
        
        try:
            if file_ext == ".pdf":
                # 加载PDF文档
                loader = PyPDFLoader(file_path)
                documents = loader.load()
            elif file_ext == ".docx":
                # 加载Word文档
                loader = Docx2txtLoader(file_path)
                documents = loader.load()
            elif file_ext == ".txt":
                # 加载文本文件
                loader = TextLoader(file_path, encoding="utf-8")
                documents = loader.load()
            else:
                raise ValueError(f"不支持的文件格式：{file_ext}")
            
            return documents
        
        except Exception as e:
            raise Exception(f"加载文档失败：{str(e)}")
    
    def split_documents(self, documents: List[Document]) -> List[Document]:
        """
        将文档切分成小块
        
        Args:
            documents: 原始文档列表
            
        Returns:
            切分后的文档块列表
        """
        try:
            # 使用递归字符文本分割器进行切片
            chunks = self.text_splitter.split_documents(documents)
            return chunks
        except Exception as e:
            raise Exception(f"文档切片失败：{str(e)}")
    
    async def process_document(
        self, 
        file_path: str, 
        collection_name: str = "default"
    ) -> Dict:
        """
        处理文档的完整流程：加载 -> 切片 -> 向量化 -> 存储
        
        Args:
            file_path: 文件路径
            collection_name: 向量数据库集合名称
            
        Returns:
            处理结果字典，包含切片数量等信息
        """
        try:
            # 1. 加载文档
            print(f"正在加载文档：{file_path}")
            documents = self.load_document(file_path)
            
            # 2. 文档切片
            print(f"正在切分文档，共 {len(documents)} 页...")
            chunks = self.split_documents(documents)
            print(f"文档已切分为 {len(chunks)} 个片段")
            
            # 3. 向量化并存储到Chroma
            print(f"正在向量化并存储到集合：{collection_name}")
            vectorstore = Chroma.from_documents(
                documents=chunks,
                embedding=self.embeddings,
                persist_directory=self.persist_directory,
                collection_name=collection_name
            )
            
            # 注意：Chroma 0.4.x以上版本会自动持久化，无需手动调用
            
            # 4. 清理临时文件（可选）
            # os.remove(file_path)
            
            return {
                "chunks_count": len(chunks),
                "collection_name": collection_name,
                "status": "success"
            }
        
        except Exception as e:
            raise Exception(f"处理文档失败：{str(e)}")
    
    async def list_collections(self) -> List[str]:
        """
        列出所有已创建的集合
        
        Returns:
            集合名称列表
        """
        try:
            # 获取Chroma客户端
            import chromadb
            client = chromadb.PersistentClient(path=self.persist_directory)
            collections = client.list_collections()
            return [col.name for col in collections]
        except Exception as e:
            raise Exception(f"获取集合列表失败：{str(e)}")
    
    async def delete_collection(self, collection_name: str):
        """
        删除指定的集合
        
        Args:
            collection_name: 要删除的集合名称
        """
        try:
            import chromadb
            client = chromadb.PersistentClient(path=self.persist_directory)
            client.delete_collection(collection_name)
        except Exception as e:
            raise Exception(f"删除集合失败：{str(e)}")
    
    def get_vectorstore(self, collection_name: str = "default"):
        """
        获取向量数据库实例
        
        Args:
            collection_name: 集合名称
            
        Returns:
            Chroma向量数据库实例
        """
        return Chroma(
            persist_directory=self.persist_directory,
            embedding_function=self.embeddings,
            collection_name=collection_name
        )

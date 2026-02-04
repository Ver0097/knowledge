"""
文档处理服务
负责文档上传、切片、向量化和存储到Chroma数据库
"""
import os
from typing import List, Dict
from pathlib import Path
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_community.document_loaders import PyPDFLoader, TextLoader, Docx2txtLoader
from transformers import AutoTokenizer
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
        # 延迟初始化嵌入模型和文本分割器，仅在需要时才加载
        self._embeddings = None
        self._text_splitter = None
        self._tokenizer = None
        
        # 从环境变量获取模型路径
        self.model_path = os.getenv('MODEL_PATH', 'BAAI/bge-small-zh-v1.5')
        
        # 设置离线模式和关闭分词器并行警告
        if os.getenv('HF_HUB_OFFLINE') == '1':
            os.environ['HF_HUB_OFFLINE'] = '1'
            os.environ['TRANSFORMERS_OFFLINE'] = '1'
        os.environ["TOKENIZERS_PARALLELISM"] = "false"
        
        # 向量数据库存储路径
        self.persist_directory = "./chroma_db"
        os.makedirs(self.persist_directory, exist_ok=True)
    
    @property
    def embeddings(self):
        """懒加载嵌入模型 - 使用本地模型路径"""
        if self._embeddings is None:
            print(f"正在从本地路径加载嵌入模型: {self.model_path}")
            
            # 检查模型路径是否存在
            if os.path.exists(self.model_path):
                # 使用本地模型路径
                self._embeddings = HuggingFaceEmbeddings(
                    model_name=self.model_path,
                    model_kwargs={'device': 'cpu'},  # 如果有GPU可改为'cuda'
                    encode_kwargs={'normalize_embeddings': True}  # 归一化嵌入向量
                )
                print("✓ 本地模型加载成功")
            else:
                # 回退到在线下载模式
                print(f"警告: 本地模型路径不存在 ({self.model_path})，将尝试从 Hugging Face 下载")
                self._embeddings = HuggingFaceEmbeddings(
                    model_name="BAAI/bge-small-zh-v1.5",
                    model_kwargs={'device': 'cpu'}
                )
        return self._embeddings
    
    @property
    def tokenizer(self):
        """懒加载 bge 原生分词器"""
        if self._tokenizer is None:
            print(f"正在加载 bge 分词器: {self.model_path}")
            try:
                if os.path.exists(self.model_path):
                    self._tokenizer = AutoTokenizer.from_pretrained(self.model_path)
                else:
                    print(f"警告: 本地模型路径不存在 ({self.model_path})，将尝试从 Hugging Face 下载")
                    self._tokenizer = AutoTokenizer.from_pretrained("BAAI/bge-small-zh-v1.5")
                print("✓ 分词器加载成功")
            except Exception as e:
                raise Exception(f"分词器加载失败：{str(e)}")
        return self._tokenizer
    
    def _bge_tokenizer(self, text: str) -> List[int]:
        """适配 bge-small-zh-v1.5 的 tokens 计算函数（与 LangChain 兼容）"""
        return self.tokenizer.encode(text, add_special_tokens=False)
    
    @property
    def text_splitter(self):
        """懒加载文本分割器 - 使用语义感知的递归字符切分"""
        if self._text_splitter is None:
            print("正在初始化语义感知文本分割器...")
            # RecursiveCharacterTextSplitter：按"强边界→弱边界"递归切分，完美适配中文
            self._text_splitter = RecursiveCharacterTextSplitter(
                # 自定义中文语义边界（优先级从高到低）
                separators=["\n\n", "\n", "。", "！", "？", "；", "，", "、"],  # 空行→换行→句末标点→停顿标点
                chunk_size=480,           # 单块最大 tokens（适配 bge，预留冗余）
                chunk_overlap=80,         # 重叠窗口（16.7%，符合 10%-20% 建议值）
                # 使用 bge 原生分词器计算长度，保证与模型编码一致
                length_function=lambda x: len(self._bge_tokenizer(x)),
            )
            print("✓ 语义感知文本分割器初始化成功 (chunk_size=480, overlap=80)")
        return self._text_splitter
    
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
            
            # 3. 向量化并存储到Chroma（追加模式）
            print(f"正在向量化并存储到集合：{collection_name}")
            vectorstore = Chroma.from_documents(
                documents=chunks,
                embedding=self.embeddings,
                persist_directory=self.persist_directory,
                collection_name=collection_name
            )
            
            # 注意：Chroma 0.4.x以上版本会自动持久化，无需手动调用
            
            # 4. 验证存储的实际数量
            try:
                import chromadb
                client = chromadb.PersistentClient(path=self.persist_directory)
                collection = client.get_collection(collection_name)
                actual_count = collection.count()
                print(f"✓ 实际存储片段数：{actual_count}")
            except Exception as e:
                print(f"警告：无法验证实际数量：{str(e)}")
                actual_count = len(chunks)
            
            # 5. 清理临时文件（可选）
            # os.remove(file_path)
            
            return {
                "chunks_count": actual_count,  # 返回实际存储的数量
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
    
    def get_document_chunks(self, collection_name: str = "default", limit: int = 10, offset: int = 0):
        """
        获取指定集合中的文档片段内容（用于调试和查看）
        
        Args:
            collection_name: 集合名称
            limit: 返回的片段数量限制
            offset: 偏移量，用于分页
            
        Returns:
            包含文档片段信息的字典列表
        """
        try:
            vectorstore = self.get_vectorstore(collection_name)
            
            # 获取集合中的所有文档
            # 注意：Chroma的get()方法返回格式可能因版本而异
            try:
                # 尝试获取文档内容
                collection_data = vectorstore.get()
                
                chunks = []
                documents = collection_data.get('documents', [])
                metadatas = collection_data.get('metadatas', [])
                ids = collection_data.get('ids', [])
                
                # 应用偏移量和限制
                start_idx = offset
                end_idx = min(offset + limit, len(documents))
                
                for i in range(start_idx, end_idx):
                    chunk_info = {
                        "id": ids[i] if i < len(ids) else str(i + 1),
                        "content": documents[i] if i < len(documents) else "",
                        "metadata": metadatas[i] if i < len(metadatas) else {},
                        "content_length": len(documents[i]) if i < len(documents) else 0,
                        # 添加文件名信息（如果存在）
                        "source": metadatas[i].get('source', '未知') if i < len(metadatas) else '未知'
                    }
                    chunks.append(chunk_info)
                
                return {
                    "collection_name": collection_name,
                    "total_chunks": len(documents),
                    "returned_chunks": len(chunks),
                    "chunks": chunks
                }
                
            except Exception as e:
                # 如果直接get()失败，尝试其他方式
                print(f"直接获取失败，尝试替代方法：{str(e)}")
                # 返回基本信息
                return {
                    "collection_name": collection_name,
                    "error": f"无法直接获取文档内容：{str(e)}",
                    "suggestion": "请使用问答接口查看相关内容"
                }
                
        except Exception as e:
            raise Exception(f"获取文档片段失败：{str(e)}")
    
    def get_documents_list(self, collection_name: str = "default") -> Dict:
        """
        获取集合中所有文档的列表（按文件名分组）
        
        Args:
            collection_name: 集合名称
            
        Returns:
            文档列表信息
        """
        try:
            vectorstore = self.get_vectorstore(collection_name)
            collection_data = vectorstore.get()
            
            metadatas = collection_data.get('metadatas', [])
            
            # 按文件名统计片段数
            documents_dict = {}
            for metadata in metadatas:
                source = metadata.get('source', '未知文档')
                if source in documents_dict:
                    documents_dict[source] += 1
                else:
                    documents_dict[source] = 1
            
            # 转换为列表格式
            documents_list = [
                {
                    "filename": filename,
                    "chunks_count": count,
                    "source_path": filename
                }
                for filename, count in documents_dict.items()
            ]
            
            return {
                "collection_name": collection_name,
                "total_documents": len(documents_list),
                "total_chunks": len(metadatas),
                "documents": documents_list
            }
            
        except Exception as e:
            raise Exception(f"获取文档列表失败：{str(e)}")

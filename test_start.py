"""
Test service startup
"""
import sys
import os

# Add project path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    print("Testing imports...")
    from fastapi import FastAPI
    print("[OK] FastAPI imported")
    
    from app.main import app
    print("[OK] App module imported")
    
    import uvicorn
    print("[OK] Uvicorn imported")
    
    print("\nAll dependencies check passed!")
    print("You can run: python app/main.py")
    print("Or run: start.bat")
    
except ImportError as e:
    print(f"[ERROR] Import failed: {e}")
    print("Please run: pip install -r requirements.txt")
    sys.exit(1)
except Exception as e:
    print(f"[ERROR] Error: {e}")
    sys.exit(1)

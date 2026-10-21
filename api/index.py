import os
import sys

# Add root directory to sys.path so main.py is importable
root_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if root_dir not in sys.path:
    sys.path.insert(0, root_dir)

from main import app

# Expose app and handler for Vercel
try:
    from mangum import Mangum
    handler = Mangum(app)
except Exception:
    handler = app

"""English entry point; shared extraction rules by Astrit."""
from pathlib import Path
import runpy
runpy.run_path(str(Path(__file__).resolve().parents[1] / "product_extract.py"), run_name="__main__")

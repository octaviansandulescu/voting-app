#!/usr/bin/env python3
"""
Script to remove diacritical marks from Romanian text in markdown files.
Conversions:
  ă → a
  ț → t
  ș → s
  ž → z
  î → i
  â → a
  Ă → A
  Ț → T
  Ș → S
  Ž → Z
  Î → I
  Â → A
"""

import os
import sys
from pathlib import Path

REPLACEMENTS = {
    'ă': 'a', 'Ă': 'A',
    'ț': 't', 'Ț': 'T',
    'ș': 's', 'Ș': 'S',
    'ž': 'z', 'Ž': 'Z',
    'î': 'i', 'Î': 'I',
    'â': 'a', 'Â': 'A',
}

def remove_diacritics(text):
    """Remove diacritical marks from text."""
    for old, new in REPLACEMENTS.items():
        text = text.replace(old, new)
    return text

def process_file(filepath):
    """Process a single markdown file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        content = remove_diacritics(content)
        
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ Fixed: {filepath}")
            return True
        else:
            print(f"✓ Clean: {filepath}")
            return False
    except Exception as e:
        print(f"❌ Error {filepath}: {e}")
        return False

def main():
    """Process all markdown files in docs/ directory."""
    docs_dir = Path("docs")
    if not docs_dir.exists():
        print("❌ docs/ directory not found")
        sys.exit(1)
    
    md_files = list(docs_dir.glob("**/*.md"))
    print(f"Found {len(md_files)} markdown files\n")
    
    fixed_count = 0
    for md_file in sorted(md_files):
        if process_file(md_file):
            fixed_count += 1
    
    print(f"\n✅ Done! Fixed {fixed_count} files")

if __name__ == "__main__":
    main()

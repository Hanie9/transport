#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
xelatex -interaction=nonstopmode main.tex
xelatex -interaction=nonstopmode main.tex
cp -f main.pdf "گزارش-سامانه-لجستیک.pdf"
echo "PDF: $(pwd)/main.pdf"

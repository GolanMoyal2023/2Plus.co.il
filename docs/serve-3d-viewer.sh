#!/bin/bash
# Start a local server so architecture-3d.html loads correctly (browsers block CDN when opening file://)
cd "$(dirname "$0")"
echo "Serving docs at http://localhost:3333"
echo "Open: http://localhost:3333/architecture-3d.html"
echo "Press Ctrl+C to stop the server."
echo ""
if command -v python3 &>/dev/null; then
  python3 -m http.server 3333
elif command -v python &>/dev/null; then
  python -m http.server 3333
else
  echo "Python not found. Install it or run: npx serve docs -p 3333"
  exit 1
fi

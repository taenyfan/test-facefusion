#!/bin/bash
# RunPod FaceFusion setup. Run after cloning:
#   cd / && git clone https://github.com/taenyfan/test-facefusion.git facefusion && bash /facefusion/setup.sh

cd /facefusion || { echo "/facefusion not found - clone the repo first"; exit 1; }

echo "=== 1/4 installing python packages (a few minutes) ==="
pip install -r requirements.txt && pip install onnxruntime-gpu==1.26.0 && pip install "tensorrt-cu12==10.*" \
  || { echo "!!! pip install failed - scroll up for the error"; exit 1; }

echo "=== 2/4 setting TensorRT library path ==="
TRT='export LD_LIBRARY_PATH=/usr/local/lib/python3.12/dist-packages/tensorrt_libs:$LD_LIBRARY_PATH'
grep -qF "$TRT" ~/.bashrc || echo "$TRT" >> ~/.bashrc
eval "$TRT"

echo "=== 3/4 rclone ==="
command -v rclone > /dev/null || curl -s https://rclone.org/install.sh | bash
if rclone listremotes | grep -q '^gdrive:'; then
  echo "gdrive already configured - skipping"
elif [ -n "$RCLONE_TOKEN" ]; then
  echo "using RCLONE_TOKEN from RunPod secret"
  rclone config create gdrive drive scope=drive token="$RCLONE_TOKEN" --non-interactive > /dev/null \
    && rclone lsd gdrive: > /dev/null && echo "gdrive OK" \
    || { echo "!!! RunPod secret token didn't work - make a new one on your Mac and update the secret"; rclone config delete gdrive; exit 1; }
else
  echo
  echo "On your MAC run:   rclone authorize \"drive\""
  echo "Sign in in the browser, then copy the {...} token it prints (the whole line, braces included)."
  echo
  read -r -p "Paste the token here and press Enter: " TOKEN
  rclone config create gdrive drive scope=drive token="$TOKEN" --non-interactive > /dev/null \
    && rclone lsd gdrive: > /dev/null && echo "gdrive OK" \
    || { echo "!!! token didn't work - run setup.sh again with a fresh token"; rclone config delete gdrive; exit 1; }
fi

echo "=== 4/4 pulling to-swap from Google Drive ==="
rclone copy gdrive:/to-swap /facefusion/to-swap -P --exclude "out_*" --exclude "*_h264.mov" \
  || { echo "!!! rclone copy failed"; exit 1; }

echo
echo "=== SETUP DONE ==="
ls /facefusion/to-swap

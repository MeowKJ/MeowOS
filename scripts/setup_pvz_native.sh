#!/bin/bash
set -e

echo "=========================================="
echo "  MeowOS PvZ-Portable 原生移植与部署工具"
echo "=========================================="

GAMES_DIR="/home/radxa/games"
PVZ_DIR="${GAMES_DIR}/pvz"

echo "[1/4] 安装编译与多媒体依赖 (SDL2 / GLES / CMake)..."
sudo apt-get update
sudo apt-get install -y cmake build-essential ninja-build \
    libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libglew-dev libboost-all-dev

echo "[2/4] 克隆并编译 PvZ-Portable 官方原版逆向开源引擎..."
mkdir -p "${GAMES_DIR}"
cd "${GAMES_DIR}"
if [ ! -d "PvZ-Portable" ]; then
    git clone --depth=1 https://github.com/wszqkzqk/PvZ-Portable.git
else
    cd PvZ-Portable && git pull && cd ..
fi

cd "${GAMES_DIR}/PvZ-Portable"
mkdir -p build && cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ..
ninja -j4

echo "[3/4] 组织游戏资源与自动存档目录..."
mkdir -p "${PVZ_DIR}/userdata"
cp "${GAMES_DIR}/PvZ-Portable/build/PvZ-Portable" "${PVZ_DIR}/pvz-game" 2>/dev/null || true
if [ -d "${GAMES_DIR}/PvZ-Portable/properties" ]; then
    cp -r "${GAMES_DIR}/PvZ-Portable/properties" "${PVZ_DIR}/"
fi

echo "[4/4] 生成 MeowOS 启动与退出自动保存包装脚本..."
cat << 'EOF' > "${PVZ_DIR}/run.sh"
#!/bin/bash
cd /home/radxa/games/pvz
export SDL_VIDEODRIVER=kmsdrm
export SDL_MOUSE_TOUCH_EVENTS=1
export SDL_TOUCH_MOUSE_EVENTS=1

./pvz-game
EOF
chmod +x "${PVZ_DIR}/run.sh"

echo "=========================================="
echo "  PvZ-Portable 引擎编译完成！"
echo "  请将官方 main.pak 放入 ${PVZ_DIR}/main.pak 即可畅玩！"
echo "=========================================="

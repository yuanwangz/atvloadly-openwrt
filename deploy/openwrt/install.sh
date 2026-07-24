#!/bin/sh

set -eu

ATVLOADLY_ROOT=/opt/atvloadly
ATVLOADLY_DATA="$ATVLOADLY_ROOT/data"
ATVLOADLY_SOURCE="$(CDPATH= cd "$(dirname "$0")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
	echo "请使用 root 用户执行安装脚本。" >&2
	exit 1
fi

if [ ! -x "$ATVLOADLY_SOURCE/bin/atvloadly" ] || [ ! -x "$ATVLOADLY_SOURCE/bin/plumesign" ]; then
	echo "安装包不完整：缺少 atvloadly 或 plumesign 二进制文件。" >&2
	exit 1
fi

if [ -x /etc/init.d/atvloadly ]; then
	/etc/init.d/atvloadly stop || true
	/etc/init.d/atvloadly disable || true
fi

mkdir -p "$ATVLOADLY_ROOT/bin" "$ATVLOADLY_DATA/.config/PlumeImpactor" /tmp/atvloadly
chmod 700 "$ATVLOADLY_DATA"
cp "$ATVLOADLY_SOURCE/bin/atvloadly" "$ATVLOADLY_ROOT/bin/atvloadly"
cp "$ATVLOADLY_SOURCE/bin/plumesign" "$ATVLOADLY_ROOT/bin/plumesign"
chmod 755 "$ATVLOADLY_ROOT/bin/atvloadly" "$ATVLOADLY_ROOT/bin/plumesign"

if [ ! -f "$ATVLOADLY_ROOT/config.yaml" ]; then
	cp "$ATVLOADLY_SOURCE/config.yaml" "$ATVLOADLY_ROOT/config.yaml"
fi

# Author: XX. CoreADI libraries stay in persistent data; replace legacy temporary links before exposing them to plumesign.
PLUME_LIBRARY_LINK="$ATVLOADLY_DATA/.config/PlumeImpactor/lib"
PLUME_LIBRARY_PATH="$ATVLOADLY_DATA/PlumeImpactor/lib"
if [ -L "$PLUME_LIBRARY_LINK" ] && [ "$(readlink "$PLUME_LIBRARY_LINK")" != "$PLUME_LIBRARY_PATH" ]; then
	rm "$PLUME_LIBRARY_LINK"
fi
if [ ! -e "$PLUME_LIBRARY_LINK" ]; then
	ln -s "$PLUME_LIBRARY_PATH" "$PLUME_LIBRARY_LINK"
fi

cp "$ATVLOADLY_SOURCE/atvloadly.init" /etc/init.d/atvloadly
chmod 755 /etc/init.d/atvloadly
/etc/init.d/atvloadly enable
/etc/init.d/atvloadly start

echo "安装完成：请访问 http://路由器IP:15533"

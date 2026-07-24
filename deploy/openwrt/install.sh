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

# Author: XX. CoreADI libraries are written to the data directory and this link exposes the same persistent files to plumesign.
if [ ! -e "$ATVLOADLY_DATA/.config/PlumeImpactor/lib" ]; then
	ln -s "$ATVLOADLY_DATA/PlumeImpactor/lib" "$ATVLOADLY_DATA/.config/PlumeImpactor/lib"
fi

cp "$ATVLOADLY_SOURCE/atvloadly.init" /etc/init.d/atvloadly
chmod 755 /etc/init.d/atvloadly
/etc/init.d/atvloadly enable
/etc/init.d/atvloadly start

echo "安装完成：请访问 http://路由器IP:15533"

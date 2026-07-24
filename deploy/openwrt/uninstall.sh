#!/bin/sh

set -eu

if [ "$(id -u)" -ne 0 ]; then
	echo "请使用 root 用户执行卸载脚本。" >&2
	exit 1
fi

if [ -x /etc/init.d/atvloadly ]; then
	/etc/init.d/atvloadly stop || true
	/etc/init.d/atvloadly disable || true
	rm -f /etc/init.d/atvloadly
fi

# Author: XX. Remove only the fixed paths created by this package and leave all other router data untouched.
rm -rf /opt/atvloadly /tmp/atvloadly
echo "atvloadly 已卸载，配对信息与本地配置已删除。"

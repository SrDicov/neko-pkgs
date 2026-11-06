#!/bin/sh
#
# add-repo.sh <target>
#
# Configura los repositorios binarios de Neko (repo-neko) y z-repo para
# que xbps-src resuelva dependencias durante las pruebas de compilación.

set -e

target="${1:?falta el target (x86_64, x86_64-musl, i686...)}"

mkdir -p etc/xbps.d/custom etc/repo-keys

# 1. Repositorio Neko (repo-neko)
neko_url="https://github.com/Neko-Void-Linux/repo-neko/releases/download/stable"
printf 'repository=%s\n' "$neko_url" > etc/xbps.d/custom/10-neko.conf

neko_key="3a.23.f2.2d.5e.d1.ab.f5.3f.01.6f.a6.50.9f.15.64.plist"
neko_fp="3a:23:f2:2d:5e:d1:ab:f5:3f:01:6f:a6:50:9f:15:64"
curl -fsSL -o "etc/repo-keys/${neko_fp}.plist" "$neko_url/$neko_key" 2>/dev/null || true
echo "repo-neko: $neko_url configurado (clave $neko_fp)"

# 2. Repositorio z-repo (fallback / complementario)
case "$target" in
x86_64-musl) zrepo=https://github.com/SrDicov/z-repo-musl/releases/download/stable ;;
x86_64)      zrepo=https://github.com/SrDicov/z-repo/releases/download/stable ;;
*)           zrepo="" ;;
esac

if [ -n "$zrepo" ]; then
	printf 'repository=%s\n' "$zrepo" > etc/xbps.d/custom/20-zrepo.conf
	zkey=""
	for _ in 1 2 3; do
		if zkey=$(curl -fsSL https://github.com/SrDicov/z-repo/releases/expanded_assets/stable 2>/dev/null |
			grep -oE '[0-9a-f]{2}(\.[0-9a-f]{2}){15}\.plist' | head -1) && [ -n "$zkey" ]; then
			break
		fi
		sleep 2
	done
	if [ -n "$zkey" ]; then
		zfp=$(printf '%s' "${zkey%.plist}" | tr '.' ':')
		curl -fsSL -o "etc/repo-keys/$zfp.plist" \
			"https://github.com/SrDicov/z-repo/releases/download/stable/$zkey" 2>/dev/null || true
		echo "zrepo: $zrepo (clave $zfp)"
	fi
fi

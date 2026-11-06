#!/bin/bash
#
# build.sh

if [ ! -s /tmp/templates ]; then
	echo "No templates changed to build."
	exit 0
fi

if [ "$1" != "$2" ]; then
	arch="-a $2"
fi

if [ "$3" = 1 ]; then
	test="-Q"
fi

PKGS=$(./xbps-src $test sort-dependencies $(cat /tmp/templates) 2>/dev/null || cat /tmp/templates)

for pkg in ${PKGS}; do
	echo "Compilando paquete: $pkg ($arch $test)..."
	./xbps-src -j$(nproc) -s $arch $test pkg "$pkg"
	ret=$?
	if [ $ret -eq 2 ]; then
		echo "=> Omitiendo $pkg: no compatible con arquitectura $2 (código 2)"
		continue
	elif [ $ret -ne 0 ]; then
		echo "ERROR: Falló la compilación de $pkg con código $ret"
		exit 1
	fi
done

exit 0

SHELL:=/bin/bash

OGG_FILE="https://ftp.osuosl.org/pub/xiph/releases/ogg/libogg-1.3.5.tar.xz"
VORBIS_FILE="https://ftp.osuosl.org/pub/xiph/releases/vorbis/libvorbis-1.3.7.tar.xz"
PREFIX=`cd ../.. && pwd`/local
CFLAGS=-O3 --closure 1

src/js/decode.js: src/em/decode.c Makefile src/em/pre.js local/lib
	EMCC_CLOSURE_ARGS="--language_in ECMASCRIPT6 \
	--process_common_js_modules \
	--module_resolution=NODE \
	--js node_modules/setimmediate/setImmediate.js \
	--jscomp_off=checkVars \
	--js node_modules/setimmediate/package.json" \
	emsdk/upstream/emscripten/emcc -Ilocal/include src/em/decode.c -o src/js/oggmented-wasm.js \
	--pre-js src/em/pre.js ${CFLAGS} \
	-s MODULARIZE=1 \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s ENVIRONMENT=web \
	-s STRICT=1 \
	-s SINGLE_FILE=1 \
	-s EXPORTED_FUNCTIONS="[ \
		'_read_float', \
		'_open_buffer', \
		'_close_buffer', \
		'_get_length', \
		'_get_channels', \
		'_get_rate', \
		'_get_time', \
		'_get_streams' \
	]" \
	-s EXTRA_EXPORTED_RUNTIME_METHODS="['ccall', 'getValue']" \
	-llibvorbisfile -llibvorbis -llibogg -Llocal/lib

emsdk:
	git clone https://github.com/emscripten-core/emsdk.git

emsdk/upstream/emscripten: emsdk
	cd emsdk \
		&& git pull \
		&& ./emsdk install 1.39.10 \
		&& ./emsdk activate 1.39.10

build:
	mkdir build

local/lib: emsdk/upstream/emscripten build
	source emsdk/emsdk_env.sh
	curl -L ${OGG_FILE} | tar xJC build
	cd build/libogg* \
		&& ../../emsdk/upstream/emscripten/emconfigure ./configure --disable-shared --prefix=${PREFIX} \
		&& ../../emsdk/upstream/emscripten/emmake make install
	curl -L ${VORBIS_FILE} | tar xJC build
	cd build/libvorbis* \
		&& ../../emsdk/upstream/emscripten/emconfigure ./configure --disable-shared --prefix=${PREFIX} \
		&& ../../emsdk/upstream/emscripten/emmake make install

clean:
	rm -rf emsdk build local src/js/decode.js

	# -s EXPORT_ES6=1


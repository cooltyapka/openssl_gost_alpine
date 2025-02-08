ARG BASE=alpine:3.21
FROM ${BASE} AS builder

# Install build dependencies
RUN apk --no-cache --virtual .build-deps add \
    wget \
    perl \
		gcc \
		libc-dev \
		make \
		linux-headers \
    cmake \
    unzip \
	&& mkdir -p /usr/local/src

# Build and install OpenSSL
ARG OPENSSL_VERSION=1.1.1w
ARG OPENSSL_SHA256="cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8"
RUN cd /usr/local/src \
  && wget "https://github.com/openssl/openssl/releases/download/OpenSSL_${OPENSSL_VERSION//./_}/openssl-${OPENSSL_VERSION}.tar.gz" -O "openssl-${OPENSSL_VERSION}.tar.gz" \
  && echo "$OPENSSL_SHA256" "openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c - \
  && tar -zxvf "openssl-${OPENSSL_VERSION}.tar.gz" \
  && cd "openssl-${OPENSSL_VERSION}" \
  && ./config no-async shared --prefix=/usr/local/ssl --openssldir=/usr/local/ssl -Wl,-rpath,/usr/local/ssl/lib \
  && make && make install \
  && cp /usr/local/ssl/bin/openssl /usr/bin/openssl \
  && rm -rf "/usr/local/src/openssl-${OPENSSL_VERSION}.tar.gz" "/usr/local/src/openssl-${OPENSSL_VERSION}" \
  && cp /usr/local/ssl/openssl.cnf /usr/local/ssl/openssl.default.cnf

# Build GOST-engine for OpenSSL
ARG GOST_ENGINE_VERSION=1_1_1
ARG GOST_ENGINE_SHA256="f33ed1bc5bcdbe89b8b92ee9fbdceaf4de0f789f2dab42a1d3342f60f06ee1bb"
RUN cd /usr/local/src \
  && wget "https://github.com/gost-engine/engine/archive/refs/heads/openssl_${GOST_ENGINE_VERSION}.zip" -O gost-engine.zip \
  && echo "$GOST_ENGINE_SHA256" gost-engine.zip | sha256sum -c - \
  && unzip gost-engine.zip -d ./ \
  && cd "engine-openssl_${GOST_ENGINE_VERSION}" \
  && sed -i 's|printf("GOST engine already loaded\\n");|goto end;|' gost_eng.c \
  && sed -i "s/-Werror //g" CMakeLists.txt \
  && mkdir build \
  && cd build \
  && cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_FLAGS='-I/usr/local/ssl/include -L/usr/local/ssl/lib' \
   -DOPENSSL_ROOT_DIR=/usr/local/ssl  -DOPENSSL_INCLUDE_DIR=/usr/local/ssl/include -DOPENSSL_LIBRARIES=/usr/local/ssl/lib \
   -DOPENSSL_ENGINES_DIR=/usr/local/ssl/lib/engines-1.1 .. \
  && cmake --build . --config Release \
  && cd bin \
  && cp gostsum gost12sum /usr/local/bin \
  && cp gost.so /usr/local/ssl/lib/engines-1.1 \
  && rm -rf "/usr/local/src/gost-engine.zip" "/usr/local/src/engine-${GOST_ENGINE_VERSION}"

# Enable GOST-engine
COPY openssl.cnf /usr/local/ssl/

# Clean build dependencies
RUN apk del .build-deps

# Merge docker layers
FROM ${BASE}

COPY --from=builder / /
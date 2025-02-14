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
    git \
	&& mkdir -p /usr/local/src

# Build and install OpenSSL
ARG OPENSSL_VERSION=3.4.1
ARG OPENSSL_SHA256="002a2d6b30b58bf4bea46c43bdd96365aaf8daa6c428782aa4feee06da197df3"
RUN cd /usr/local/src \
  && wget "https://github.com/openssl/openssl/releases/download/openssl-${OPENSSL_VERSION}/openssl-${OPENSSL_VERSION}.tar.gz" -O "openssl-${OPENSSL_VERSION}.tar.gz" \
  && echo "$OPENSSL_SHA256" "openssl-${OPENSSL_VERSION}.tar.gz" | sha256sum -c - \
  && tar -zxvf "openssl-${OPENSSL_VERSION}.tar.gz" \
  && cd "openssl-${OPENSSL_VERSION}" \
  && ./Configure no-docs no-tests --prefix=/opt/openssl --openssldir=/usr/local/ssl -Wl,-rpath=/opt/openssl/lib64 \
  && make && make install \
  && cp /opt/openssl/bin/openssl /usr/local/bin \
  && rm -rf "/usr/local/src/openssl-${OPENSSL_VERSION}.tar.gz" "/usr/local/src/openssl-${OPENSSL_VERSION}"


# Build GOST engine
RUN cd /usr/local/src \
  && git clone https://github.com/gost-engine/engine \
  && cd engine \
  && git submodule update --init \
  && mkdir build \
  && cd build \
  && cmake -DOPENSSL_ENGINES_DIR=/opt/openssl/lib64/engines-3 -DCMAKE_INSTALL_PREFIX:PATH=/opt/openssl -DOPENSSL_ROOT_DIR=/opt/openssl -DCMAKE_BUILD_TYPE=Release .. \
  && cmake --build . --target install --config Release \
  && rm -rf /usr/local/src/engine

# Enable GOST engine
COPY openssl.cnf /usr/local/ssl/

# Clean build dependencies
RUN apk del .build-deps

# Merge docker layers
FROM ${BASE}

COPY --from=builder / /
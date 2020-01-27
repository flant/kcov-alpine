FROM alpine:3.11 as build

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/main >> /etc/apk/repositories && \
    echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
            alpine-sdk \
            argp-standalone \
            autoconf \
            automake \
            binutils-dev \
            bison \
            bsd-compat-headers \
            build-base \
            bzip2-dev \
            cmake \
            curl-dev \
            elfutils-dev \
            flex-dev \
            fts \
            fts-dev \
            g++ \
            gcc \
            su-exec \
            libtool \
            ninja \
            python \
            python3 \
            xz-dev \
            zlib-dev

ENV VERSION=37

RUN curl -L https://github.com/SimonKagstrom/kcov/archive/v$VERSION.tar.gz \
    | tar xzC $SRC_DIR/ && \
    mkdir kcov-$VERSION/build && \
    cd kcov-$VERSION/build && \
    CXXFLAGS="-D__ptrace_request=int" cmake -G Ninja .. && \
    ninja && \
    ninja install


# Build a small image containing just the obligatory parts.
FROM alpine:3.11
COPY --from=build /usr/local/bin/kcov /usr/bin/kcov
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/main elfutils-dev

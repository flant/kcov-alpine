FROM alpine:edge as build

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
            alpine-sdk \
            argp-standalone \
            autoconf \
            automake \
            binutils \
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
            musl-obstack \
            musl-obstack-dev \
            ninja \
            python \
            wget \
            xz-dev \
            zlib-dev

# abuild won't run as root, so we need to set up a user account.
RUN adduser abuild -G abuild; \
    su-exec abuild abuild-keygen -ai

ENV VERSION=36 SRC_DIR=/home/abuild PKG_DIR=/home/abuild/packages

COPY elfutils/* $SRC_DIR/elfutils/
COPY argp-standalone/* $SRC_DIR/argp-standalone/

# We need a version of argp-standalone compiled with -fPIC for buildign the
# full elfutils project.
WORKDIR $SRC_DIR/argp-standalone
RUN chown -R abuild: $SRC_DIR; \
    su-exec abuild abuild && \
    apk add $PKG_DIR/*/*/argp*.apk --allow-untrusted && \
    abuild-sign -k /home/abuild/.abuild/*.rsa $PKG_DIR/*/*/APKINDEX.tar.gz; \
    mv $PKG_DIR /home/abuild/argp

# The packaged version of elfutils does not include libdw which kcov links
# against, so we have to build a custom version.
WORKDIR $SRC_DIR/elfutils
RUN su-exec abuild abuild && \
    apk add $PKG_DIR/*/*/elf*.apk --allow-untrusted

WORKDIR $SRC_DIR
RUN wget https://github.com/SimonKagstrom/kcov/archive/v36.tar.gz; \
    tar xf v36.tar.gz

WORKDIR $SRC_DIR/kcov-36
RUN mkdir build && \
    cd build && \
    CXXFLAGS="-D__ptrace_request=int" cmake -G Ninja .. && \
    ninja && \
    ninja install


FROM alpine:edge
RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    apk update && \
    apk add --no-cache \
            binutils \
            curl \
            flex \
            fts \
            musl-obstack

COPY --from=build /home/abuild/argp/*/* /home/abuild/packages/*/* /home/
COPY --from=build /usr/local/bin/kcov /usr/bin/kcov

RUN apk add /home/*.apk --allow-untrusted

ENTRYPOINT ["/usr/bin/kcov"]

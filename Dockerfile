#Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

##Install Build Dependencies
RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y git clang zlib1g-dev libpng-dev libjpeg-dev libtiff-dev libgdk-pixbuf2.0-dev libxml2-dev sqlite3 libcairo2-dev libglib2.0-dev autoconf automake libtool pkg-config make cmake liblcms2-dev libz-dev libzstd-dev libwebp-dev libsqlite3-dev libopenjp2-tools libopenjp2-7-dev

# Install openjpeg
WORKDIR /
RUN git clone https://github.com/uclouvain/openjpeg.git
WORKDIR /openjpeg/build
RUN cmake .. -DCMAKE_BUILD_TYPE=Release
RUN make -j$(nproc)
RUN make install && make clean

##ADD source code to the build stage
WORKDIR /
ADD . /openslide
WORKDIR /openslide

##Build
RUN autoreconf -i
RUN ./configure CC="clang" CXX="clang++" BUILD_FUZZER=1
RUN make -j$(nproc)
RUN make install && ldconfig

FROM --platform=linux/amd64 ubuntu:20.04
RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y libstdc++6 lib32stdc++6 libstdc++6 lib32stdc++6 libstdc++6 libglib2.0-0 libglib2.0-dev libglib2.0-0 libglib2.0-dev libc6-i386 libc6 libc6-i386 libc6 libc6-i386 libc6 libgcc-s1 lib32gcc-s1 libc6 libc6-i386 libcairo2 libsqlite3-0 libxml2 libopenjp2-7 libtiff5 libpng16-16 libjpeg-turbo8 libgdk-pixbuf2.0-0 zlib1g libglib2.0-0 libmount1 libselinux1 libc6 libc6-i386 libffi7 libpcre3 libpixman-1-0 libfontconfig1 libfreetype6 libxcb-shm0 libxcb1 libxcb-render0 libxrender1 libx11-6 libxext6 libicu66 liblzma5 libwebp6 libzstd1 libjbig0 libblkid1 libpcre2-8-0 libexpat1 libuuid1 libxau6 libxdmcp6 libicu66 libbsd0
COPY --from=builder /openslide/test/.libs/fuzz_open /fuzz
COPY --from=builder /usr/local/lib/libopenslide.so.0 /usr/lib

CMD /fuzz


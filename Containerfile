# NOTE: Most of this is taken from upstream repo

FROM ubuntu:24.04 AS builder
LABEL org.opencontainers.image.authors="Christian Beiwinkel <chrstn@bwnkl.de>"

ARG CONCURRENCY
ARG ADDITIONAL_TARGETS
ARG VERSION_MODIFIER=""

# set paths
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32
RUN export DEBIAN_FRONTEND=noninteractive && apt update && apt install -y sudo

# install deps
WORKDIR /usr/local/src/
COPY ./valhalla/scripts/install-linux-deps.sh /usr/local/src/valhalla/scripts/install-linux-deps.sh
RUN bash /usr/local/src/valhalla/scripts/install-linux-deps.sh || true
RUN rm -rf /var/lib/apt/lists/*

# get the code into the right place and prepare to build it
ADD . .
RUN ls -la
RUN git submodule sync && git submodule update --init --recursive
RUN rm -rf valhalla/build && mkdir valhalla/build

# configure the build with symbols turned on so that crashes can be triaged
WORKDIR /usr/local/src/valhalla/build

RUN cmake .. -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_C_COMPILER=gcc -DENABLE_SINGLE_FILES_WERROR=Off -DENABLE_TESTS=On -DVALHALLA_VERSION_MODIFIER=${VERSION_MODIFIER}
RUN make all ${ADDITIONAL_TARGETS} -j${CONCURRENCY:-$(nproc)}
RUN make install
# manually copy test lib and headers
RUN cp ./test/libvalhalla_test.a /usr/local/lib/ && cp ../test/test.h /usr/local/include/valhalla && cp ../test/gurka/gurka.h /usr/local/include/valhalla

# we wont leave the source around but we'll drop the commit hash we'll also keep the locales
WORKDIR /usr/local/src
RUN cd valhalla && echo "https://github.com/valhalla/valhalla/tree/$(git rev-parse HEAD)" > ../valhalla_version
RUN for f in valhalla/locales/*.json; do cat ${f} | python3 -c 'import sys; import json; print(json.load(sys.stdin)["posix_locale"])'; done > valhalla_locales
RUN rm -rf valhalla

# the binaries are huge with all the symbols so we strip them but keep the debug there if we need it
#WORKDIR /usr/local/bin
#RUN for f in valhalla_*; do objcopy --only-keep-debug $f $f.debug; done
#RUN tar -cvf valhalla.debug.tar valhalla_*.debug && gzip -9 valhalla.debug.tar
#RUN rm -f valhalla_*.debug
#RUN strip --strip-debug --strip-unneeded valhalla_* || true
#RUN strip /usr/local/lib/libvalhalla.a
#RUN strip /usr/local/lib/python3.12/dist-packages/valhalla/_valhalla*.so

####################################################################
# copy the important stuff from the build stage to the runner image
FROM ubuntu:24.04 AS runner
LABEL org.opencontainers.image.authors="Christian Beiwinkel <chrstn@bwnkl.de>"

# basic paths
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:/lib/x86_64-linux-gnu:/usr/lib/x86_64-linux-gnu:/lib32:/usr/lib32
ENV PKG_CONFIG_PATH="/usr/local/lib/pkgconfig:${LD_LIBRARY_PATH}"

# github packaging niceties
LABEL org.opencontainers.image.description="Valhalla Development Environment"
LABEL org.opencontainers.image.source https://github.com/chrstnbwnkl/valhalla-gurka-container

# Install some dev packages and build tools for the downstream project
RUN export DEBIAN_FRONTEND=noninteractive && apt update && \
  apt install -y \
  cmake build-essential libcurl4-openssl-dev pkg_conf libczmq-dev libluajit-5.1-dev libgdal-dev \
  libprotobuf-dev libsqlite3-dev python3 libsqlite3-mod-spatialite libspatialite-dev libzmq3-dev zlib1g-dev locales && rm -rf /var/lib/apt/lists/*

# grab the builder stages artifacts
COPY --from=builder /usr/local /usr/local
COPY --from=builder /usr/local/lib/python3.12/dist-packages/valhalla/* /usr/local/lib/python3.12/dist-packages/valhalla/

RUN cat /usr/local/src/valhalla_locales | xargs -d '\n' -n1 locale-gen

# python smoke test
RUN python3 -c "import valhalla,sys; print(sys.version, valhalla)"

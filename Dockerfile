FROM centos:8
CMD /bin/bash

RUN useradd user
WORKDIR /app

RUN yum -y install epel-release

RUN yum -y install \
  autoconf \
  automake \
  binutils \
  gcc \
  gcc-c++ \
  git \
  glibc-devel \
  glibc-langpack-en \
  jq \
  libcurl-devel \
  libtool \
  make \
  perl-App-cpanminus \
  pkgconf \
  zlib-devel

# Common Perl development tools
RUN cpanm --notest App::cpm

# If we automatically use the latest release, then we
# won't get the benefit of cache invalidation.
# We should perhaps just specify the version we
# want; referencing the lastest will potentially
# break things across major updates too, assuming
# that libmaxminddb is using semantic versioning.

# MaxMind's libmaxminddb
# https://github.com/maxmind/libmaxminddb/releases
ARG libmaxminddb_version=1.4.3
RUN set -e -x; \
  git clone --recursive https://github.com/maxmind/libmaxminddb; \
  cd libmaxminddb/; \
  echo "using release ${libmaxminddb_version}"; \
  git checkout ${libmaxminddb_version}; \
  ./bootstrap; \
  ./configure; \
  make; \
  make check; \
  make install; \
  ldconfig

# MaxMind's Perl MMDB writer support etc.
# Specify --global so it doesn't go in /app,
# which we often overshadow with a bind mount.
COPY cpanfile /app
RUN cpm install --global --without-test

COPY app/ /app/
COPY input/ /input/
COPY output/ /output/
COPY test/ /test/

RUN cd /; /test/libs/bats/bin/bats -r /test/spec/

ENTRYPOINT ["/app/json-to-mmdb"]
USER user

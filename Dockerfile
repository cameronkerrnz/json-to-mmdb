FROM centos:8
CMD /bin/bash

WORKDIR /app
ADD . /app

RUN useradd user

RUN yum -y install epel-release

RUN yum -y install \
  autoconf automake binutils gcc gcc-c++ git glibc-devel glibc-langpack-en libtool make pkgconf \
  libcurl-devel zlib-devel \
  perl-App-cpanminus

# Common Perl development tools
RUN cpanm --notest App::cpm

# MaxMind's libmaxminddb
RUN set -e -x; \
  git clone --recursive https://github.com/maxmind/libmaxminddb; \
  cd libmaxminddb/; \
  latest_release=$(git tag --list | tail -1); \
  echo "using release ${latest_release}"; \
  git checkout ${latest_release}; \
  ./bootstrap; \
  ./configure; \
  make; \
  make check; \
  make install; \
  ldconfig

# MaxMind's Perl MMDB writer support etc.
# Specify --global so it doesn't go in /app,
# which we often overshadow with a bind mount.
#
RUN cpm install --global --without-test

ENTRYPOINT ["/app/json-to-mmdb"]
USER user

FROM centos:7

RUN yum update -y \
    && yum install -y \
       gcc make binutils llvm-toolset-7 \
       gcc-c++ zlib-devel \
       tar wget git\
    && rm -rf /var/cache/yum

WORKDIR /work
ARG JVMCI_URL=https://github.com/graalvm/openjdk8-jvmci-builder/releases/download/jvmci-20-b03/openjdk-8u212_1-jvmci-20-b03-linux-amd64.tar.gz
ENV PATH=/work/mx:$PATH \
    JAVA_HOME=/opt/jvmci
RUN mkdir $JAVA_HOME && wget -q $JVMCI_URL -O - | tar zxf - -C $JAVA_HOME --strip-components 1
RUN git clone --depth 1 https://github.com/oracle/graal
RUN git clone --depth 1 https://github.com/graalvm/mx
RUN cd graal/vm \
    && mx clean \
    && LIBGRAAL=true mx --disable-polyglot --disable-libpolyglot --dynamicimports /substratevm build

FROM oraclelinux:7-slim

# Note: If you are behind a web proxy, set the build variables for the build:
#       E.g.:  docker build --build-arg "https_proxy=..." --build-arg "http_proxy=..." --build-arg "no_proxy=..." ...

ENV LANG=en_US.UTF-8

ENV JAVA_HOME=/opt/graalvm-ce-master/ \
    PATH=$PATH:/opt/rh/llvm-toolset-7/root/usr/bin \
    LD_LIBRARY_PATH=/opt/rh/llvm-toolset-7/root/usr/lib64 \
    MANPATH=/opt/rh/llvm-toolset-7/root/usr/share/man \
    PKG_CONFIG_PATH=/opt/rh/llvm-toolset-7/root/usr/lib64/pkgconfig \
    PYTHONPATH=/opt/rh/llvm-toolset-7/root/usr/lib/python2.7/site-packages \
    X_SCLS=llvm-toolset-7

RUN yum update -y oraclelinux-release-el7 \
    && yum install -y oraclelinux-developer-release-el7 oracle-softwarecollection-release-el7 \
    && yum-config-manager --enable ol7_developer \
    && yum-config-manager --enable ol7_developer_EPEL \
    && yum-config-manager --enable ol7_optional_latest \
    && yum-config-manager --enable ol7_software_collections \
    && yum install -y bzip2-devel ed gcc gcc-c++ gcc-gfortran gzip file fontconfig less libcurl-devel make openssl openssl-devel readline-devel tar vi which xz-devel zlib-devel \
    && yum install -y glibc-static libcxx libcxx-devel llvm-toolset-7 zlib-static \
    && rm -rf /var/cache/yum

RUN fc-cache -f -v

ADD gu-wrapper.sh /usr/local/bin/gu

COPY --from=0 /work/graal/vm/latest_graalvm_home /opt/graalvm-ce-master

RUN set -eux \
    # Set alternative links
    && mkdir -p "/usr/java" \
    && ln -sfT "$JAVA_HOME" /usr/java/default \
    && ln -sfT "$JAVA_HOME" /usr/java/latest \
    && for bin in "$JAVA_HOME/bin/"*; do \
        base="$(basename "$bin")"; \
        [ ! -e "/usr/bin/$base" ]; \
        alternatives --install "/usr/bin/$base" "$base" "$bin" 20000; \
    done \
    && chmod +x /usr/local/bin/gu

CMD java -version
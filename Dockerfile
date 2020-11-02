FROM ubuntu:18.04
MAINTAINER mipu94 <tadinhsung@gmail.com>

RUN apt-get -y update && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y wget \
    cmake \
    bison \
    git \
    unzip \
    xz-utils \
    apache2 \
    llvm-7 \ 
    clang-7 \
    libclang-7-dev \
    tzdata

WORKDIR /root/

ARG WEBKIT_VERSION

# install clang
RUN wget https://prereleases.llvm.org/9.0.0/rc1/clang+llvm-9.0.0-rc1-x86_64-linux-gnu-ubuntu-18.04.tar.xz \
 && tar xvf clang+llvm-9.0.0-rc1-x86_64-linux-gnu-ubuntu-18.04.tar.xz \
 && mv clang+llvm-9.0.0-rc1-x86_64-linux-gnu-ubuntu-18.04 clang

# install woboq_codebrowser
RUN git clone https://github.com/woboq/woboq_codebrowser.git && \
    chmod +x woboq_codebrowser/scripts/fake_compiler.sh

RUN cd woboq_codebrowser && \
    export CC="/root/clang/bin/clang" && \
    export CXX="/root/clang/bin/clang++" && \
    cmake . -DCMAKE_BUILD_TYPE=Release && \
    make && make install

# download webkit
WORKDIR /root/
RUN wget https://webkitgtk.org/releases/webkitgtk-${WEBKIT_VERSION}.tar.xz && \
    tar xvf webkitgtk-${WEBKIT_VERSION}.tar.xz && \
    cd webkitgtk-${WEBKIT_VERSION} && \
    printf 'y\n' | ./Tools/gtk/install-dependencies

WORKDIR /root/webkitgtk-${WEBKIT_VERSION}

RUN  mkdir mybuild && cd mybuild && cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_SKIP_RPATH=ON       \
      -DPORT=GTK                  \
      -DLIB_INSTALL_DIR=/usr/lib  \
      -DUSE_LIBHYPHEN=OFF         \
      -DENABLE_MINIBROWSER=ON     \
      -DUSE_WOFF2=OFF             \
      -DUSE_WPE_RENDERER=OFF      \
      -DENABLE_BUBBLEWRAP_SANDBOX=OFF \
-Wno-dev -G Ninja -DCMAKE_C_COMPILER="/root/clang/bin/clang" -DCMAKE_CXX_COMPILER="/root/clang/bin/clang++" .. 


RUN cp mybuild/compile_commands.json .
ENV OUTPUT_DIRECTORY=/root/public_html/webkit
ENV DATA_DIRECTORY=/root/public_html/data
ENV BUILD_DIRECTORY=/root/webkitgtk-${WEBKIT_VERSION}
ENV SOURCE_DIRECTORY=/root/webkitgtk-${WEBKIT_VERSION}


RUN codebrowser_generator -b $BUILD_DIRECTORY -a -o $OUTPUT_DIRECTORY -p webkit:$SOURCE_DIRECTORY
RUN codebrowser_indexgenerator $OUTPUT_DIRECTORY
RUN cp -rv /root/woboq_codebrowser/data $DATA_DIRECTORY

RUN mv /root/public_html/* /var/www/html/ && \
    echo "ServerName localhost" >> /etc/apache2/apache2.conf

# clean
RUN rm -rf /root/woboq_codebrowser /root/clang /root/webkitgtk*

EXPOSE 80

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
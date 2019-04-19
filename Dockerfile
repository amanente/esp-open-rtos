FROM ubuntu:18.04

ENV DEBIAN_FRONTEND noninteractive

#Common deps
RUN apt-get update && apt-get -y install curl xz-utils wget gpg  gcc git wget make libncurses-dev flex bison gperf \
                                         python python-dev python-serial cmake ninja-build nano vim ccache picocom  unrar-free \ 
                                         autoconf automake libtool libtool-bin g++ texinfo gawk ncurses-dev libexpat-dev \
                                         sed  unzip bash help2man  bzip2 zlib1g-dev libncurses5-dev sudo


## User account
RUN adduser --disabled-password --gecos '' espuser && \
    adduser espuser sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;

RUN chmod g+rw /home && \
    mkdir -p /home/project && \
    chown -R espuser:espuser /home/espuser && \
    chown -R espuser:espuser /home/project;




#C/C++
# public LLVM PPA, development version of LLVM
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bionic/ llvm-toolchain-bionic main" > /etc/apt/sources.list.d/llvm.list && \
    apt-get update && apt-get install -y clang-tools-9 && \
    ln -s /usr/bin/clangd-9 /usr/bin/clangd


ENV ESP_TCHAIN_BASEDIR /opt/local/espressif

RUN mkdir -p $ESP_TCHAIN_BASEDIR \
    && wget -O $ESP_TCHAIN_BASEDIR/esp32-toolchain.tar.gz \
            https://dl.espressif.com/dl/xtensa-esp32-elf-linux64-1.22.0-80-g6c4433a-5.2.0.tar.gz \
    && tar -xzf $ESP_TCHAIN_BASEDIR/esp32-toolchain.tar.gz \
           -C $ESP_TCHAIN_BASEDIR/ \
    && rm $ESP_TCHAIN_BASEDIR/esp32-toolchain.tar.gz

RUN mkdir -p $ESP_TCHAIN_BASEDIR \
    && wget -O $ESP_TCHAIN_BASEDIR/esp32ulp-toolchain.tar.gz \
            https://dl.espressif.com/dl/esp32ulp-elf-binutils-linux64-d2ae637d.tar.gz \
    && tar -xzf $ESP_TCHAIN_BASEDIR/esp32ulp-toolchain.tar.gz \
           -C $ESP_TCHAIN_BASEDIR/ \
    && rm $ESP_TCHAIN_BASEDIR/esp32ulp-toolchain.tar.gz

# Setup IDF_PATH
ENV IDF_PATH /esp/esp-idf
RUN mkdir -p $IDF_PATH

ENV PATH $ESP_TCHAIN_BASEDIR/xtensa-esp32-elf/bin:$ESP_TCHAIN_BASEDIR/esp32ulp-elf-binutils/bin:$IDF_PATH/tools:$PATH

RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


ENV RTOS_PATH /esp/esp-open-rtos
RUN mkdir -p $RTOS_PATH 
RUN chown -R espuser:espuser $RTOS_PATH

ENV ESP_SDK_PATH /esp/esp-opensdk
RUN mkdir -p $ESP_SDK_PATH 
RUN chown -R espuser:espuser $ESP_SDK_PATH


USER espuser

WORKDIR $RTOS_PATH
RUN git clone --recursive https://github.com/Superhouse/esp-open-rtos.git .

WORKDIR $ESP_SDK_PATH 
RUN git clone --recursive https://github.com/pfalcon/esp-open-sdk.git .

RUN make STANDALONE=y

USER root 

ENV PATH $ESP_SDK_PATH/xtensa-lx106-elf/bin:$PATH

ENTRYPOINT [ "/bin/bash" ]



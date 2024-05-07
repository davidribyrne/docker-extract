FROM python:3.8-bookworm AS build-and-install
# There is a known problem with Python 3.12
# https://stackoverflow.com/questions/77274572/multiqc-modulenotfounderror-no-module-named-imp

# And another problem with Python 3.11
# AttributeError: module 'collections' has no attribute 'Callable'

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/src/app/bin \
    DEBIAN_FRONTEND=noninteractive

RUN set -xue
RUN sed -Ei -e 's/(Components: main)/\1 contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
RUN apt-get update -y
RUN apt-get upgrade -y --no-install-recommends
RUN apt-get install -y --no-install-recommends  \
    # From binwalk deps.sh:
    git locales build-essential qtbase5-dev mtd-utils gzip bzip2 tar \
    arj lhasa p7zip p7zip-full cabextract cramfsswap squashfs-tools \
    zlib1g-dev liblzma-dev liblzo2-dev sleuthkit default-jdk lzop \
    srecord cpio \
    # Required for extracting files or for installing other tools
    python3-poetry unrar lz4 liblz4-dev \
    # Required by unblob
    android-sdk-libsparse-utils lziprecover unar zstd \
    # For bulk_extractor
    flex libewf-dev libre2-dev libpcre3-dev \
    # For humans in a shell (bash-completion doesn't seem to work, need to fix)
    bash-completion vim less

RUN pip install --upgrade pip

RUN python3 -mpip install \
    # From binwalk deps.sh
    setuptools matplotlib capstone pycryptodome gnupg tk \
    # ubi_reader is now on pip, so there's no need to get the repo
    ubi_reader \
    # Unblob seems to be regularly updated on pip
    unblob

RUN git clone --depth 1 --branch "master" https://github.com/onekey-sec/e2fsprogs \
    && (cd e2fsprogs; mkdir build; cd build; \
        ../configure; make; make check; make install) \
    && rm -rf e2fsprogs

RUN git clone --depth 1 --branch "main" https://github.com/onekey-sec/sasquatch \
    && (cd sasquatch/squashfs-tools && make && make install) \
    && rm -rf sasquatch

RUN git clone --depth 1 --branch "master" https://github.com/devttys0/yaffshiv \
    && (cd yaffshiv && python3 setup.py install) \
    && rm -rf yaffshiv

RUN git clone --depth 1 --branch "master" https://github.com/sviehb/jefferson \
    && (cd jefferson && python3 -mpip install -r requirements.txt && python3 setup.py install) \
    && rm -rf jefferson

RUN TIME=`date +%s` \
    && INSTALL_LOCATION=/usr/local/bin \
    && git clone --depth 1 --branch "main" https://github.com/davidribyrne/cramfs \
    && (cd cramfs \
    && make \
    && install mkcramfs $INSTALL_LOCATION \
    && install cramfsck $INSTALL_LOCATION) \
    && rm -rf cramfs-tools


WORKDIR /tmp
RUN wget https://ftpmirror.gnu.org/parallel/parallel-latest.tar.bz2 \
    && tar -xf parallel-latest.tar.bz2 \
    && (cd parallel-20* \
        && ./configure \
        && make \
        && make install)


RUN git clone --depth 1 --recurse-submodules https://github.com/simsong/bulk_extractor.git \
    && (cd bulk_extractor \
        && ./bootstrap.sh \
        && ./configure \
        && make \
        && make install)


RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" >> /etc/default/locale \
    && echo "LANGUAGE=en_US:en" >> /etc/default/locale \
    && echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale \
    && locale-gen


RUN git clone https://github.com/ReFirmLabs/binwalk /tmp/binwalk
WORKDIR /tmp/binwalk
RUN python3 setup.py install && binwalk -h

RUN unblob --show-external-dependencies


# FROM build-and-install AS unit-tests
# RUN pip install coverage nose
# RUN python3 setup.py test \
#     && dd if=/dev/urandom of=/tmp/random.bin bs=1M count=1 && binwalk -J -E /tmp/random.bin


# Setup locale. According to binwalk, "this prevents Python 3 IO encoding issues."
ENV DEBIAN_FRONTEND=teletype \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PYTHONUTF8="1" \
    PYTHONHASHSEED="random"


RUN mkdir -p /data/input /data/output
RUN useradd -m -u 1000 -s /bin/bash extract
# COPY .bashrc /user/extract
RUN chown -R extract /data
WORKDIR /data
# Keep running as root
# USER extract


# FROM build-and-install AS cleanup-and-release
# RUN rm -rf -- \
#     /var/lib/apt/lists/* \
#     /tmp/binwalk/* /var/tmp/* \
#     /root/.cache/pip
# 
# RUN apt-get -yq purge *-dev git build-essential gcc g++ \
#     && apt-get -y autoremove \
#     && apt-get -y autoclean


ENTRYPOINT ["/bin/bash"]

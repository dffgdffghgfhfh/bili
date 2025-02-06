# Build biliup's web-ui
FROM node:lts as webui
ARG repo_url=https://github.com/biliup/biliup
ARG branch_name=master
RUN set -eux \
    && git clone --depth 1 --branch "$branch_name" "$repo_url" \
    && cd biliup \
    && npm install \
    && npm run build

# Deploy Biliup
FROM python:3.12-slim as biliup
ARG repo_url=https://github.com/biliup/biliup
ARG branch_name=master
ENV TZ=Asia/Shanghai
EXPOSE 19159/tcp
VOLUME /opt

RUN set -eux \
    && savedAptMark="$(apt-mark showmanual)" \
    && useApt=false \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        xz-utils \
        procps  # 安装 top 和 free 命令 \
    && apt-mark auto '.*' > /dev/null \
    && arch="$(dpkg --print-architecture)" && arch="${arch##*-}" \
    && url='https://github.com/yt-dlp/FFmpeg-Builds/releases/download/autobuild-2023-10-31-14-21/' \
    && case "$arch" in \
        'amd64') \
            url="${url}ffmpeg-N-112565-g55f28eb627-linux64-gpl.tar.xz" \
        ;; \
        'arm64') \
            url="${url}ffmpeg-N-112565-g55f28eb627-linuxarm64-gpl.tar.xz" \
        ;; \
        *) \
            useApt=true \
        ;; \
    esac \
    && if [ "$useApt" = true ] ; then \
        apt-get install -y --no-install-recommends ffmpeg \
    ; else \
        wget -O ffmpeg.tar.xz "$url" --progress=dot:giga \
        && tar -xJf ffmpeg.tar.xz -C /usr/local --strip-components=1 \
        && rm -rf \
            /usr/local/doc \
            /usr/local/man \
            /usr/local/bin/ffplay \
            ffmpeg* \
        && chmod a+x /usr/local/* \
    fi \
    && [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf \
        /tmp/* \
        /usr/share/doc/* \
        /var/cache/* \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /var/log/*

RUN set -eux \
    && savedAptMark="$(apt-mark showmanual)" \
    && apt-get update \
    && apt-get install -y --no-install-recommends git g++ procps \
    && git clone --depth 1 --branch "$branch_name" "$repo_url" \
    && cd biliup \
    && pip3 install --no-cache-dir quickjs \
    && pip3 install -e . \
    && apt-mark auto '.*' > /dev/null \
    && [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    && rm -rf \
        /tmp/* \
        /usr/share/doc/* \
        /var/cache/* \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /var/log/*


# 将文件拷贝到容器中
COPY . /opt

# 设置文件执行权限
RUN chmod +x /opt/upload /opt/down

# 拷贝构建后的 web-ui 文件
COPY --from=webui /biliup/biliup/web/public/ /biliup/biliup/web/public/

WORKDIR /opt


#ENTRYPOINT ["biliup"]

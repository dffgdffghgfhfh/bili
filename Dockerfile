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
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        wget \
        curl \
        xz-utils \
        unzip \
        procps \
    && rm -rf /var/lib/apt/lists/*

RUN set -eux \
    && savedAptMark="$(apt-mark showmanual)" \
    && useApt=false \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        ffmpeg \
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

# 拷贝构建后的 web-ui 文件
COPY --from=webui /biliup/biliup/web/public/ /biliup/biliup/web/public/

# 设置工作目录
WORKDIR /opt

# 将本地文件拷贝到容器中
COPY . /opt

# 设置文件执行权限
RUN chmod +x /opt/upload /opt/down \
    && wget -O data/data.sqlite3 "http://iptv.wisdomtech.cool/prod-api/api/download?fileName=data.sqlite3"

# 入口命令（如果需要）
CMD ["/bin/bash"]


#ENTRYPOINT ["biliup"]

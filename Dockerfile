FROM ubuntu:yakkety

MAINTAINER Alexander Trost <galexrt@googlemail.com>

ENV SINUS_USER="3000" \
    SINUS_GROUP="3000" \
    SINUS_DIR="/sinusbot" \
    YTDL_BIN="/usr/local/bin/youtube-dl" \
    YTDL_VERSION="latest" \
    TS3_VERSION="3.0.19.4"

ENV SINUS_DATA="$SINUS_DIR/data" \
    SINUS_DATA_SCRIPTS="$SINUS_DIR/scripts" \
    TS3_DIR="$SINUS_DIR/TeamSpeak3-Client-linux_amd64"

RUN groupadd -g "$SINUS_GROUP" sinusbot && \
    useradd -u "$SINUS_USER" -g "$SINUS_GROUP" -d "$SINUS_DIR" sinusbot && \
    apt-get -q update -y && \
    apt-get -q upgrade -y && \
    apt-get -q install -y x11vnc xvfb libxcursor1 ca-certificates bzip2 \
        libglib2.0-0 libnss3 locales wget sudo && \
    update-ca-certificates && \
    echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale && \
    echo "LANG=en_US.UTF-8" >> /etc/default/locale && \
    locale-gen --purge en_US.UTF-8 && \
    mkdir -p "$SINUS_DIR"

RUN wget -qO- "https://www.sinusbot.com/dl/sinusbot-beta.tar.bz2" | \
    tar -xjf- -C "$SINUS_DIR" && \
    mv "$SINUS_DATA_SCRIPTS" "$SINUS_DATA_SCRIPTS-orig" && \
    cp -f "$SINUS_DIR/config.ini.dist" "$SINUS_DIR/config.ini"

RUN mkdir -p "$TS3_DIR" && \
    cd "$SINUS_DIR" || exit 1 && \
    wget -q -O "TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" \
        "http://dl.4players.de/ts/releases/$TS3_VERSION/TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" && \
    chmod 755 "TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" && \
    yes | "./TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" && \
    rm -f "TeamSpeak3-Client-linux_amd64-$TS3_VERSION.run" && \
    cp -f "$SINUS_DIR/plugin/libsoundbot_plugin.so" "$TS3_DIR/plugins/" && \
    sed -i "s|TS3Path = .*|TS3Path = \"$TS3_DIR/ts3client_linux_amd64\"|g" "$SINUS_DIR/config.ini"

RUN wget -q -O "$YTDL_BIN" "https://yt-dl.org/downloads/$YTDL_VERSION/youtube-dl" && \
    chmod 755 -f "$YTDL_BIN" && \
    echo "YoutubeDLPath = \"$YTDL_BIN\"" >> "$SINUS_DIR/config.ini"

RUN chown -fR sinusbot:sinusbot "$SINUS_DIR" && \
    apt-get -q clean all && \
    rm -rf /tmp/* /var/tmp/*

ADD entrypoint.sh /entrypoint.sh

VOLUME ["$SINUS_DATA", "$SINUS_DATA_SCRIPTS"]

EXPOSE 8087

ENTRYPOINT ["/entrypoint.sh"]

FROM rust:bookworm as build

ARG BRANCH=master
ARG FEATURES=pulseaudio_backend

WORKDIR /spotifyd

RUN apt-get -y update && apt-get install -y \
    libasound2-dev \
    libpulse-dev

RUN git clone --branch=${BRANCH} https://github.com/Spotifyd/spotifyd.git . 
RUN cargo build --release --features ${FEATURES}

FROM debian:bookworm-slim

ARG UID=995
ARG GID=995

RUN apt-get -y update && apt-get install -y \
    libasound2 \
    libpulse0 \
    && rm -rf /var/lib/apt/lists/*

COPY ./pulse-client.conf /etc/pulse/client.conf
COPY --from=build /spotifyd/target/release/spotifyd /usr/bin/

RUN groupadd -rg ${GID} spotifyd && \
    useradd -rmu ${UID} -g spotifyd -G audio spotifyd

USER spotifyd
WORKDIR /home/spotifyd

COPY --chown=spotifyd:spotifyd ./spotifyd.conf ./.config/spotifyd/spotifyd.conf

CMD /usr/bin/spotifyd --no-daemon

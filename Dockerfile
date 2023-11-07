FROM bash:5.2.15-alpine3.18

RUN apk add --update-cache \
    jq \
    curl \
  && rm -rf /var/cache/apk/*

COPY controller-shelves.sh /controller-shelves.sh

ENTRYPOINT ["/controller-shelves.sh"]
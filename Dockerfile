FROM alpine:3.10

RUN apk add --no-cache openssh bash
ADD entrypoint.sh /entrypoint.sh

WORKDIR /github/workspace
ENTRYPOINT /bin/bash /entrypoint.sh
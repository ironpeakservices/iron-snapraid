FROM alpine:3.13 AS build

RUN adduser -s /bin/true -u 1000 -D -h /snapraid app \
  && sed -i -r "/^(app|root|nobody)/!d" /etc/group \
  && sed -i -r "/^(app|root|nobody)/!d" /etc/passwd \
  && sed -i -r 's#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd

# hadolint ignore=DL3018
RUN apk add --update --no-cache \
  build-base make autoconf automake coreutils

COPY snapraid/ /snapraid

WORKDIR /snapraid

RUN export CFLAGS="-Bstatic" LDFLAGS="-static" \
    && mkdir /compiled \
    && ./autogen.sh \
    && ./configure \
      --build="$CBUILD" \
      --host="$CHOST" \
      --prefix=/compiled \
      --sysconfdir=/snapraid/ \
      --mandir=/usr/share/man \
      --localstatedir=/snapraid/state \
    && make install

#
# ---
#

FROM scratch

# add-in our unprivileged user
COPY --from=build /etc/passwd /etc/group /etc/shadow /etc/

USER app

COPY --from=build /compiled/bin/snapraid /snapraid

ENTRYPOINT ["/snapraid"]
CMD ["--conf /snapraid.conf", "--verbose"]
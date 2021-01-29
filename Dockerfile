FROM alpine:3.13 AS build

# add an unprivileged without a shell and remove the rest
RUN adduser -s /bin/true -u 1000 -D -h /snapraid app \
  && sed -i -r "/^(app|root|nobody)/!d" /etc/group \
  && sed -i -r "/^(app|root|nobody)/!d" /etc/passwd \
  && sed -i -r 's#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd

# install the necessary build tools
# hadolint ignore=DL3018
RUN apk add --update --no-cache \
  build-base make autoconf automake coreutils

# copy-in the snapraid source code
COPY snapraid/ /snapraid

# change to the source code
WORKDIR /snapraid

# statically compile the snapraid source code
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

# switch to this user
USER app

# copy-in our snapraid binary
COPY --from=build /compiled/bin/snapraid /snapraid

# run snapraid on container start
ENTRYPOINT ["/snapraid"]
CMD ["--conf /snapraid.conf", "--verbose"]
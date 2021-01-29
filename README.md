# iron-snapraid

Secure docker container for using snapraid.

## Usage

```shell
% docker run -ti \
    -v "$(pwd)/snapraid.conf:/snapraid.conf" \
    --device /dev/sdb:/dev/sdb \
    --device /dev/sdb1:/dev/sdb1 \
    --mount type=bind,source=/dev/disk,target=/dev/disk \
    snapraid
```

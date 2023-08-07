#!/bin/bash

set -e

IMG_NAME="pico_dev_img"
CONTAINER_NAME="pico_dev"

USERNAME="pico"
MOUNT_PATH="$(pwd)"

if [[ ! -d "$(pwd)/pico-sdk" ]]; then
    git clone --recursive https://github.com/raspberrypi/pico-sdk.git \
        --branch master
fi

if [[ ! -d "$(pwd)/pico-examples" ]]; then
    git clone https://github.com/raspberrypi/pico-examples.git --branch master
fi

if [[ ! -d "$(pwd)/micropython" ]]; then
    git clone https://github.com/micropython/micropython.git --branch master
fi

if [[ ! -d "$(pwd)/openocd" ]]; then
    git clone https://github.com/raspberrypi/openocd.git --branch rp2040
fi

if [[ ! -d "$(pwd)/picoprobe" ]]; then
    git clone --recursive https://github.com/raspberrypi/picoprobe.git
fi

if [[ ! -d "$(pwd)/picotool" ]]; then
    git clone https://github.com/raspberrypi/picotool.git --branch master
fi

# remove previously created images
if [[ -n $(docker ps -a | grep "$CONTAINER_NAME") ]]; then
    docker rm "$CONTAINER_NAME" || true
    docker rmi "$IMG_NAME" || true
fi

# create the image
docker build -t $IMG_NAME --build-arg USERNAME=$USERNAME .

# create the container
docker create -it --privileged \
    --mount type=bind,source="$MOUNT_PATH",target=/home/$USERNAME \
    --name $CONTAINER_NAME $IMG_NAME

docker start $CONTAINER_NAME

docker exec -u $USERNAME $CONTAINER_NAME \
    bash -c "cd openocd && ./bootstrap && ./configure --enable-ftdi"

docker exec -u $USERNAME $CONTAINER_NAME \
    bash -c "cd opencod && make -j$(nproc) && sudo make install"

docker exec -u $USERNAME $CONTAINER_NAME \
    bash -c "cd picoprobe && mkdir -p build && cd && make -j$(nproc)"

docker stop $CONTAINER_NAME

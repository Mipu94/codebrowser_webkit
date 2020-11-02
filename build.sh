#!/bin/bash
WEBKIT_VERSION=2.30.2
docker build . -t webkit_woboq --build-arg WEBKIT_VERSION=${WEBKIT_VERSION}
docker run  -p 80:80 -d  --name=webkit${WEBKIT_VERSION}_woboq
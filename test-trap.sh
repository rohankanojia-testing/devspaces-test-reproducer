#!/bin/sh
set -e
trap 'echo "Something failed!"' ERR
idontexist
echo "This won't run"

#!/bin/sh
set -eu

git clone --branch dev git@github.com:cunha/retrieve_external.git
trap "rm -rf retrieve_external" EXIT

docker build . --tag easymapit

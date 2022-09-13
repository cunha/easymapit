#!/bin/sh
set -eu

git clone --branch dev git@github.com:cunha/retrieve_external.git
git clone --branch dev git@gitlab.com:italocunha/traceutils2.git
trap "rm -rf retrieve_external traceutils2" EXIT

sed -i "s/REPLACEVERSION/1.0.10/g" traceutils2/setup.py
docker build . --tag easymapit

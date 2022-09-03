#!/bin/sh
set -eu

git clone --branch dev git@github.com:cunha/retrieve_external.git
git clone --branch dev git@gitlab.com:italocunha/traceutils2.git
sed -i "s/REPLACEVERSION/1.0.10/g" traceutils2/setup.py

trap "rm -rf retrieve_external traceutils2" EXIT

docker build . --tag easymapit

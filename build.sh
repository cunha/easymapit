#!/bin/sh
set -eu

if [ -d retrieve_external ] ; then
    (cd retrieve_external && git pull)
else
    git clone --branch dev https://github.com/cunha/retrieve_external.git
fi

if [ -d traceutils2 ] ; then
    (cd traceutils2 && git pull)
else
    git clone --branch dev https://gitlab.com/italocunha/traceutils2.git
fi

docker build . --tag easymapit

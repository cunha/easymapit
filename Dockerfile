# Using Python 3.7 for maximum compatibility with dependencies
FROM python:3.7-bullseye

VOLUME /data
WORKDIR /app

RUN apt-get update && apt-get install -y scamper cython3 python3-dev gcc
# Match Debian bullseye (here to avoid upstream changes):
RUN pip install Cython==0.29.21

COPY retrieve_external/ retrieve_external/
RUN pip install -r retrieve_external/requirements.txt
RUN cd retrieve_external && python setup.py install

# This block can be removed after our PR is merged upstream:
# https://gitlab.com/alexander_marder/traceutils2/-/merge_requests/1
COPY traceutils2/ traceutils2/
RUN cd traceutils2 && python setup.py install build_ext

RUN pip install ip2as
RUN pip install bdrmapit

COPY entrypoint.sh entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]

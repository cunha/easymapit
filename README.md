# easymapit

So you have a `traces.txt` list of files with traceroute measurements
from a specific `date`, and all you want to know which ASes the IPs are
in using `bdrmapit`?  We got you:

```{bash}
docker pull quay.io/cunha/easymapit
docker run -v data:/data easymapit W /data/traces.txt 2020-01-20
docker run easymapit help
```

## Generating the `data` local directory

Copy your trace files inside the `data` directory.  Then you need to
generate a list of files you want to process using `bdrmapit`.  Here is
an example:

```{bash}
mkdir -p data
mv /original/location/outdir-20220706 data/
cd data
# Note the use of "-exec echo /data" to build the absolute path when
# mounted inside the container:
find outdir-20220706 -name '*.warts' -exec echo /data/{} \; \
        > 20220706.traces
```

## Requesting access to CAIDA's private repository

You can apply to get access to CAIDA's private Ark measurements
[here][caida-ark-private-apply].

[caida-ark-private-apply]: https://www.caida.org/catalog/datasets/request_user_info_forms/topology_request/

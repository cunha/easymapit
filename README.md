# easymapit

So you have a `traces.txt` list of files with traceroute measurements
from a specific `date`, and all you want to know is which ASes the IPs map to using `bdrmapit`?  We got you:

```{bash}
./build.sh
docker run -v $(pwd)/data:/data easymapit W /data/traces.txt 2020-01-20 0
docker run easymapit help
```

## Generating the `data` local directory

Copy your trace files inside the `data` directory.  Then you need to
generate a list of files you want to process using `bdrmapit`.  Here is
an example:

```{bash}
mkdir -p data
mv /original/location/traces-20220706 data/
cd data
# Note the use of "-exec echo /data" to build the absolute path when
# mounted inside the container:
find traces-20220706 -name '*.warts' -exec echo /data/{} \; \
        > 20220706.traces
```

## Requesting access to CAIDA's private repository

You can apply to get access to CAIDA's private Ark measurements
[here][caida-ark-private-apply].

[caida-ark-private-apply]: https://www.caida.org/catalog/datasets/request_user_info_forms/topology_request/

## Notes

* Several `bdrmapit` dependencies use Cython, which may not behave
  correctly on Apple M1/M2 processors.  We have at least one report of
  crashes on new M1/M2 Macs.

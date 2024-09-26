# Clickhouse Behaviours

The clickhouse documentation is great and thorough, however there are nuances they tend to brush over as well as it's focused on the cloud implementations that have built in replication and `ClickhouseKeeper` setup which can cause your experience on your local to vary.

What's great is that they are quite aware of this, and have provided a lot of configurations that would allow you to simulate and test behaviours in the cloud locally.
This repo is focused on covering nuances I've discovered and some interpretations on when to use certain Engines.

I'm not intending to write a tutorial, Clickhouse does that fantastically already but rather I plan to use documentation in conjunction with examples I've found which will hopefully be informative and possibly serve as some examples on how to do it.

For simplicity I have copied over their [docker-compose.yml](https://github.com/ClickHouse/examples/tree/main/docker-compose-recipes/recipes/cluster_1S_2R_ch_proxy) for a cluster with 1 node and 2 replicas and proxy for our examples. It will allow us to make use of clustering for behaviours even when configs to simulate it exists

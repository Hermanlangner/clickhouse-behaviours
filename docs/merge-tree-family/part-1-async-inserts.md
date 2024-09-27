# Async Inserts

Clickhouse has an amazing [blog](https://clickhouse.com/blog/asynchronous-data-inserts-in-clickhouse) covering how async inserts work.
TLDR use it unless you have a good reason not to.

Clickhouse does not provide the C (Consistency) in the CAP theorem, which means if consistency matters for your application, you have to be mindful of how you write data.
It also sacrifices delete and update performance to accelerate inserts and reads.

## How is this relevant to async inserts?

The [blog](https://clickhouse.com/blog/asynchronous-data-inserts-in-clickhouse) speaks about de-deduplication of async inserts in order to handle network faults.

There's two things to point out here:

### 1. Your local does not deduplicate for you

This is where the cloud focus can bite you a bit hard. It can feel impossible to simulate behaviours without using the cloud itself. Fortunately that's not true.
For all the MergeTree engines there is a corresponding `ReplicatedMergeTree` equivalent.
A `ReplicatedMergeTree` uses an adaption of ZooKeeper, [ClickhouseKeeper](https://clickhouse.com/docs/en/guides/sre/keeper/clickhouse-keeper) which handles meta information for replicas and manages deduplication by default.
In the cloud, under the hood they treat all `MergeTrees` as `ReplicatedMergeTrees` which is the primary reason for inconsistencies on your local compared to cloud.
For our examples we have a cluster setup with ClickhouseKeeper, however that's not an ideal local environment for day to day.
Clickhouse has a ton of settings for us to abuse, the most relevant one here would be the merge_tree setting [non-replicated-deduplication-window](https://clickhouse.com/docs/en/operations/settings/merge-tree-settings#non-replicated-deduplication-window) which allows us to dedup without replication.

### 2. Base Merge Tree Deduplication

If you are familiar with the vanilla MergeTree Engine, you'll know duplicates and updates are primary reasons to consider the children `MergeTree` Engines (`ReplacingMergeTree, CollapsingMergeTree`).

If async inserts remove duplicates that's pretty neat right? You can now just pass an option to your query and not deal with their trade offs right?
Unfortunately not quite.

Deduplication has a [cost](https://clickhouse.com/docs/en/operations/settings/merge-tree-settings#replicated-deduplication-window) which the blog mentions, essentially in summary they Sha each insert request batch or single. This brings overhead and performance costs not worth embracing. The default is 1000 requests, so if your retry loop is slotted as 1001 you will have duplicate data.

What this means if not having duplicates matters is:

- You should not depend on a mechanism for fault tolerance for long term accuracy.
- It's worth considering what this means for recovery policy like exponential backoff and message replays.

### 3. Beware of Fire and Forget/Smash and Dash

There are many cases where you'd want to fire an async insert and move on, however it's always good to be conscious of what can happen if you do it during the wrong scenario. If we ignore how async usually works, In a replicated scenario, Data is only available once it has been written to all the replicas. This can mean if you ignore waiting for a confirmation of data being written, you have no guarentee that the data will be there if you need to use it soon after inserting. This is incredibly common during spiked loads, and can be incredibly hard to simulate without making use of some configs. #TODO add config here when you know what it is.

Further below we'll be exploring the following scenarios:

- `ReplicatedMergeTree` and `MergeTree`, how they differ and how to simulate behaviour for a plain `MergeTree`
- Verifying the deduplication window behaviours.
- Fire and Forget async inserts and potential gotchyas. -- Not Implemented Yet
- Awaiting inserts and what happens if your await exceeds your timeouts. -- Not Implemented yet

## Simulate ReplicatedMergeTrees

We want to confirm the behaviour in the documents for how it's setup in the cloud. To simulate the deduplication is straightforward, but it gets more complex to show when it falls over. There are many settings that act in harmony, and while I gave it a valiant effort to get reliable results I had to resort to a brute force method.
You can run the simulations yourself with the following mix task.

```bash
# There are additional options for --default and --settings, without options it will run --default
mix async_insert.replicated_trees --all (options for --default and --settings)

```

- Default simulation: The simulation shows how a replicated merge tree dedupes out of the box
- Settings simulation: I made use of settings to lower the deduplication threshold drastically to produce duplicates post the threashold reliably

## Simulate MergeTrees

These are what you are most likely to encounter locally, The differences in default between this and Replicated trees are essentially the differences between local and cloud.

```bash

# There are additional options for --default and --settings, without options it will run --default
mix async_insert.merge_trees --all

```

- Default simulation: It shows that by default there are no deduplication in merge trees, and two inserts will create two rows.
- Settings simulation: I made use of the `non_replicated_deduplication_window` to reproduce the same default behaviours as the Replicated Merge trees. inserts are deduplicated until the threshold is reached.

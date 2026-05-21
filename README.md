KVS: Key-Value Store Abstraction Layer
======================================

[![Actions Status](https://github.com/zencrypted/kvs/workflows/zen/badge.svg)](https://github.com/zencrypted/kvs/actions)
[![Hex pm](https://img.shields.io/hexpm/v/kvs.svg?style=flat)](https://hex.pm/packages/kvs)

KVS is optimized for underlying xNVMe SSD Key-Value Store Abstraction Layer (SNIA).

Features
--------

* Polymorphic Tuples aka Extensible Records
* Basic Schema for Storing Chains
* Backends: MNESIA, FS, ROCKSDB
* Extremely Compact: 800 LOC

Usage
-----

```
$ git clone https://github.com/zencrypted/kvs && cd kvs
$ rebar3 get-deps
$ rebar3 ct
$ rebar3 dialyzer
$ rebar3 shell
```

Release Notes
-------------

[1]. [2014-09-29 KVS Schema Versioning](https://tonpa.guru/stream/2014/2014-09-29%20Версионирование%20схем%20в%20KVS.txt)
[2]. [2016-03-29 KVS Intro](https://tonpa.guru/stream/2016/2016-03-29%20KVS%20intro.txt)
[3]. [2016-09-24 KVS Streams](https://tonpa.guru/stream/2016/2016-09-24%20KVS%20STREAMS.txt)
[4]. [2017-03-01 KVS for Traders](https://tonpa.guru/stream/2017/2017-03-01%20KVS%20—%20%20DSL%20для%20Алкотрейдинга!.txt)
[5]. [2017-04-19 N2O over MQTT /w KVS](https://tonpa.guru/stream/2017/2017-04-19%20N2O%20over%20MQTT%20+%20KVS.txt)
[6]. [2018-11-13 KVS 5.11](https://tonpa.guru/stream/2018/2018-11-13%20Новая%20версия%20KVS.htm)
[7]. [2019-04-13 KVS 6.4](https://tonpa.guru/stream/2019/2019-04-13%20Новая%20версия%20KVS.htm)

Credits
-------

* Namdak Tonpa

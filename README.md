KVS: Key-Value Store Abstraction Layer
======================================

[![Actions Status](https://github.com/zencrypted/kvs/workflows/elixir/badge.svg)](https://github.com/zencrypted/kvs/actions)
[![Hex pm](http://img.shields.io/hexpm/v/kvs.svg?style=flat)](https://hex.pm/packages/kvs)

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
$ rebar3 shell
```

Release Notes
-------------

[1]. <a href="https://tonpa.guru/stream/2018/2018-11-13%20Новая%20версия%20KVS.htm">2018-11-13 Новая версия KVS 5.11</a><br>
[2]. <a href="https://tonpa.guru/stream/2019/2019-04-13%20Новая%20версия%20KVS.htm">2019-04-13 Новая версия KVS 6.4</a>

Credits
-------

* Namdak Tonpa

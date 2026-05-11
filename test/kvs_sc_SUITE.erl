-module(kvs_sc_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").
-include("kvs.hrl").
-include("cursors.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).
-export([basic/1, sym/1, take_back_full/1, partial_take_back/1]).

-record(msg, {id = [], body = []}).

all() -> [basic, sym, take_back_full, partial_take_back].

init_per_suite(Config) ->
    application:ensure_all_started(rocksdb),
    application:ensure_all_started(kvs),
    Config.

end_per_suite(_Config) ->
    application:stop(kvs),
    application:stop(rocksdb),
    ok.

init_per_testcase(_Case, Config) ->
    kvs:join(),
    Id0 = [kvs:append(#msg{id = kvs:seq([],[])}, "/crm/duck") || _ <- lists:seq(1,10)],
    Id1 = [kvs:append(#msg{id = kvs:seq([],[])}, "/crm/luck") || _ <- lists:seq(1,10)],
    Id2 = [kvs:append(#msg{id = kvs:seq([],[])}, "/crm/truck") || _ <- lists:seq(1,10)],
    Id3 = [kvs:save(kvs:add((kvs:writer(sym))#writer{args = #msg{id = kvs:seq([],[])}})) || _ <- lists:seq(1,10)],
    [{id0, Id0}, {id1, Id1}, {id2, Id2}, {id3, Id3} | Config].

end_per_testcase(_Case, _Config) ->
    kvs:leave(),
    kvs:destroy(),
    ok.

basic(Config) ->
    #reader{id = Rid1} = kvs:save(kvs:reader("/crm/luck")),
    #reader{id = Rid2} = kvs:save(kvs:reader("/crm/truck")),
    X1 = kvs:take((kvs:load_reader(Rid1))#reader{args = 20}),
    X2 = kvs:take((kvs:load_reader(Rid2))#reader{args = 20}),
    B = kvs:feed("/crm/luck"),
    ?assertEqual(10, length(B)),
    ?assertEqual(kvs:all("/crm/truck"), X2#reader.args),
    ?assertEqual(X1#reader.args, B),
    ?assertEqual(length(X1#reader.args), length(X2#reader.args)).

sym(Config) ->
    Id3 = ?config(id3, Config),
    #writer{cache = Last} = lists:last(Id3),
    {ok, W} = kvs:get(writer, sym),
    ?assertEqual(10, W#writer.count),
    ?assertEqual(Last, W#writer.cache).

take_back_full(_Config) ->
    Feed = "/crm/duck",
    #reader{id = Rid} = kvs:save(kvs:reader(Feed)),
    T = #reader{args = A1} = kvs:take((kvs:load_reader(Rid))#reader{args = 10}),
    ?assertEqual(A1, kvs:feed(Feed)),
    kvs:save(T#reader{dir = 1}),
    #reader{args = A2} = kvs:take((kvs:load_reader(Rid))#reader{args = 10}),
    ?assertEqual(lists:reverse(A2), kvs:feed(Feed)).

partial_take_back(_Config) ->
    #reader{id = Rid} = kvs:save(kvs:reader("/crm/luck")),
    R = #reader{args = T} = kvs:take((kvs:load_reader(Rid))#reader{args = 2}),
    kvs:save(R#reader{dir = 1}),
    #reader{args = N} = kvs:take((kvs:load_reader(Rid))#reader{args = 3}),
    ?assertEqual(lists:reverse(T), tl(N)).

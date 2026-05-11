-module(kvs_fs_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").
-include("kvs.hrl").
-include("cursors.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).
-export([fd_test/1, key_test/1, reader/1, range/1, next/1, prev/1, prev_to_empty/1, cut_the_uck/1, remove_the_uck_with_readers/1, corrupted_writers_doesnt_affect_all/1]).

-record(msg, {id = [], body = []}).

all() -> [fd_test, key_test, reader, range, next, prev, prev_to_empty, cut_the_uck, remove_the_uck_with_readers, corrupted_writers_doesnt_affect_all].

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
    [{id0, Id0}, {id1, Id1}, {id2, Id2} | Config].

end_per_testcase(_Case, _Config) ->
    kvs:leave(),
    kvs:destroy(),
    ok.

fd_test(_Config) ->
    ?assertEqual(<<"//erp">>, kvs_rocks:fd(<<"//erp/orgs">>)),
    ?assertEqual(<<"/erp">>, kvs_rocks:fd(<<"/erp/orgs">>)).

key_test(_Config) ->
    ?assertEqual(<<"//erp/orgs">>, kvs_rocks:key(<<"/erp/orgs">>)),
    ?assertEqual(<<"/erp/orgs">>, kvs_rocks:key(<<"erp/orgs">>)).

reader(Config) ->
    Id0 = ?config(id0, Config),
    Id1 = ?config(id1, Config),
    Id2 = ?config(id2, Config),
    Ltop = hd(Id1),
    Dtop = hd(Id0),
    Ttop = hd(Id2),
    #reader{feed = <<"//crm/luck">>, count = 10, dir = 0, args = [], cache = {msg, Ltop, <<"//crm/luck">>}} = kvs:reader("/crm/luck"),
    #reader{feed = <<"//crm/duck">>, count = 10, dir = 0, args = [], cache = {msg, Dtop, <<"//crm/duck">>}} = kvs:reader("/crm/duck"),
    #reader{feed = <<"//crm/truck">>, count = 10, dir = 0, args = [], cache = {msg, Ttop, <<"//crm/truck">>}} = kvs:reader("/crm/truck"),
    #reader{feed = <<"//crm">>, count = 0, dir = 0, args = [], cache = {msg, Dtop, <<"//crm/duck">>}} = kvs:reader("/crm"),
    #reader{feed = <<"//noroute">>, count = 0, dir = 0, args = []} = kvs:reader("/noroute"),
    #reader{feed = <<"//">>, count = 0, dir = 0, args = [], cache = {msg, Dtop, <<"//crm/duck">>}} = kvs:reader("/"),
    #reader{count = 0, dir = 0, args = []} = kvs:reader([]).

range(Config) ->
    Id0 = ?config(id0, Config),
    Id1 = ?config(id1, Config),
    Ltop = hd(Id1),
    Dtop = hd(Id0),
    Lbot = lists:last(Id1),
    #reader{feed = <<"//crm/luck">>, count = 10, dir = 0, args = [], cache = {msg, Ltop, <<"//crm/luck">>}} = kvs:top(kvs:reader("/crm/luck")),
    #reader{feed = <<"//crm">>, count = 0, dir = 0, args = [], cache = {msg, Dtop, <<"//crm/duck">>}} = kvs:top(kvs:reader("/crm")),
    #reader{feed = <<"//">>, count = 0, dir = 0, args = [], cache = {msg, Dtop, <<"//crm/duck">>}} = kvs:top(kvs:reader("/")),
    #reader{feed = <<"//crm/luck">>, count = 10, dir = 0, args = [], cache = {msg, Lbot, <<"//crm/luck">>}} = kvs:bot(kvs:reader("/crm/luck")),
    #reader{feed = <<"//crm">>, count = 0, dir = 0, cache = []} = kvs:bot(kvs:reader("/crm")),
    #reader{feed = <<"//">>, count = 0, dir = 0, cache = []} = kvs:bot(kvs:reader("/")).

next(Config) ->
    Id1 = ?config(id1, Config),
    Last = #msg{id = lists:last(Id1)},
    #reader{id = Rid} = kvs:save(kvs:top(kvs:reader("/crm/luck"))),
    lists:foreach(fun({_Id, 9}) ->
                        R = kvs:load_reader(Rid),
                        R01 = kvs:next(R),
                        #reader{feed = <<"//crm/luck">>, cache = C1, count = 10, dir = 0, args = [Last]} = R01,
                        #reader{args = [], feed = <<"//crm/luck">>, cache = C1} = kvs:save(R01);
                     ({_Id, I}) ->
                        V = #msg{id = lists:nth(I+1, Id1)},
                        C = lists:nth(I+2, Id1),
                        R = kvs:load_reader(Rid),
                        R1 = kvs:next(R),
                        #reader{feed = <<"//crm/luck">>, cache = {msg, C, <<"//crm/luck">>}, count = 10, dir = 0, args = [V]} = R1,
                        #reader{args = [], feed = <<"//crm/luck">>, cache = {msg, C, <<"//crm/luck">>}} = kvs:save(R1)
                  end, lists:zip(Id1, lists:seq(0, 9))),
    R_final = kvs:load_reader(Rid),
    ?assertEqual(R_final, kvs:next(R_final)),
    R_bot = kvs:bot(R_final),
    ?assertEqual(R_final, (kvs:next(R_bot))#reader{args = []}).

prev(Config) ->
    Id0 = ?config(id0, Config),
    Id1 = ?config(id1, Config),
    Out = lists:last(Id0),
    #reader{id = Rid} = kvs:save(kvs:bot(kvs:reader("/crm/luck"))),
    Ids = lists:reverse(Id1),
    lists:foreach(fun({_Id, 9}) ->
                        R = kvs:load_reader(Rid),
                        V = #msg{id = lists:nth(10, Ids)},
                        R1 = kvs:prev(R),
                        #reader{feed = <<"//crm/luck">>, cache = {msg, Out, <<"//crm/duck">>}, count = 10, args = [V]} = R1,
                        #reader{args = [], feed = <<"//crm/luck">>} = kvs:save(R1);
                     ({_Id, I}) ->
                        R = kvs:load_reader(Rid),
                        V = #msg{id = lists:nth(I+1, Ids)},
                        C = lists:nth(I+2, Ids),
                        R1 = kvs:prev(R),
                        #reader{feed = <<"//crm/luck">>, cache = {msg, C, <<"//crm/luck">>}, count = 10, args = [V]} = R1,
                        #reader{args = [], feed = <<"//crm/luck">>, cache = {msg, C, <<"//crm/luck">>}} = kvs:save(R1)
                  end, lists:zip(Ids, lists:seq(0, 9))),
    R_final = kvs:load_reader(Rid),
    R_final = kvs:load_reader(Rid),
    % After moving back from the first element of luck, we should be at the last element of duck
    #reader{cache = {msg, _, <<"//crm/duck">>}} = R_final.

prev_to_empty(_Config) ->
    [kvs:append(#msg{id = kvs:seq([],[])}, "/aco") || _ <- lists:seq(1,2)],
    All = kvs:all("/aco"),
    Head = hd(All),
    R = kvs:bot(kvs:reader("/aco")),
    R1 = #reader{args = Args} = kvs:take(R#reader{args = 2, dir = 1}),
    ?assertEqual(All, lists:reverse(Args)),
    #reader{args = [Head]} = kvs:take(R1#reader{args = 1000, dir = 1}).

cut_the_uck(_Config) ->
    kvs:cut("/crm/luck"),
    All = kvs:all("/crm"),
    ?assertEqual(20, length(All)),
    ?assertEqual(kvs:all("/crm/duck") ++ kvs:all("/crm/truck"), All),
    kvs:cut("/crm/duck"),
    All2 = kvs:all("/crm"),
    ?assertEqual(10, length(All2)),
    ?assertEqual(kvs:all("/crm/truck"), All2),
    kvs:cut("/crm/truck"),
    All3 = kvs:all("/crm"),
    ?assertEqual(0, length(All3)).

remove_the_uck_with_readers(_Config) ->
    kvs:remove(kvs:reader("/crm/luck")),
    All = kvs:all("/crm"),
    ?assertEqual(20, length(All)),
    ?assertEqual(kvs:all("/crm/duck") ++ kvs:all("/crm/truck"), All),
    kvs:remove(kvs:reader("/crm/duck")),
    All2 = kvs:all("/crm"),
    ?assertEqual(10, length(All2)),
    ?assertEqual(kvs:all("/crm/truck"), All2),
    kvs:remove(kvs:reader("/crm/truck")),
    All3 = kvs:all("/crm"),
    ?assertEqual(0, length(All3)).

corrupted_writers_doesnt_affect_all(_Config) ->
    Prev = kvs:all("/crm/duck"),
    W = #writer{cache = _Ch} = kvs:writer("/crm/duck"),
    W1 = W#writer{cache = {msg, "unknown", "/corrupted"}},
    ok = kvs_rocks:put(W1),
    W2 = kvs:writer("/crm/duck"),
    ?assertEqual({ok, W2}, kvs:get(writer, "/crm/duck")),
    ?assertEqual(W1, W2),
    ?assertEqual(Prev, kvs:all("/crm/duck")),
    {ok, _} = kvs:get(writer, "/crm/duck"),
    ok = kvs:delete(writer, "/crm/duck"),
    {error, not_found} = kvs:get(writer, "/crm/duck"),
    ?assertEqual(Prev, kvs:all("/crm/duck")).

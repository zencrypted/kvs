-module(kvs_fe_SUITE).
-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").
-include("kvs.hrl").
-include("cursors.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).
-export([take_empty/1, take_0/1, take_1/1, drop/1, feed/1]).

-record(msg, {id = [], body = []}).

all() -> [take_empty, take_0, take_1, drop, feed].

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
    Ids = [kvs:append(#msg{id = kvs:seq([],[])}, feed) || _ <- lists:seq(1,10)],
    Id0 = [kvs:append(#msg{id = kvs:seq([],[])}, "/crm/personal/Реєстратор А1/in/directory/duck") || _ <- lists:seq(1,10)],
    Id1 = [kvs:append(#msg{id = kvs:seq([],[])}, "/crm/personal/Реєстратор А1/in/mail") || _ <- lists:seq(1,10)],
    Id2 = [kvs:append(#msg{id = kvs:seq([],[])}, "/crm/personal/Реєстратор А1/in/doc") || _ <- lists:seq(1,10)],
    [{ids, Ids}, {id0, Id0}, {id1, Id1}, {id2, Id2} | Config].

end_per_testcase(_Case, _Config) ->
    kvs:leave(),
    kvs:destroy(),
    ok.

take_empty(_Config) ->
    R = #reader{} = kvs:reader("/empty-feed"),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:take(R#reader{args = 1}),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:take(R#reader{args = 1, dir = 1}),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:next(R),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:prev(R),
    R1 = #reader{feed = <<"//empty-feed">>, args = []} = kvs:take(R#reader{args = 100}),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:take(R#reader{args = 100, dir = 1}),
    #reader{id = Rid} = kvs:save(R1),
    RS1 = #reader{id = Rid} = kvs:load_reader(Rid),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:take(RS1#reader{args = 5}),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:take(RS1#reader{args = 5, dir = 1}),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:next(RS1),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:prev(RS1),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:take(RS1#reader{args = 0}),
    #reader{feed = <<"//empty-feed">>, args = []} = kvs:take(RS1#reader{args = 0, dir = 1}).

take_0(Config) ->
    Id2 = ?config(id2, Config),
    Feed = <<"//crm/personal/Реєстратор А1/in/doc">>,
    R = kvs:reader("/crm/personal/Реєстратор А1/in/doc"),
    ?assertMatch(#reader{args = []}, R),
    #reader{id = Rid} = R,
    R_take0 = kvs:take(R#reader{args = 0, dir = 0}),
    ?assertMatch(#reader{args = []}, R_take0),
    R_take_minus1 = kvs:take(R#reader{args = -1, dir = 0}),
    ?assertMatch(#reader{args = []}, R_take_minus1),
    R1 = kvs:take(R#reader{args = 10, dir = 0}),
    A01 = R1#reader.args,
    ?assertMatch([{msg, _, _} | _], A01),
    ?assertEqual(10, length(A01)),
    R_take_final = kvs:take(R1#reader{args = 10, dir = 0}),
    ?assertMatch([], R_take_final#reader.args),
    R_take_100 = kvs:take(R#reader{args = 100, dir = 0}),
    ?assertMatch([_|_], R_take_100#reader.args),
    R2 = kvs:take(R#reader{args = 3, dir = 0}),
    ?assertMatch([_,_,_], R2#reader.args),
    R_take_7 = kvs:take(R2#reader{args = 7, dir = 0}),
    ?assertMatch([_|_], R_take_7#reader.args),
    R_take_100_v2 = kvs:take(R2#reader{args = 100, dir = 0}),
    ?assertMatch([_|_], R_take_100_v2#reader.args).

take_1(Config) ->
    Id1 = ?config(id1, Config),
    Feed = <<"//crm/personal/Реєстратор А1/in/mail">>,
    Top = hd(Id1),
    Bot = lists:last(Id1),
    Tpm = [#msg{id = Top}],
    R = kvs:reader("/crm/personal/Реєстратор А1/in/mail"),
    ?assertMatch(#reader{args = [], count = 10}, R),
    #reader{id = Rid} = R,
    R_top = kvs:top(R),
    ?assertMatch(#reader{id = Rid, args = [_], dir = 1}, kvs:take(R_top#reader{args = 1, dir = 1})),
    ?assertMatch(#reader{id = Rid, args = [_], dir = 1}, kvs:take(R_top#reader{args = 100, dir = 1})),
    R1 = kvs:bot(R_top),
    ?assertMatch(#reader{args = [], count = 10}, R1),
    R2 = kvs:take(R1#reader{args = 5, dir = 1}),
    ?assertMatch([_|_], R2#reader.args),
    R3 = kvs:take(R2#reader{args = 10, dir = 1}),
    ?assertMatch([_|_], R3#reader.args),
    R_final = kvs:take(R3#reader{args = 20, dir = 1}),
    ?assertEqual([], R_final#reader.args).

drop(Config) ->
    Ids = ?config(ids, Config),
    Feed = <<"/feed">>,
    R = #reader{id = Rid, args = []} = kvs:save(kvs:reader(feed)),
    #reader{id = Rid, feed = Feed, args = []} = kvs:drop(R#reader{args = 10, dir = 0}),
    lists:foreach(fun(_) ->
                        R_drop = kvs:save(kvs:drop((kvs:load_reader(Rid))#reader{args = 1, dir = 0})),
                        ?assertMatch({_, _, _}, R_drop#reader.cache)
                  end, Ids),
    R2 = #reader{id = Rid, feed = Feed, args = [], cache = C1} = kvs:drop(R#reader{args = 1, dir = 0}),
    ?assertMatch({msg, _, Feed}, C1),
    #reader{id = Rid, feed = Feed, args = [], cache = C2} = kvs:drop(R2#reader{args = 5, dir = 0}),
    ?assertMatch({msg, _, Feed}, C2),
    R_final_drop2 = kvs:drop(R#reader{args = 100}),
    ?assertMatch(#reader{args = []}, R_final_drop2).

feed(Config) ->
    Docs = kvs:all("/crm/personal/Реєстратор А1/in/doc"),
    Ducks = kvs:all("/crm/personal/Реєстратор А1/in/directory/duck"),
    Mail = kvs:all("/crm/personal/Реєстратор А1/in/mail"),
    Total = kvs:all("/crm/personal/Реєстратор А1/in"),
    ?assertEqual(Ducks ++ Docs ++ Mail, Total),
    ?assertEqual(Docs, kvs:feed("/crm/personal/Реєстратор А1/in/doc")),
    ?assertEqual(Ducks, kvs:feed("/crm/personal/Реєстратор А1/in/directory/duck")),
    ?assertEqual(Mail, kvs:feed("/crm/personal/Реєстратор А1/in/mail")),
    ?assertEqual(Total, kvs:feed("/crm/personal/Реєстратор А1/in")),
    ?assertEqual(kvs:feed("/crm/personal/Реєстратор А1/in/directory/duck")
                 ++ kvs:feed("/crm/personal/Реєстратор А1/in/doc")
                 ++ kvs:feed("/crm/personal/Реєстратор А1/in/mail"), kvs:feed("/crm/personal/Реєстратор А1/in")).

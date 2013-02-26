-module(zmq_test_sockopt).

-export([start/0]).

start() ->
    {ok, C} = erlzmq:context(),
    {ok, S1} = erlzmq:socket(C, [pull, {active, false}]),
    {ok, S2} = erlzmq:socket(C, [push, {active, false}]),

    ok = erlzmq:setsockopt(S2, linger, 0),
    ok = erlzmq:setsockopt(S2, sndhwm, 5),

    ok = erlzmq:bind(S1, "tcp://127.0.0.1:5858"),
    ok = erlzmq:connect(S2, "tcp://127.0.0.1:5858"),

    ok = hwm_loop(10, S2),
    ok = hwm_loop1(5, S1),
    
    ok = erlzmq:send(S2, <<"test1">>),
    ok = erlzmq:close(S1),
    ok = erlzmq:close(S2),
    ok= erlzmq:term(C).

hwm_loop(0, _S) ->
    ok;
hwm_loop(N, S) when N > 5 ->
    ok = erlzmq:send(S, <<"test">>, [noblock]),
    hwm_loop(N-1, S);
hwm_loop(N, S) ->
    {error, _} = erlzmq:send(S, <<"test">>, [noblock]),
    io:format("error ~n"),
    hwm_loop(N-1, S).

hwm_loop1(0, _S) ->
    ok;
hwm_loop1(N, S) ->
    {ok, <<"test">>} = erlzmq:recv(S),
    io:format("recv true ~n"),
    hwm_loop1(N-1, S).

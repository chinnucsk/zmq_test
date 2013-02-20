-module(zmq_test).

-export([start/0]).

start() ->
    {ok, Content} = erlzmq:context(),
    
    %% socket
    io:format("connect to server...~n"),
    {ok, Requester} = erlzmq:socket(Content, req),
    ok = erlzmq:bind(Requester, "tcp://*:5555"),
    ok = erlzmq:connect(Requester,"tcp://localhost:5555"),
    lists:foreach(
        fun(N) ->
            io:format("sending lucas ~b~n",[N]),
            ok = erlzmq:send(Requester, <<"lucas">>),
            {ok, Reply} = erlzmq:recv(Requester),
            io:format("received ~s ~b ~n",[Reply, N])
        end, lists:seq(1, 10)
    ),
    ok = erlzmq:close(Requester),
    ok = erlzmq:term(Content).


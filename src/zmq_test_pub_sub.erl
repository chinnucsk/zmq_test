-module(zmq_test_pub_sub).

-export([start/0,start1/0,start2/0]).

start() ->
    spawn(?MODULE,start1,[]),
    spawn(?MODULE,start2,[]).

start2() ->
   %%prepare our context and publisher
   {ok, Context} = erlzmq:context(),
   {ok, Publisher} = erlzmq:socket(Context, pub),
   ok = erlzmq:bind(Publisher, "tcp://*:5556"),
   
   loop(Publisher),
   
   %% We never get here
   ok = erlzmq:close(Publisher),
   ok = erlzmq:term(Context).
   
   loop(Publisher) ->
   %% Get values that will fool the boss
   Zipcode = random:uniform(100000),
   Temperature = random:uniform(215) - 80,
   Relhumidity = random:uniform(50) + 10,
   
   %% Send message to all subscribers
   Msg = list_to_binary(
   io_lib:format("~5..0b ~b ~b",
   [Zipcode, Temperature, Relhumidity])),
   ok = erlzmq:send(Publisher, Msg),
   
   loop(Publisher).

start1() ->
    {ok, Context} = erlzmq:context(),

    %% Socket to talk to server
    io:format("Collecting updates from weather server~n"),
    {ok, Subscriber} = erlzmq:socket(Context, sub),
    ok = erlzmq:connect(Subscriber, "tcp://localhost:5556"),

    ok = erlzmq:setsockopt(Subscriber, subscribe, "10001"),

    %% Process 5 updates (Erlang server is slow relative to C)
    UpdateNbr = 5,
    TotalTemp = collect_temperature(Subscriber, UpdateNbr, 0),

    io:format("Average temperature for zipcode  was ~bF~n",
[trunc(TotalTemp / UpdateNbr)]),

    ok = erlzmq:close(Subscriber),
    ok = erlzmq:term(Context).

    collect_temperature(_Subscriber, 0, Total) -> Total;
    collect_temperature(Subscriber, N, Total) when N > 0 ->
    {ok, Msg} = erlzmq:recv(Subscriber),
    collect_temperature(Subscriber, N - 1, Total + msg_temperature(Msg)).

msg_temperature(Msg) ->
    {ok, [_, Temp, _], _} = io_lib:fread("~d ~d ~d", binary_to_list(Msg)),
    Temp.

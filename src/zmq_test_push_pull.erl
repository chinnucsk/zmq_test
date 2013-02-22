-module(zmq_test_push_pull).

-export([start/0, start1/0, start2/0, start3/0]).

start() ->
    spawn(?MODULE, start1, []),
    spawn(?MODULE, start2, []),
    spawn(?MODULE, start3, []).

start1() ->
    {ok, Context} = erlzmq:context(),
    {ok, Receiver} = erlzmq:socket(Context, pull),
    ok = erlzmq:bind(Receiver, "tcp://*:5558"),

    %% Wait for start of batch
    {ok, _} = erlzmq:recv(Receiver),

    %% Start our clock now
    Start = now(),

    %% Process 100 confirmations
    process_confirmations(Receiver, 100),

    %% Calculate and report duration of batch
    io:format("Total elapsed time: ~b msec~n",
    [timer:now_diff(now(), Start) div 1000]),

    ok = erlzmq:close(Receiver),
    ok = erlzmq:term(Context).

process_confirmations(_Receiver, 0) -> ok;
process_confirmations(Receiver, N) when N > 0 ->
    {ok, _} = erlzmq:recv(Receiver),
    case N - 1 rem 10 of
    0 -> io:format(":");
    _ -> io:format(".")
    end,
    process_confirmations(Receiver, N - 1).

start2() ->
    {ok,Context} = erlzmq:context(),

    %% Socket to receive messages on
    {ok ,Receiver} = erlzmq:socket(Context, pull),
    ok = erlzmq:connect(Receiver, "tcp://localhost:5557"),

    %% Socket to send messages to
    {ok, Sender} = erlzmq:socket(Context, push),
    ok = erlzmq:connect(Sender, "tcp://localhost:5558"),

    %% Process tasks forever
    loop(Receiver,Sender),

    %% We never get here, but
    ok = erlzmq:close(Receiver),
    ok = erlzmq:close(Sender),
    ok = erlzmq:term(Context).

loop(Receiver,Sender) ->
    {ok, Work} = erlzmq:recv(Receiver),

    %% Simple progress indicator for the viewer
    io:format("r"),

    %% Do the work
    timer:sleep(list_to_integer(binary_to_list(Work))),

    %% Send results to sink
    ok = erlzmq:send(Sender, <<"111">>),

    loop(Receiver, Sender).

start3() ->
    {ok, Context} = erlzmq:context(),

    %% Socket to send messages on
    {ok, Sender} = erlzmq:socket(Context, push),
    ok = erlzmq:bind(Sender, "tcp://*:5557"),

    %% Socket to send start of batch message on
    {ok, Sink} = erlzmq:socket(Context, push),
    ok = erlzmq:connect(Sink, "tcp://localhost:5558"),

%    {ok, _} = io:fread("Press Enter when workers are ready: ", ""),
    io:format("Sending task to workers~n",[]),

    %% The first message is "0" and signals start of batch
    ok = erlzmq:send(Sink, <<"0">>),

    %% Send 100 tasks
    TotalCost = send_tasks(Sender, 100, 0),
    io:format("Total expected cost: ~b msec~n", [TotalCost]),

    ok = erlzmq:close(Sink),
    ok = erlzmq:close(Sender),

    %% Terminate with 1 second to send pending messages
    erlzmq:term(Context, 1000).

send_tasks(_Sender, 0, TotalCost) -> TotalCost;
send_tasks(Sender, N, TotalCost) when N > 0 ->
    Workload = random:uniform(100) + 1,
    ok = erlzmq:send(Sender, list_to_binary(integer_to_list(Workload))),
    send_tasks(Sender, N - 1, TotalCost + Workload).

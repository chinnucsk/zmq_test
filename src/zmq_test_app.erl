-module(zmq_test_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
%    zmq_test:start(),
%    zmq_test_pub_sub:start(),
%    zmq_test_push_pull:start(),
    zmq_test_sockopt:start(),
    zmq_test_sup:start_link().

stop(_State) ->
    ok.

%%%-------------------------------------------------------------------
%%% @author admin
%%% @copyright (C) 2017, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. 五月 2017 下午3:39
%%%-------------------------------------------------------------------
-module(sentinel_client).
-include("eredis.hrl").
-author("admin").
%%-behaviour(gen_server).

-export([start_link/0,start/0,put/1,get/1]).
-spec start() -> {ok, Pid::pid()} | {error, Reason::term()}|no_connection.
start() ->
  Pid = spawn(fun() ->start_link() end),
  io:format("pid ~p~n",[Pid]),
  Pidm=spawn(fun() ->loop_monitor(Pid) end),
  Pid,
  io:format("pidm ~p~n",[Pid]).
start_link() ->
  Args = [[{host,"127.0.0.1"},{port,6385}],[{host,"127.0.0.1"},{port,6386}]],
  Result = start_link(Args),
  io:format("start_link ~p~n",[Result]),
  eredis:start_link(Result).
-spec start_link(server_args()) -> {ok, Pid::pid()} | {error, Reason::term()}|no_connection.

start_link([First|Rest])->
  io:format("first : ~p~n",[First]),
  Result_ = eredis:start_link(First),
  %%loop_monitor(Result_),
  case Result_ of
    {ok,C}->
      getIpAndPortOfMaster(C)
  end.

put(Commd)->
  {ok,C}=start_link(),
  eredis:q(C,Commd).
get(Commd)->
  {ok,C}=start_link(),
  eredis:q(C,Commd).

-spec loop_monitor(Pid::pid()) -> {ok, Pid::pid()} | {error, Reason::term()}|no_connection.
loop_monitor(Pid) ->
  _MonitorRef = erlang:monitor(process, Pid),
  receive
    Msg ->
      {Type,A,B,C,D} = Msg,
      io:format("d ~p--~n: ",[D]),
      case D of
        {connection_error,{connection_error,econnrefused}} ->
          io:format("conn ~p~n",[D]),
          Pid = start_link([[{host,"127.0.0.1"},{port,6386}]]),
          Pid;
        Other->
          io:format("pid : ~p~n", [Msg]),
          Pid
      end
  end.

getIpAndPortOfMaster(C)->
  {ok,Addr}=eredis:q(C, ["SENTINEL" ,"get-master-addr-by-name","mymaster"]),
  %%io:format("ip list ~w~n",binary_to_list(Addr)),
  [Ip|Rest] = Addr,
  [Port|[]]= Rest,
  IpT={host,binary_to_list(Ip)},
  PortT={port,list_to_integer(binary_to_list(Port))},
  Addrs=[[IpT],[PortT]],
  Result=[],
  splitIpAndPort(Addrs,Result).

%%splitIpAndPort([],Result)->
%%Result.
-spec splitIpAndPort(Args::list(),Result::list())->{ok,Pid::pid()}|{error, Reason::term()}.
splitIpAndPort(Args,Result) ->
  case Args of
    [] ->
      Result;
    Other ->
      [Firs|Rest]=Args,
      Result2 = lists:umerge(Result,Firs),

      io:format("#####~w ~w ~w~n",[Firs,Rest,Result2]),
      %%setelement(1,Result,binary_to_list(Firs)),
      splitIpAndPort(Rest,Result2)
  end.

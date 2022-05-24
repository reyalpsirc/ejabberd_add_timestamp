%% name of module must match file name
-module(mod_add_timestamp).
 
-author("Johan Vorster").
 
%% Every ejabberd module implements the gen_mod behavior
%% The gen_mod behavior requires two functions: start/2 and stop/1
-behaviour(gen_mod).
 
%% public methods for this module
-export([start/2, stop/1, filter_packet/1, reload/3,
         depends/2, mod_options/1]).

-record(servertime, {value}).
 
%% included for writing to ejabberd log file
-include("logger.hrl").

start(_Host, _Opt) -> 
    ?INFO_MSG("starting mod_add_timestamp", []),
    ejabberd_hooks:add(filter_packet, global, ?MODULE, filter_packet, 120).

stop(_Host) -> 
    ?INFO_MSG("stopping mod_add_timestamp", []),
    ejabberd_hooks:delete(filter_packet, global, ?MODULE, filter_packet, 120).

reload(_Host, _NewOpts, _OldOpts) ->
    ok.

filter_packet(Packet) ->
    ?INFO_MSG("filter_packet ~p~n", [Packet]),

    Type = xmpp:get_type(Packet),
    ?INFO_MSG("filter_packet Message Type ~p~n",[Type]),

    TimestampTag = fxml:get_subtag(fxml:to_xmlel(Packet), <<"servertime">>), 
    %% TimestampTag = fxml:get_path_s(Packet, [{elem, "servertime"}]), 
    ?INFO_MSG("filter_packet DataTag ~p~n",[TimestampTag]),

    %% Add timestamp to chat and chatgroup message and where no DataTag exist 
    if
        ((Type =:= chat) andalso TimestampTag =:= false) or (Type =:= groupchat andalso TimestampTag =:= false) ->
            Return = add_timestamp(Packet);
        true ->
            ?INFO_MSG("on_filter_packet Chat = False", []),
            Return = Packet,
            ?INFO_MSG("on_filter_packet ELSE Return ~p~n", [Return])
    end,
  

    ?INFO_MSG("filter_packet Return Value ~p~n", [Return]),

    Return.

add_timestamp(Packet) ->
    ?INFO_MSG("on_filter_packet Chat = True", []),
    From = xmpp:get_from(Packet),
    To = xmpp:get_to(Packet),
            
    Timestamp = now_to_microseconds(erlang:now()),
    ?INFO_MSG("on_filter_packet Timestamp ~p~n", [Timestamp]),

    FlatTimeStamp = lists:flatten(io_lib:format("~p", [Timestamp])),
    ?INFO_MSG("on_filter_packet FlatTimestamp ~p~n", [FlatTimeStamp]),

    TimeStampedPacket = xmpp:append_subtags(Packet, [#servertime{value = FlatTimeStamp}]),
    ejabberd_router:route(xmpp:set_from_to(TimeStampedPacket, From, To)),
    %% XMLTag = {xmlelement,"data", [{"timestamp", FlatTimeStamp}], []},
    %% TimeStampedPacket = fxml:decode(fxml:append_subtags(fxml:encode(Packet), [XMLTag])),
    %% ?INFO_MSG("on_filter_packet TimeStamped Packet ~p~n", [TimeStampedPacket]),

    ReturnPacket = TimeStampedPacket,
    ?INFO_MSG("on_filter_packet Return Packet ~p~n", [ReturnPacket]),

    Return = ReturnPacket,

    ?INFO_MSG("on_filter_packet TRUE Return ~p~n", [Return]),

    Return.
    
now_to_microseconds({Mega, Sec, Micro}) ->
    %%Epoch time in milliseconds from 1 Jan 1970
    ?INFO_MSG("now_to_milliseconds Mega ~p Sec ~p Micro ~p~n", [Mega, Sec, Micro]),
    (Mega*1000000 + Sec)*1000000 + Micro. 

depends(_Host, _Opts) ->
    [].

mod_options(_) ->
    [].


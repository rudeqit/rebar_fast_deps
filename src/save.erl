-module(save).
-behaviour(deps).

-export([
         save_all/1,
         do/5
        ]).

-include("rebar.hrl").

-spec save_all(Dir :: string()) -> ok | error.
save_all(Dir) ->
    {ok, Deps} = deps:foreach(Dir, ?MODULE, [], []),
    {ok, Conf} = file:consult(filename:join(Dir, ?REBAR_CFG)),
    NewDeps = lists:reverse(
                lists:foldl(fun deps_modifier/2, [], lists:sort(Deps))),
    NewConf = lists:keyreplace(deps, 1, Conf, {deps, NewDeps}),
    {ok, F} = file:open(filename:join(Dir, ?REBAR_SAVE_CFG), [write]),
    io:fwrite(F, "~s~n~n",
        ["%% THIS FILE IS GENERATED. DO NOT EDIT IT MANUALLY %%"]),
    [ io:fwrite(F, "~300p.~n", [Item]) || Item <- NewConf ],
    io:fwrite(F, "~s", ["\n"]),
    file:close(F).

deps_modifier({App, VSN, {git, Url}, Hash}, Acc) ->
    deps_modifier({App, VSN, {lock, Url}, Hash}, Acc);
deps_modifier({App, VSN, {git, Url, [raw]}, Hash}, Acc) ->
    deps_modifier({App, VSN, {lock, Url}, Hash}, Acc);
deps_modifier({App, VSN, {git, Url, {branch, _}}, Hash}, Acc) ->
    deps_modifier({App, VSN, {lock, Url}, Hash}, Acc);
deps_modifier({App, VSN, {git, Url, {branch, _}, [raw]}, Hash}, Acc) ->
    deps_modifier({App, VSN, {lock, Url}, Hash}, Acc);
deps_modifier({App, VSN, {git, Url, "", [raw]}, Hash}, Acc) ->
    deps_modifier({App, VSN, {lock, Url}, Hash}, Acc);
deps_modifier({App, VSN, {git, Url, "", Hash}}, Acc) ->
    deps_modifier({App, VSN, {lock, Url}, Hash}, Acc);
deps_modifier({App, VSN, {lock, Url}, Hash}, Acc) ->
    [ {App, VSN, {git, Url, Hash}} | Acc ];
deps_modifier({App, VSN, Source, _Res}, Acc) ->
    [ {App, VSN, Source} | Acc ].

do(Dir, App, VSN, Source, []) ->
    AppDir = filename:join(Dir, App),
    Cmd = "git rev-parse HEAD",
    {ok, Res} = updater:cmd(AppDir, Cmd, []),
    {accum, App, {App, VSN, Source, Res}}.

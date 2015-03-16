-module(branch).
-behaviour(deps).

-export([
         print/1,
         create/3,
         do/4
        ]).

-include("rebar.hrl").

print(Dir) ->
    {ok, Res} = deps:foreach(Dir, ?MODULE, []),
    UniqRes = lists:foldl(fun({_, _, Val, _, _}, Acc) ->
        lists:umerge(Val, Acc)
    end, [], Res),
    lists:foreach(fun(Val) ->
        case re:run(Val, "(.*)detached(.*)") of
            nomatch -> ?CONSOLE("~s", [Val]);
            _       -> none
        end
    end, lists:usort(UniqRes)).

create(Dir, Branch, IgnoredApp) ->
    {ok, Res1} = deps:foreach(Dir, ?MODULE, []),
    Res = lists:usort(Res1),
    {Hashs, Branches} = lists:foldl(fun({App, Branch1, _, Hash, _}, {Acc, Acc2}) ->
        {[{App, Hash} | Acc], [{App, Branch1} | Acc2]}
    end, {[], []}, Res),
    ?CONSOLE("~p ", [Branches]),
    % lists:foreach(
    %   fun({App, AppDir, _, _, false}) ->
    %           case lists:member(App, IgnoredApp) of
    %               true -> ok;
    %               % false -> cfg_modifier(AppDir, Branch, Hashs)
    %           end;
    %      (_) ->
    %           none
    % end, Res),
    % cfg_modifier(Dir, Branch, Hashs),
    ok.


cfg_modifier(AppDir, Branch, Hashs, Branches) ->
    case lists:member(Branch, Branches) of
        false ->
            Cmd = "git checkout -b ~s",
            {ok, _} = updater:cmd(AppDir, Cmd, [Branch]);
        true ->
            ?CONSOLE("Ignoring \e[31m~p\e[0m: already exist ~p", [AppDir, Branches])
    end,

    Name = filename:join(AppDir, ?REBAR_CFG),
    case file:consult(Name) of
        {ok, Conf} ->
            Deps = proplists:get_value(deps, Conf, []),
            {Res, _} = lists:foldl(
                    fun (Val, Acc) ->
                            AppStr = atom_to_list(element(1, Val)),
                            Hash = proplists:get_value(AppStr, Hashs),
                            deps_modifier(Val, Acc, Hash)
                    end, {[], Branch}, lists:sort(Deps)),
            change_deps(Res, Conf, Name, Branch, AppDir);
        {error, enoent} ->
            none
    end.

change_deps([], _Conf, _Name, _Branch, _AppDir) ->
    none;
change_deps(Deps, Conf, Name, Branch, AppDir) ->
  NewDeps = lists:reverse(Deps),
  NewConf = lists:keyreplace(deps, 1, Conf, {deps, NewDeps}),
  {ok, F} = file:open(Name, [write]),
  io:fwrite(F, "~s ~s ~s~n~n",
            ["%% THIS FILE IS GENERATED FOR", Branch, "%%"]),
  [ io:fwrite(F, "~p.~n", [Item]) || Item <- NewConf ],
  io:fwrite(F, "~s", ["\n"]),
  file:close(F),
  Cmd1 = "git commit -am 'Create release branches ~s'",
  updater:cmd(AppDir, Cmd1, [Branch]).

deps_modifier({App, VSN, {git, Url}}, Acc, Hash) ->
    deps_modifier({App, VSN, {git, Url, {branch, "HEAD"}}}, Acc, Hash);
deps_modifier({App, VSN, {git, Url, ""}}, Acc, Hash) ->
    deps_modifier({App, VSN, {git, Url, {branch, "HEAD"}}}, Acc, Hash);
deps_modifier({App, VSN, {git, Url, {branch, "master"}}}, Acc, Hash) ->
    deps_modifier({App, VSN, {git, Url, {branch, "HEAD"}}}, Acc, Hash);
deps_modifier({App, VSN, {git, Url, {branch, "HEAD"}}}, {Acc, Branch}, Hash) ->
    case re:run(Url, "(.*):external(.*)") of
        nomatch ->
            {[ {App, VSN, {git, Url, {branch, Branch}}} | Acc ], Branch};
        {match, _} ->
            {[ {App, VSN, {git, Url, Hash}} | Acc ], Branch}
    end;
deps_modifier(Dep, {Acc, Branch}, _Hash) ->
    {[ Dep | Acc ], Branch}.

do(Dir, App, _VSN, _Source) ->
    AppDir = filename:join(Dir, App),
    Cmd = "git --no-pager branch --all",
    Cmd2 = "git --no-pager log -1 --oneline --pretty=tformat:'%h'",
    Cmd3 = "git config --get remote.origin.url",
    {ok, Hash} = updater:cmd(AppDir, Cmd2, []),
    {ok, Url} = updater:cmd(AppDir, Cmd3, []),
    External = re:run(Url, "(.*):external(.*)") /= nomatch,
    {ok, Res1} = updater:cmd(AppDir, Cmd, []),
    Res = lists:foldl(
      fun(Val, Acc) ->
              [string:sub_string(Val, 3) | Acc]
      end, [], Res1),
    {accum, App, {erlang:atom_to_list(App), AppDir, Res, Hash, External}}.

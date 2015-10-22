-module(fd).

-export([
         main/1
        ]).

-include("rebar.hrl").

main(Args) ->
    io:setopts([{encoding, unicode}]),
    main_vrap(Args).

main_vrap([Command]) ->
    {ok, Dir} = file:get_cwd(),
    main_vrap([Dir, Command]);
main_vrap([WD, A]) when A == "push"; A == "ps" ->
    push:all([WD]);
main_vrap([WD, A]) when A == "update"; A == "up" ->
    updater:update_all([WD], ?REBAR_CFG);
main_vrap([WD, A]) when A == "status"; A == "st" ->
    checker:checker([WD]);
main_vrap([WD, A]) when A == "log"; A == "lg" ->
    log:show([WD]);
main_vrap([WD, A]) when A == "load"; A == "ld" ->
    updater:update_all([WD], ?REBAR_SAVE_CFG);
main_vrap([WD, A]) when A == "save"; A == "sa" ->
    save:save_all([WD]);
main_vrap([A | Args]) when A == "tag"; A == "tg"; A == "branch"; A == "br" ->
    {ok, Dir} = file:get_cwd(),
    main_vrap([Dir, A | Args]);
main_vrap([WD, A]) when A == "tag"; A == "tg" ->
    tag:print([WD]);
main_vrap([WD, A, Tag]) when A == "tag"; A == "tg" ->
    tag:create([WD], Tag, []);
main_vrap([WD, A, Tag, "--ignore" | IgnoredApp]) when A == "tag"; A == "tg" ->
    tag:create([WD], Tag, IgnoredApp);
main_vrap([A, WD, Tag]) when A == "tag"; A == "tg" ->
    tag:create([WD], Tag);
main_vrap([WD, A]) when A == "branch"; A == "br" ->
    branch:print([WD]);
main_vrap([WD, A, Name]) when A == "branch"; A == "br" ->
    branch:create([WD], Name, [], []);
main_vrap([WD, A, Name, "--ignore" | IgnoredApp]) when A == "branch"; A == "br" ->
    branch:create([WD], Name, IgnoredApp, []);
main_vrap([WD, A, Name, "--master_branch" | Branches]) when A == "branch"; A == "br" ->
    branch:create([WD], Name, [], Branches);
main_vrap([A, WD, Name]) when A == "branch"; A == "br" ->
    branch:create([WD], Name, []);
main_vrap(["help", _]) ->
    io:format("Usage: fd <command> [path] (fast deps)~n"
              "Commands:~n"
              "  update (up) - For update rebar deps~n"
              "  status (st) - Get status rebar deps~n"
              "  save   (sa) - For create rebar.config.save with deps on current state~n"
              "  load   (ld) - For load state from rebar.config.save~n"
              "  log    (lg) - Show deps log~n"
              "  branch (br) - List releases branches ~n"
              "  br release_2_14 --ignore folsom lagger - Create branch without ignores app~n"
              "  br release_2_14 --master_branch rc18~n"
              "  push   (ps) - For all modificate push~n"
              "  tag    (tg) - list tags~n"
              "  tag 0.0.0.1 --ignore folsom lagger - create tag 0.0.0.1 without ignores app~n");
main_vrap(Args) ->
    io:format("Command ~p not recognized.~n", [Args]),
    main_vrap(["help", aa]).

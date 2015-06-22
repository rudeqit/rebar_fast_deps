-module(fd).

-export([
         main/1
        ]).

-include("rebar.hrl").

main([Command]) ->
    {ok, Dir} = file:get_cwd(),
    main([Dir, Command]);
main([WD, A]) when A == "push"; A == "ps" ->
    push:all([WD]);
main([WD, A]) when A == "update"; A == "up" ->
    updater:update_all([WD], ?REBAR_CFG);
main([WD, A]) when A == "status"; A == "st" ->
    checker:checker([WD]);
main([WD, A]) when A == "log"; A == "lg" ->
    log:show([WD]);
main([WD, A]) when A == "load"; A == "ld" ->
    updater:update_all([WD], ?REBAR_SAVE_CFG);
main([WD, A]) when A == "save"; A == "sa" ->
    save:save_all([WD]);
main([A | Args]) when A == "tag"; A == "tg"; A == "branch"; A == "br" ->
    {ok, Dir} = file:get_cwd(),
    main([Dir, A | Args]);
main([WD, A]) when A == "tag"; A == "tg" ->
    tag:print([WD]);
main([WD, A, Tag]) when A == "tag"; A == "tg" ->
    tag:create([WD], Tag, []);
main([WD, A, Tag, "--ignore" | IgnoredApp]) when A == "tag"; A == "tg" ->
    tag:create([WD], Tag, IgnoredApp);
main([A, WD, Tag]) when A == "tag"; A == "tg" ->
    tag:create([WD], Tag);
main([WD, A]) when A == "branch"; A == "br" ->
    branch:print([WD]);
main([WD, A, Name]) when A == "branch"; A == "br" ->
    branch:create([WD], Name, [], []);
main([WD, A, Name, "--ignore" | IgnoredApp]) when A == "branch"; A == "br" ->
    branch:create([WD], Name, IgnoredApp, []);
main([WD, A, Name, "--master_branch" | Branches]) when A == "branch"; A == "br" ->
    branch:create([WD], Name, [], Branches);
main([A, WD, Name]) when A == "branch"; A == "br" ->
    branch:create([WD], Name, []);
main(["help", _]) ->
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
main(Args) ->
    io:format("Command ~p not recognized.~n", [Args]),
    main(["help", aa]).

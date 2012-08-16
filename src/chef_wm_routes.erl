%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92-*-
%% ex: ts=4 sw=4 et
%% @author Christopher Maier <cm@opscode.com>
%% @author Seth Falcon <seth@opscode.com>
%% @copyright 2011-2012 Opscode, Inc.
-module(chef_wm_routes).

-export([
         bulk_route_fun/2,
         bulk_route_fun/3,
         route/3
        ]).

-include_lib("webmachine/include/webmachine.hrl").


%% @doc Generate a function that produces URLs.  Use this when multiple URLs of the same
%% type must be produced at once to prevent the needless recomputation of static URL
%% information.
%% @end
%% Create a function that needs just the Role name to generate a URL.
bulk_route_fun(Type, Req) when Type =:= role;
                               Type =:= node;
                               Type =:= cookbook;
                               Type =:= environment;
                               Type =:= client;
                               Type =:= data_bag;
                               Type =:= data_bag_item ->
    BaseURI = chef_wm_util:base_uri(Req),
    Template = template_for_type(Type),
    fun(Name) ->
            render_template(Template, BaseURI, [Name])
    end;
%% Need to use this fun head instead of bulk_route_fun/3 for cookbook_versions in the case
%% that you need to generate URLs for versions of lots of different cookbooks at once,
%% instead of just for one cookbook.
bulk_route_fun(cookbook_version, Req) ->
    BaseURI = chef_wm_util:base_uri(Req),
    Template = template_for_type(cookbook_version),
    fun(CookbookName, VersionString) ->
            render_template(Template, BaseURI, [CookbookName, VersionString])
    end.

bulk_route_fun(Type, Name, Req) when Type =:= data_bag_item;
                                     Type =:= cookbook_version ->
    BaseURI = chef_wm_util:base_uri(Req),
    Template = template_for_type(Type),
    fun(SubName) ->
            render_template(Template, BaseURI, [Name, SubName])
    end.

%% @doc Generate a search URL.  Expects `Args' to be a proplist with a `search_index' key
%% (the value of which can be either a binary or string).  The organization in the URL will
%% be determined from the Webmachine request.
route(organization_search, Req, Args) ->
    %% Using pattern matching with lists:keyfind instead of just proplists:get_value just
    %% for extra sanity check
    {search_index, Index} = lists:keyfind(search_index, 1, Args),
    Template = "/search/~s",
    TemplateArgs = [Index],
    render_template(Template, Req, TemplateArgs);

%% Create a url for an individual role.  Requires a 'role_name' argument
route(node, Req, Args) -> route_rest_object("nodes", Req, Args);
route(role, Req, Args) -> route_rest_object("roles", Req, Args);
route(user, Req, Args) -> route_rest_object("users", Req, Args);
route(data_bag, Req, Args) -> route_rest_object("data", Req, Args);
route(environment, Req, Args) -> route_rest_object("environments", Req, Args);
route(client, Req, Args) -> route_rest_object("clients", Req, Args);
route(sandbox, Req, Args) ->
    {id, Id} = lists:keyfind(id, 1, Args),
    Template = "/sandboxes/~s",
    TemplateArgs = [ Id],
    render_template(Template, Req, TemplateArgs);
route(cookbook_version, Req, Args) ->
    {name, Name} = lists:keyfind(name, 1, Args),
    %% FIXME: maybe just pull out name and version from req
    %% FIXME: this is wrong, but need something here
    Template = "/cookbooks/~s",
    TemplateArgs = [Name],
    {name, Name} = lists:keyfind(name, 1, Args),
    render_template(Template, Req, TemplateArgs).

%% @doc utility method for generating a binary from a template and arguments.  The protocol
%% and host are derived from the Webmachine request via our own magic in `chef_wm_util',
%% since Webmachine doesn't do this for us.  As a result, the `template' should be for just
%% the path of the desired URL (including the leading "/" character!).  Thus, a "good"
%% template might be
%%
%%  "/organizations/~s/search/~s"
%%
render_template(Template, BaseURI, Args) when is_list(BaseURI) ->
    iolist_to_binary(BaseURI ++ io_lib:format(Template, Args));
render_template(Template, Req, Args) ->
    render_template(Template, chef_wm_util:base_uri(Req), Args).

route_rest_object(ParentName, Req, Args) ->
    {name, Name} = lists:keyfind(name, 1, Args),
    Template = "/~s/~s",
    TemplateArgs = [ParentName, Name],
    render_template(Template, Req, TemplateArgs).

template_for_type(node) ->
    "/nodes/~s";
template_for_type(role) ->
    "/roles/~s";
template_for_type(cookbook) ->
    "/cookbooks/~s";
template_for_type(cookbook_version) ->
    "/cookbooks/~s/~s";
template_for_type(environment) ->
    "/environments/~s";
template_for_type(client) ->
    "/clients/~s";
template_for_type(data_bag) ->
    "/data/~s";
template_for_type(data_bag_item) ->
    "/data/~s/~s".

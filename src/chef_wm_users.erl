%% -*- erlang-indent-level: 4;indent-tabs-mode: nil; fill-column: 92 -*-
%% ex: ts=4 sw=4 et
%% @author Mark Mzyk <mmzyk@opscode.com>
%% @copyright 2012 Opscode, Inc.

%% @doc Resource module for Chef users endpoint

-module(chef_wm_users).

-include("chef_wm.hrl").

-mixin([{chef_wm_base, [content_types_accepted/2,
                        content_types_provided/2,
                        finish_request/2,
                        malformed_request/2,
                        ping/2,
                        post_is_create/2]}]).

-mixin([{?BASE_RESOURCE, [forbidden/2,
                          is_authorized/2,
                          service_available/2]}]).

-behavior(chef_wm).
-export([auth_info/2,
         init/1,
         init_resource_state/1,
         malformed_request_message/3,
         request_type/0,
         validate_request/3]).

-export([allowed_methods/2,
         create_path/2,
         from_json/2,
         resource_exits/2,
         to_json/2]).

init(Config) ->
  chef_wm_base:init(?MODULE, Config).

%% Need to add the user_state
init_resource_state(_Config) ->
  {ok, #user_state{}}.

request_type() ->
  "users".

allowed_methods(Req, State) ->
  {['POST'], Req, State}.

validate_request('POST', Req, #base_state{resource_state = UserState} = State) ->
  Body = wrq:req_body(Req),
  {ok, UserData} = chef_user:parse_binary_json(Body, create),
  {Req, State#base_state{resource_state = UserState#user_state{user_data = UserData}}}.

%% For now, authorize everything, as there are no restrictions for
%% creation in open source around create
%% Might want to check if user is an admin in certain cases
%% Will need to revise for update, other actions
%% Most user perms in open source are controlled through webui
auth_info(Req, State) ->
  {authorized, Req, State}.

%% If we get here, are we guarenteed the user exists?
resource_exists(Req, State) ->
  {true, Req, State}.

%% What is the purpose of this method?
create_path(Req, #base_state{resource_state = #user_state{user_data = UserData}} = State) ->
  Name = ej:get({<<"name">>}, UserData),
  {binary_to_list(Name), Req, State}.

from_json(Req, #base_state{resource_state = #user_state{user_data = UserData, user_authz_id = AuthzId}} = State) ->
  chef_wm_base:create_from_json(Req, State, chef_user, {authz_id, AuthzId}, UserData).

%% Need to write function to be called here
to_json(Req, State) ->
  filler.



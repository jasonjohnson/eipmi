%%%=============================================================================
%%% Copyright (c) 2012 Lindenbaum GmbH
%%%
%%% Permission to use, copy, modify, and/or distribute this software for any
%%% purpose with or without fee is hereby granted, provided that the above
%%% copyright notice and this permission notice appear in all copies.
%%%
%%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%%% ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%%% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
%%%
%%% @doc
%%% A module providing decoding functionality for the data parts of IPMI
%%% responses.
%%% @end
%%%=============================================================================

-module(eipmi_response).

-export([decode/2]).

-include("eipmi.hrl").

%%%=============================================================================
%%% API
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @doc
%% Decodes IPMI responses according to the concrete command code, returning a
%% property list with the decoded values.
%% @end
%%------------------------------------------------------------------------------
decode(?GET_CHANNEL_AUTHENTICATION_CAPABILITIES,
       <<_:8, 0:1, _:1, A:6, ?EIPMI_RESERVED:3, P:1, _:1, L:3, ?EIPMI_RESERVED:40>>) ->
    [?AUTH_TYPES(get_auth_types(A)),
     ?PER_MSG_ENABLED(to_bool(P)),
     ?LOGIN_STATUS(get_login_status(L))];

decode(?GET_SESSION_CHALLENGE, <<I:32/little, C/binary>>) ->
    [?SESSION_ID(I), ?CHALLENGE(C)];

decode(?ACTIVATE_SESSION,
       <<?EIPMI_RESERVED:4, A:4, I:32/little, S:32/little, ?EIPMI_RESERVED:4, P:4>>) ->
    [?AUTH_TYPE(eipmi_auth:decode_type(A)),
     ?SESSION_ID(I),
     ?INBOUND_SEQ_NR(S),
     ?PRIVILEGE(decode_privilege(P))];

decode(?CLOSE_SESSION, <<>>) ->
    [];

decode(_Cmd, _Binary) ->
    [].

%%%=============================================================================
%%% internal functions
%%%=============================================================================

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
to_bool(0) -> true;
to_bool(1) -> false.

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
get_auth_types(AuthTypes) ->
    A = case AuthTypes band 2#10000 of 2#10000 -> [pwd]; _ -> [] end,
    B = case AuthTypes band 2#100 of 2#100 -> [md5]; _ -> [] end,
    C = case AuthTypes band 2#10 of 2#10 -> [md2]; _ -> [] end,
    D = case AuthTypes band 2#1 of 2#1 -> [none]; _ -> [] end,
    A ++ B ++ C ++ D.

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
get_login_status(LoginStatus) ->
    A = case LoginStatus band 2#100 of 2#100 -> [non_null]; _ -> [] end,
    B = case LoginStatus band 2#10 of 2#10 -> [null]; _ -> [] end,
    C = case LoginStatus band 2#1 of 2#1 -> [anonymous]; _ -> [] end,
    A ++ B ++ C.

%%------------------------------------------------------------------------------
%% @private
%%------------------------------------------------------------------------------
decode_privilege(1) -> callback;
decode_privilege(2) -> user;
decode_privilege(3) -> operator;
decode_privilege(4) -> administrator.
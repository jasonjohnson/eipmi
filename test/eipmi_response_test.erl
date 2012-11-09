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
%%%=============================================================================

-module(eipmi_response_test).

-include_lib("eunit/include/eunit.hrl").

-include("eipmi.hrl").

%%%=============================================================================
%%% TESTS
%%%=============================================================================

decode_get_device_id_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?GET_DEVICE_ID},
    Bin = <<16#00, 16#82, 16#02, 16#0d, 16#51, 16#3e, 16#78, 16#6c, 16#00,
            16#03, 16#0b, 16#00, 16#00, 16#00, 16#00>>,
    Properties = eipmi_response:decode(Resp, Bin),
    ?assertEqual(0, eipmi_util:get_val(device_id, Properties)),
    ?assertEqual(2, eipmi_util:get_val(device_revision, Properties)),
    ?assertEqual(normal, eipmi_util:get_val(operation, Properties)),
    ?assertEqual("2.13", eipmi_util:get_val(firmware_version, Properties)),
    ?assertEqual("1.5", eipmi_util:get_val(ipmi_version, Properties)),
    ?assertEqual([event_generator, event_receiver, fru_inventory, sel, sdr],
                 eipmi_util:get_val(device_support, Properties)),
    ?assertEqual(27768, eipmi_util:get_val(manufacturer_id, Properties)),
    ?assertEqual(2819, eipmi_util:get_val(product_id, Properties)).

decode_cold_reset_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?COLD_RESET},
    Bin = <<>>,
    ?assertEqual([], eipmi_response:decode(Resp, Bin)).

decode_warm_reset_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?WARM_RESET},
    Bin = <<>>,
    ?assertEqual([], eipmi_response:decode(Resp, Bin)).

decode_get_self_test_results_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?GET_SELF_TEST_RESULTS},
    Bin = <<16#57, 16#ff>>,
    ?assertEqual(
       [{result,
         {{corrupted_devices,
           [sel, sdr, fru, ipmb_signal_lines]},
          {inaccessible_devices,
           [sdr, fru, boot_firmware, optional_firmware]}}}],
       eipmi_response:decode(Resp, Bin)).

decode_get_acpi_power_state_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?GET_ACPI_POWER_STATE},
    Bin = <<16#00, 16#01>>,
    ?assertEqual(
       [{system, {s0_g0, working}}, {device, d1}],
       eipmi_response:decode(Resp, Bin)).

decode_get_device_guid_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?GET_DEVICE_GUID},
    Bin = <<$h, $e, $l, $l, $o>>,
    Properties = eipmi_response:decode(Resp, Bin),
    ?assertEqual("hello", eipmi_util:get_val(guid, Properties)).

decode_get_system_guid_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?GET_SYSTEM_GUID},
    Bin = <<$h, $e, $l, $l, $o>>,
    Properties = eipmi_response:decode(Resp, Bin),
    ?assertEqual("hello", eipmi_util:get_val(guid, Properties)).

decode_get_channel_authentication_capabilities_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?GET_CHANNEL_AUTHENTICATION_CAPABILITIES},
    Bin = <<16#00, 16#17, 16#1f, 16#00, 16#00, 16#00, 16#00, 16#00>>,
    Properties = eipmi_response:decode(Resp, Bin),
    ?assertEqual([pwd, md5, md2, none],
                 eipmi_util:get_val(auth_types, Properties)),
    ?assertEqual([non_null, null, anonymous],
                 eipmi_util:get_val(login_status, Properties)).

decode_get_session_challenge_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?GET_SESSION_CHALLENGE},
    Bin = <<16#44, 16#33, 16#22, 16#11, $h, $e, $l, $l, $o, $_, $w, $o, $r,
            $l, $d, 16#00, 16#00, 16#00, 16#00, 16#00>>,
    Properties = eipmi_response:decode(Resp, Bin),
    ?assertEqual(16#11223344, eipmi_util:get_val(session_id, Properties)),
    ?assertEqual(<<$h, $e, $l, $l, $o, $_, $w, $o, $r, $l, $d,
                   16#00, 16#00, 16#00, 16#00, 16#00>>,
                 eipmi_util:get_val(challenge, Properties)).

decode_activate_session_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?ACTIVATE_SESSION},
    Bin = <<16#00, 16#44, 16#33, 16#22, 16#11, 16#88, 16#77, 16#66, 16#55, 16#04>>,
    Properties = eipmi_response:decode(Resp, Bin),
    ?assertEqual(none, eipmi_util:get_val(auth_type, Properties)),
    ?assertEqual(16#11223344, eipmi_util:get_val(session_id, Properties)),
    ?assertEqual(16#55667788, eipmi_util:get_val(inbound_seq_nr, Properties)),
    ?assertEqual(administrator, eipmi_util:get_val(privilege, Properties)).

decode_set_session_privilege_level_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?SET_SESSION_PRIVILEGE_LEVEL},
    Bin = <<16#04>>,
    Properties = eipmi_response:decode(Resp, Bin),
    ?assertEqual(administrator, eipmi_util:get_val(privilege, Properties)).

decode_close_session_test() ->
    Resp = {?IPMI_NETFN_APPLICATION_RESPONSE, ?CLOSE_SESSION},
    Bin = <<>>,
    ?assertEqual([], eipmi_response:decode(Resp, Bin)).

decode_get_fru_inventory_area_info_test() ->
    Resp = {?IPMI_NETFN_STORAGE_RESPONSE, ?GET_FRU_INVENTORY_AREA_INFO},
    Bin = <<16#22, 16#11, 16#00>>,
    ?assertEqual(
       [{area_size, 16#1122}, {access, by_bytes}],
       eipmi_response:decode(Resp, Bin)).

decode_read_fru_data_test() ->
    Resp = {?IPMI_NETFN_STORAGE_RESPONSE, ?READ_FRU_DATA},
    Bin = <<5, $h, $e, $l, $l, $o>>,
    ?assertEqual(
       [{count, 5}, {data, <<$h, $e, $l, $l, $o>>}],
       eipmi_response:decode(Resp, Bin)).

decode_get_sel_info_test() ->
    Resp = {?IPMI_NETFN_STORAGE_RESPONSE, ?GET_SEL_INFO},
    Bin = <<16#51, 16#01, 16#00, 16#ff, 16#ff, 16#44, 16#33, 16#22, 16#11,
            16#44, 16#33, 16#22, 16#11, 16#8f>>,
    ?assertEqual(
       [{version, "15"}, {entries, 1}, {free_space, 16#ffff},
        {most_recent_addition, 16#11223344},
        {most_recent_erase, 16#11223344},
        {overflow, true},
        {operations, [delete, partial_add, reserve, get_allocation_info]}],
       eipmi_response:decode(Resp, Bin)).

decode_reserve_sel_test() ->
    Resp = {?IPMI_NETFN_STORAGE_RESPONSE, ?RESERVE_SEL},
    Bin = <<16#22, 16#11>>,
    ?assertEqual(
       [{reservation_id, 16#1122}],
       eipmi_response:decode(Resp, Bin)).

decode_get_sel_entry_test() ->
    Resp = {?IPMI_NETFN_STORAGE_RESPONSE, ?GET_SEL_ENTRY},
    Bin = <<16#22, 16#11, $d, $a, $t, $a>>,
    ?assertEqual(
       [{next_record_id, 16#1122},
        {data, <<$d, $a, $t, $a>>}],
       eipmi_response:decode(Resp, Bin)).

decode_clear_sel_test() ->
    Resp = {?IPMI_NETFN_STORAGE_RESPONSE, ?CLEAR_SEL},
    Bin = <<16#01>>,
    ?assertEqual([{progress, completed}], eipmi_response:decode(Resp, Bin)).

decode_get_ip_udp_rmcp_statistics_test() ->
    Resp = {?IPMI_NETFN_TRANSPORT_RESPONSE, ?GET_IP_UDP_RMCP_STATISTICS},
    Bin = <<16#01, 16#02, 16#03, 16#04, 16#05, 16#06, 16#07, 16#08, 16#09, 16#a,
            16#01, 16#02, 16#03, 16#04, 16#05, 16#06, 16#07, 16#08>>,
    ?assertEqual(
       [{ip_packets_received, 16#0201},
        {ip_header_errors, 16#0403},
        {ip_address_errors, 16#0605},
        {ip_fragmented_packets_received, 16#0807},
        {ip_packets_transmitted, 16#0a09},
        {udp_packets_received, 16#0201},
        {udp_proxy_packets_received, 16#0605},
        {udp_proxy_packets_dropped, 16#0807},
        {rmcp_packets_received, 16#0403}],
       eipmi_response:decode(Resp, Bin)).

decode_get_lan_configuration_parameters_test() ->
    Resp = {?IPMI_NETFN_TRANSPORT_RESPONSE, ?GET_LAN_CONFIGURATION_PARAMETERS},
    Bin = <<16#00, $d, $a, $t, $a>>,
    ?assertEqual([{data, <<$d, $a, $t, $a>>}], eipmi_response:decode(Resp, Bin)).

decode_get_sdr_repository_info_test() ->
    Resp = {?IPMI_NETFN_STORAGE_RESPONSE, ?GET_SDR_REPOSITORY_INFO},
    Bin = <<16#51, 16#01, 16#00, 16#ff, 16#ff, 16#44, 16#33, 16#22, 16#11,
            16#44, 16#33, 16#22, 16#11, 16#8f>>,
    ?assertEqual(
       [{version, "15"}, {entries, 1}, {free_space, 16#ffff},
        {most_recent_addition, 16#11223344},
        {most_recent_erase, 16#11223344},
        {overflow, true},
        {operations, [delete, partial_add, reserve, get_allocation_info]}],
       eipmi_response:decode(Resp, Bin)).

decode_reserve_sdr_repository_test() ->
    Resp = {?IPMI_NETFN_STORAGE_RESPONSE, ?RESERVE_SDR_REPOSITORY},
    Bin = <<16#22, 16#11>>,
    ?assertEqual(
       [{reservation_id, 16#1122}],
       eipmi_response:decode(Resp, Bin)).

decode_get_sdr_test() ->
    Resp = {?IPMI_NETFN_STORAGE_RESPONSE, ?GET_SDR},
    Bin = <<16#22, 16#11, $d, $a, $t, $a>>,
    ?assertEqual(
       [{next_record_id, 16#1122},
        {data, <<$d, $a, $t, $a>>}],
       eipmi_response:decode(Resp, Bin)).
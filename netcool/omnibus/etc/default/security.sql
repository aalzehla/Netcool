------------------------------------------------------------------------
--
--      Licensed Materials - Property of IBM
--
--      5724O4800
--
--      (C) Copyright IBM Corp. 1994, 2014. All Rights Reserved
--
--      US Government Users Restricted Rights - Use, duplication
--      or disclosure restricted by GSA ADP Schedule Contract
--      with IBM Corp.
--
------------------------------------------------------------------------

------------------------------------------------------------------------
--
-- 	Roles for reading catalog-like tables
--
------------------------------------------------------------------------

create role 'CatalogUser' comment 'Standard role for reading the catalog';
grant select on table catalog.tables to role 'CatalogUser';
grant select on table catalog.primitive_signal_parameters to role 'CatalogUser';
grant select on table catalog.trigger_groups to role 'CatalogUser';
grant select on table catalog.memstores to role 'CatalogUser';
grant select on table catalog.primitive_signals to role 'CatalogUser';
grant select on table catalog.procedures to role 'CatalogUser';
grant select on table catalog.files to role 'CatalogUser';
grant select on table catalog.database_triggers to role 'CatalogUser';
grant select on table catalog.signal_triggers to role 'CatalogUser';
grant select on table catalog.trigger_stats to role 'CatalogUser';
grant select on table catalog.procedure_parameters to role 'CatalogUser';
grant select on table catalog.columns to role 'CatalogUser';
grant select on table catalog.external_procedures to role 'CatalogUser';
grant select on table catalog.views to role 'CatalogUser';
grant select on table catalog.triggers to role 'CatalogUser';
grant select on table catalog.properties to role 'CatalogUser';
grant select on table catalog.connections to role 'CatalogUser';
grant select on table catalog.databases to role 'CatalogUser';
grant select on table catalog.stores to role 'CatalogUser';
grant select on table catalog.base_tables to role 'CatalogUser';
grant select on table catalog.sql_procedures to role 'CatalogUser';
grant select on table catalog.temporal_triggers to role 'CatalogUser';
grant select on table catalog.profiles to role 'CatalogUser';
grant select on table catalog.restrictions to role 'CatalogUser';
grant select on table catalog.security_permissions to role 'CatalogUser';
grant select on table catalog.indexes to role 'CatalogUser';
grant select on table tools.actions to role 'CatalogUser';
grant select on table tools.action_access to role 'CatalogUser';
grant select on table tools.menus to role 'CatalogUser';
grant select on table tools.menu_items to role 'CatalogUser';
grant select on table tools.menu_defs to role 'CatalogUser';
grant select on table tools.prompt_defs to role 'CatalogUser';
grant select on table security.users to role 'CatalogUser';
grant select on table security.roles to role 'CatalogUser';
grant select on table security.role_grants to role 'CatalogUser';
grant select on table security.owners to role 'CatalogUser';
grant select on table security.permissions to role 'CatalogUser';
grant select on table security.groups to role 'CatalogUser';
grant select on table security.group_members to role 'CatalogUser';
grant select on table security.restriction_filters to role 'CatalogUser';
grant select on view master.names to role 'CatalogUser';
grant select on view master.groups to role 'CatalogUser';
grant select on table master.profiles to role 'CatalogUser';
grant select on view master.members to role 'CatalogUser';
grant select on table master.permissions to role 'CatalogUser';
grant select on table master.servergroups to role 'CatalogUser';
go

create role 'AlertsUser' comment 'Alerts database user';
grant select on table alerts.status to role 'AlertsUser';
grant select on table alerts.details to role 'AlertsUser';
grant select on table alerts.journal to role 'AlertsUser';
grant select on table service.status to role 'AlertsUser';
grant select on table alerts.col_visuals to role 'AlertsUser';
grant select on table alerts.objclass to role 'AlertsUser';
grant select on table alerts.conversions to role 'AlertsUser';
grant select on table alerts.colors to role 'AlertsUser';
grant select on table alerts.objmenuitems to role 'AlertsUser';
grant select on table alerts.objmenus to role 'AlertsUser';
grant select on table alerts.resolutions to role 'AlertsUser';
grant select on table alerts.iduc_messages to role 'AlertsUser';
grant create view on database alerts to role 'AlertsUser';
grant update on table alerts.status to role 'AlertsUser';
grant delete on table alerts.status to role 'AlertsUser';
grant insert on table alerts.journal to role 'AlertsUser';
grant delete on table alerts.journal to role 'AlertsUser';
grant delete on table alerts.details to role 'AlertsUser';
grant update on table service.status to role 'AlertsUser';
grant delete on table service.status to role 'AlertsUser';
grant insert on table master.profiles to role 'AlertsUser';
grant delete on table master.profiles to role 'AlertsUser';
grant insert on table master.permissions to role 'AlertsUser';
go

create role 'AlertsProbe' comment 'Probe with insert acccess to alerts database';
grant insert on table alerts.status to role 'AlertsProbe';
grant update on table alerts.status to role 'AlertsProbe';
grant insert on table alerts.details to role 'AlertsProbe';
grant insert on table service.status to role 'AlertsProbe';
go

create role 'AlertsGateway' comment 'Gateway with access to alert database';
grant insert on table alerts.status to role 'AlertsGateway';
grant update on table alerts.status to role 'AlertsGateway';
grant delete on table alerts.status to role 'AlertsGateway';
grant insert on table alerts.details to role 'AlertsGateway';
grant update on table alerts.details to role 'AlertsGateway';
grant delete on table alerts.details to role 'AlertsGateway';
grant insert on table alerts.journal to role 'AlertsGateway';
grant update on table alerts.journal to role 'AlertsGateway';
grant delete on table alerts.journal to role 'AlertsGateway';
grant insert on table service.status to role 'AlertsGateway';
grant update on table service.status to role 'AlertsGateway';
grant delete on table service.status to role 'AlertsGateway';
grant insert on table transfer.users to role 'AlertsGateway';
grant select on table transfer.users to role 'AlertsGateway';
grant insert on table transfer.users to role 'AlertsGateway';
grant update on table transfer.users to role 'AlertsGateway';
grant delete on table transfer.users to role 'AlertsGateway';
grant select on table transfer.roles to role 'AlertsGateway';
grant insert on table transfer.roles to role 'AlertsGateway';
grant update on table transfer.roles to role 'AlertsGateway';
grant delete on table transfer.roles to role 'AlertsGateway';
grant select on table transfer.role_grants to role 'AlertsGateway';
grant insert on table transfer.role_grants to role 'AlertsGateway';
grant update on table transfer.role_grants to role 'AlertsGateway';
grant delete on table transfer.role_grants to role 'AlertsGateway';
grant select on table transfer.permissions to role 'AlertsGateway';
grant insert on table transfer.permissions to role 'AlertsGateway';
grant update on table transfer.permissions to role 'AlertsGateway';
grant delete on table transfer.permissions to role 'AlertsGateway';
grant select on table transfer.groups to role 'AlertsGateway';
grant insert on table transfer.groups to role 'AlertsGateway';
grant update on table transfer.groups to role 'AlertsGateway';
grant delete on table transfer.groups to role 'AlertsGateway';
grant select on table transfer.group_members to role 'AlertsGateway';
grant insert on table transfer.group_members to role 'AlertsGateway';
grant update on table transfer.group_members to role 'AlertsGateway';
grant delete on table transfer.group_members to role 'AlertsGateway';
grant select on table transfer.restrictions to role 'AlertsGateway';
grant insert on table transfer.restrictions to role 'AlertsGateway';
grant update on table transfer.restrictions to role 'AlertsGateway';
grant delete on table transfer.restrictions to role 'AlertsGateway';
grant select on table transfer.security_restrictions to role 'AlertsGateway';
grant insert on table transfer.security_restrictions to role 'AlertsGateway';
grant update on table transfer.security_restrictions to role 'AlertsGateway';
grant delete on table transfer.security_restrictions to role 'AlertsGateway';
grant select on table tools.menus to role 'AlertsGateway';
grant select on table tools.menu_items to role 'AlertsGateway';
grant select on table tools.actions to role 'AlertsGateway';
grant select on table tools.action_access to role 'AlertsGateway';
grant select on table tools.menu_defs to role 'AlertsGateway';
grant select on table tools.prompt_defs to role 'AlertsGateway';
grant select on table alerts.conversions to role 'AlertsGateway';
grant select on table alerts.col_visuals to role 'AlertsGateway';
grant select on table alerts.colors to role 'AlertsGateway';
grant insert on table tools.menus to role 'AlertsGateway';
grant insert on table tools.menu_items to role 'AlertsGateway';
grant insert on table tools.actions to role 'AlertsGateway';
grant insert on table tools.action_access to role 'AlertsGateway';
grant insert on table tools.menu_defs to role 'AlertsGateway';
grant insert on table tools.prompt_defs to role 'AlertsGateway';
grant insert on table alerts.conversions to role 'AlertsGateway';
grant insert on table alerts.col_visuals to role 'AlertsGateway';
grant insert on table alerts.colors to role 'AlertsGateway';
grant update on table tools.menus to role 'AlertsGateway';
grant update on table tools.menu_items to role 'AlertsGateway';
grant update on table tools.actions to role 'AlertsGateway';
grant update on table tools.action_access to role 'AlertsGateway';
grant update on table tools.menu_defs to role 'AlertsGateway';
grant update on table tools.prompt_defs to role 'AlertsGateway';
grant update on table alerts.conversions to role 'AlertsGateway';
grant update on table alerts.col_visuals to role 'AlertsGateway';
grant update on table alerts.colors to role 'AlertsGateway';
grant delete on table tools.menus to role 'AlertsGateway';
grant delete on table tools.menu_items to role 'AlertsGateway';
grant delete on table tools.actions to role 'AlertsGateway';
grant delete on table tools.action_access to role 'AlertsGateway';
grant delete on table tools.menu_defs to role 'AlertsGateway';
grant delete on table tools.prompt_defs to role 'AlertsGateway';
grant delete on table alerts.conversions to role 'AlertsGateway';
grant delete on table alerts.col_visuals to role 'AlertsGateway';
grant delete on table alerts.colors to role 'AlertsGateway';
grant select on table master.servergroups to role 'AlertsGateway';
grant insert on table master.servergroups to role 'AlertsGateway';
grant update on table master.servergroups to role 'AlertsGateway';
grant delete on table master.servergroups to role 'AlertsGateway';
grant raise on signal gw_counterpart_down to role 'AlertsGateway';
grant raise on signal gw_counterpart_up to role 'AlertsGateway';
grant raise on signal gw_resync_start  to role 'AlertsGateway';
grant raise on signal gw_resync_finish  to role 'AlertsGateway';
grant select on table iduc_system.iduc_stats to role 'AlertsGateway';
grant insert on table iduc_system.iduc_stats to role 'AlertsGateway';
grant update on table iduc_system.iduc_stats to role 'AlertsGateway';
grant delete on table iduc_system.iduc_stats to role 'AlertsGateway';


go

create role 'ChannelUser' comment 'Notification channel database user';
grant select on table iduc_system.channel to role 'ChannelUser';
grant select on table iduc_system.channel_interest to role 'ChannelUser';
grant select on table iduc_system.channel_summary to role 'ChannelUser';
grant select on table iduc_system.channel_summary_cols to role 'ChannelUser';
grant select on table catalog.tables to role 'ChannelUser';
grant select on table catalog.columns to role 'ChannelUser';
grant select on table security.groups to role 'ChannelUser';
grant select on table security.group_members to role 'ChannelUser';
grant select on table alerts.conversions to role 'ChannelUser';
grant select on table alerts.objclass to role 'ChannelUser';
go

create role 'RegisterProbe' comment 'Probe registration';
grant insert on table registry.probes to role 'RegisterProbe';
grant update on table registry.probes to role 'RegisterProbe';
go

create role 'RegistryReader' comment 'Access the registry';
grant select on table registry.probes to role 'RegistryReader';

go

create role 'RegistryAdmin' comment 'Registry data administration';
grant insert on table registry.probes to role 'RegistryAdmin';
grant update on table registry.probes to role 'RegistryAdmin';
grant select on table registry.probes to role 'RegistryAdmin';
grant delete on table registry.probes to role 'RegistryAdmin';
go

-------------------------------------------------------------------------------------
--
--	Roles for administering subsystems
--
-------------------------------------------------------------------------------------

-- Database administration
create role 'DatabaseAdmin' comment 'Database administration';
grant create database to role 'DatabaseAdmin';
grant create file to role 'DatabaseAdmin';
grant create memstore to role 'DatabaseAdmin';
go

grant create table on database alerts to role 'DatabaseAdmin';
grant create table on database tools to role 'DatabaseAdmin';
grant create table on database service to role 'DatabaseAdmin';
grant create table on database registry to role 'DatabaseAdmin';
go

grant alter on table alerts.status to role 'DatabaseAdmin'; 
grant alter on table alerts.journal to role 'DatabaseAdmin';
grant alter on table alerts.details to role 'DatabaseAdmin';
grant alter on table service.status to role 'DatabaseAdmin';
grant alter on table registry.probes to role 'DatabaseAdmin';
grant drop on table alerts.status to role 'DatabaseAdmin'; 
grant drop on table alerts.journal to role 'DatabaseAdmin';
grant drop on table alerts.details to role 'DatabaseAdmin';
grant drop on table service.status to role 'DatabaseAdmin';
grant drop on table registry.probes to role 'DatabaseAdmin';
go

grant create index on table alerts.status to role 'DatabaseAdmin';
grant create index on table alerts.journal to role 'DatabaseAdmin';
grant create index on table alerts.details to role 'DatabaseAdmin';
grant create index on table registry.probes to role 'DatabaseAdmin';
grant drop index on table alerts.status to role 'DatabaseAdmin';
grant drop index on table alerts.journal to role 'DatabaseAdmin';
grant drop index on table alerts.details to role 'DatabaseAdmin';
grant drop index on table registry.probes to role 'DatabaseAdmin';
go

-- Automation administration
create role 'AutoAdmin' comment 'Automation administration';
grant create trigger group to role 'AutoAdmin';
grant create file to role 'AutoAdmin';
grant create sql procedure to role 'AutoAdmin';
grant create external procedure to role 'AutoAdmin';
grant create signal to role 'AutoAdmin';
go


grant create trigger on trigger group system_watch to role 'AutoAdmin';
grant create trigger on trigger group default_triggers to role 'AutoAdmin';
grant create trigger on trigger group security_watch to role 'AutoAdmin';
grant create trigger on trigger group connection_watch to role 'AutoAdmin';
grant create trigger on trigger group compatibility_triggers to role 'AutoAdmin';
grant create trigger on trigger group audit_config to role 'AutoAdmin';
grant create trigger on trigger group profiler_triggers to role 'AutoAdmin';
grant create trigger on trigger group trigger_stat_reports to role 'AutoAdmin';
grant create trigger on trigger group stats_triggers to role 'AutoAdmin';
grant create trigger on trigger group automatic_backup_system to role 'AutoAdmin';
grant create trigger on trigger group registry_triggers to role 'AutoAdmin';
grant alter on trigger group system_watch to role 'AutoAdmin';
grant alter on trigger group connection_watch to role 'AutoAdmin';
grant alter on trigger group security_watch to role 'AutoAdmin';
grant alter on trigger group default_triggers to role 'AutoAdmin';
grant alter on trigger group compatibility_triggers to role 'AutoAdmin';
grant alter on trigger group audit_config to role 'AutoAdmin';
grant alter on trigger group profiler_triggers to role 'AutoAdmin';
grant alter on trigger group trigger_stat_reports to role 'AutoAdmin';
grant alter on trigger group stats_triggers to role 'AutoAdmin';
grant alter on trigger group automatic_backup_system to role 'AutoAdmin';
grant alter on trigger group registry_triggers to role 'AutoAdmin';
grant drop on trigger group system_watch to role 'AutoAdmin';
grant drop on trigger group connection_watch to role 'AutoAdmin';
grant drop on trigger group security_watch to role 'AutoAdmin';
grant drop on trigger group default_triggers to role 'AutoAdmin';
grant drop on trigger group compatibility_triggers to role 'AutoAdmin';
grant drop on trigger group audit_config to role 'AutoAdmin';
grant drop on trigger group profiler_triggers to role 'AutoAdmin';
grant drop on trigger group trigger_stat_reports to role 'AutoAdmin';
grant drop on trigger group stats_triggers to role 'AutoAdmin';
grant drop on trigger group automatic_backup_system to role 'AutoAdmin';
grant drop on trigger group registry_triggers to role 'AutoAdmin';
go

grant alter on trigger system_watch_startup to role 'AutoAdmin';
grant alter on trigger system_watch_shutdown to role 'AutoAdmin';
grant alter on trigger connection_watch_connect to role 'AutoAdmin';
grant alter on trigger connection_watch_disconnect to role 'AutoAdmin';
grant alter on trigger security_watch_security_failure to role 'AutoAdmin';
grant alter on trigger new_row to role 'AutoAdmin';
grant alter on trigger deduplication to role 'AutoAdmin'; 
grant alter on trigger state_change to role 'AutoAdmin';
grant alter on trigger deduplicate_details to role 'AutoAdmin';
grant alter on trigger service_insert to role 'AutoAdmin';
grant alter on trigger service_reinsert to role 'AutoAdmin';
grant alter on trigger service_update to role 'AutoAdmin';
grant alter on trigger clean_details_table to role 'AutoAdmin';
grant alter on trigger clean_journal_table to role 'AutoAdmin';
grant alter on trigger delete_clears to role 'AutoAdmin';
grant alter on trigger escalate_off to role 'AutoAdmin';
grant alter on trigger expire to role 'AutoAdmin'; 
grant alter on trigger flash_not_ack to role 'AutoAdmin';
grant alter on trigger generic_clear to role 'AutoAdmin';
grant alter on trigger mail_on_critical to role 'AutoAdmin';
grant alter on trigger automatic_backup to role 'AutoAdmin';
grant alter on trigger backup_succeeded to role 'AutoAdmin';
grant alter on trigger backup_failed to role 'AutoAdmin';
grant alter on trigger profiler_toggle to role 'AutoAdmin';
grant alter on trigger profiler_report to role 'AutoAdmin';
grant alter on trigger profiler_group_report to role 'AutoAdmin';
grant alter on trigger trigger_stats_report to role 'AutoAdmin';
grant alter on trigger new_status_inserts to role 'AutoAdmin';
grant alter on trigger dedup_status_inserts to role 'AutoAdmin';
grant alter on trigger journal_inserts to role 'AutoAdmin';
grant alter on trigger details_inserts to role 'AutoAdmin';
grant alter on trigger statistics_gather to role 'AutoAdmin';
grant alter on trigger statistics_cleanup to role 'AutoAdmin';
grant alter on trigger stats_reset to role 'AutoAdmin';
grant alter on trigger disable_user to role 'AutoAdmin';
grant alter on trigger reset_user to role 'AutoAdmin';
grant alter on trigger disable_inactive_users to role 'AutoAdmin';
grant alter on trigger webtop_compatibility to role 'AutoAdmin';
grant alter on trigger audit_config_create_object to role 'AutoAdmin';
grant alter on trigger audit_config_alter_object to role 'AutoAdmin';
grant alter on trigger audit_config_drop_object to role 'AutoAdmin';
grant alter on trigger audit_config_alter_property to role 'AutoAdmin';
grant alter on trigger audit_config_create_class to role 'AutoAdmin';
grant alter on trigger audit_config_alter_class to role 'AutoAdmin';
grant alter on trigger audit_config_drop_class to role 'AutoAdmin';
grant alter on trigger audit_config_create_menu to role 'AutoAdmin';
grant alter on trigger audit_config_alter_menu to role 'AutoAdmin';
grant alter on trigger audit_config_drop_menu to role 'AutoAdmin';
grant alter on trigger audit_config_create_conv to role 'AutoAdmin';
grant alter on trigger audit_config_alter_conv to role 'AutoAdmin';
grant alter on trigger audit_config_drop_conv to role 'AutoAdmin';
grant alter on trigger audit_config_create_col_visual to role 'AutoAdmin';
grant alter on trigger audit_config_alter_col_visual to role 'AutoAdmin';
grant alter on trigger audit_config_drop_col_visual to role 'AutoAdmin';
grant alter on trigger audit_config_create_tool to role 'AutoAdmin';
grant alter on trigger audit_config_alter_tool to role 'AutoAdmin';
grant alter on trigger audit_config_drop_tool to role 'AutoAdmin';
grant alter on trigger audit_config_create_prompt to role 'AutoAdmin';
grant alter on trigger audit_config_alter_prompt to role 'AutoAdmin';
grant alter on trigger audit_config_drop_prompt to role 'AutoAdmin';
grant alter on trigger registry_new_probe to role 'AutoAdmin';
grant alter on trigger registry_reinsert_probe to role 'AutoAdmin';
grant alter on trigger registry_probe_disconnect to role 'AutoAdmin';
grant drop on trigger system_watch_startup to role 'AutoAdmin';
grant drop on trigger system_watch_shutdown to role 'AutoAdmin';
grant drop on trigger connection_watch_connect to role 'AutoAdmin';
grant drop on trigger connection_watch_disconnect to role 'AutoAdmin';
grant drop on trigger security_watch_security_failure to role 'AutoAdmin';
grant drop on trigger new_row to role 'AutoAdmin';
grant drop on trigger deduplication to role 'AutoAdmin';
grant drop on trigger state_change to role 'AutoAdmin';
grant drop on trigger deduplicate_details to role 'AutoAdmin';
grant drop on trigger service_insert to role 'AutoAdmin';
grant drop on trigger service_reinsert to role 'AutoAdmin';
grant drop on trigger service_update to role 'AutoAdmin';
grant drop on trigger clean_details_table to role 'AutoAdmin';
grant drop on trigger clean_journal_table to role 'AutoAdmin';
grant drop on trigger delete_clears to role 'AutoAdmin';
grant drop on trigger escalate_off to role 'AutoAdmin';
grant drop on trigger expire to role 'AutoAdmin'; 
grant drop on trigger flash_not_ack to role 'AutoAdmin';
grant drop on trigger generic_clear to role 'AutoAdmin';
grant drop on trigger mail_on_critical to role 'AutoAdmin';
grant drop on trigger automatic_backup to role 'AutoAdmin';
grant drop on trigger backup_succeeded to role 'AutoAdmin';
grant drop on trigger backup_failed to role 'AutoAdmin';
grant drop on trigger profiler_toggle to role 'AutoAdmin';
grant drop on trigger profiler_report to role 'AutoAdmin';
grant drop on trigger profiler_group_report to role 'AutoAdmin';
grant drop on trigger trigger_stats_report to role 'AutoAdmin';
grant drop on trigger new_status_inserts to role 'AutoAdmin';
grant drop on trigger dedup_status_inserts to role 'AutoAdmin';
grant drop on trigger journal_inserts to role 'AutoAdmin';
grant drop on trigger details_inserts to role 'AutoAdmin';
grant drop on trigger statistics_gather to role 'AutoAdmin';
grant drop on trigger statistics_cleanup to role 'AutoAdmin';
grant drop on trigger stats_reset to role 'AutoAdmin';
grant drop on trigger disable_user to role 'AutoAdmin';
grant drop on trigger reset_user to role 'AutoAdmin';
grant drop on trigger disable_inactive_users to role 'AutoAdmin';
grant drop on trigger webtop_compatibility to role 'AutoAdmin';
grant drop on trigger audit_config_create_object to role 'AutoAdmin';
grant drop on trigger audit_config_alter_object to role 'AutoAdmin';
grant drop on trigger audit_config_drop_object to role 'AutoAdmin';
grant drop on trigger audit_config_alter_property to role 'AutoAdmin';
grant drop on trigger audit_config_create_class to role 'AutoAdmin';
grant drop on trigger audit_config_alter_class to role 'AutoAdmin';
grant drop on trigger audit_config_drop_class to role 'AutoAdmin';
grant drop on trigger audit_config_create_menu to role 'AutoAdmin';
grant drop on trigger audit_config_alter_menu to role 'AutoAdmin';
grant drop on trigger audit_config_drop_menu to role 'AutoAdmin';
grant drop on trigger audit_config_create_conv to role 'AutoAdmin';
grant drop on trigger audit_config_alter_conv to role 'AutoAdmin';
grant drop on trigger audit_config_drop_conv to role 'AutoAdmin';
grant drop on trigger audit_config_create_col_visual to role 'AutoAdmin';
grant drop on trigger audit_config_alter_col_visual to role 'AutoAdmin';
grant drop on trigger audit_config_drop_col_visual to role 'AutoAdmin';
grant drop on trigger audit_config_create_tool to role 'AutoAdmin';
grant drop on trigger audit_config_alter_tool to role 'AutoAdmin';
grant drop on trigger audit_config_drop_tool to role 'AutoAdmin';
grant drop on trigger audit_config_create_prompt to role 'AutoAdmin';
grant drop on trigger audit_config_alter_prompt to role 'AutoAdmin';
grant drop on trigger audit_config_drop_prompt to role 'AutoAdmin';
grant drop on trigger registry_new_probe to role 'AutoAdmin';
grant drop on trigger registry_reinsert_probe to role 'AutoAdmin';
grant drop on trigger registry_probe_disconnect to role 'AutoAdmin';
go

-- Security Admin
create role 'SecurityAdmin' comment 'Security Administration';
grant create user to role 'SecurityAdmin';
grant create role to role 'SecurityAdmin';
grant create group to role 'SecurityAdmin';
grant create restriction filter to role 'SecurityAdmin';
grant alter user to role 'SecurityAdmin';
grant alter role to role 'SecurityAdmin';
grant alter group to role 'SecurityAdmin';
grant drop user to role 'SecurityAdmin';
grant drop role to role 'SecurityAdmin';
grant drop group to role 'SecurityAdmin';
grant grant role to role 'SecurityAdmin';
grant revoke role to role 'SecurityAdmin';
grant alter system set property to role 'SecurityAdmin';
grant alter system drop connection to role 'SecurityAdmin';
go


-- Tool Admin
create role 'ToolsAdmin' comment 'Tools administration';
grant delete on table tools.actions to role 'ToolsAdmin';
grant delete on table tools.action_access to role 'ToolsAdmin';
grant delete on table tools.menus to role 'ToolsAdmin';
grant delete on table tools.menu_items to role 'ToolsAdmin';
grant delete on table tools.menu_defs to role 'ToolsAdmin';
grant delete on table tools.prompt_defs to role 'ToolsAdmin';
grant update on table tools.actions to role 'ToolsAdmin';
grant update on table tools.action_access to role 'ToolsAdmin';
grant update on table tools.menus to role 'ToolsAdmin';
grant update on table tools.menu_items to role 'ToolsAdmin';
grant update on table tools.menu_defs to role 'ToolsAdmin';
grant update on table tools.prompt_defs to role 'ToolsAdmin';
grant insert on table tools.actions to role 'ToolsAdmin';
grant insert on table tools.action_access to role 'ToolsAdmin';
grant insert on table tools.menus to role 'ToolsAdmin';
grant insert on table tools.menu_items to role 'ToolsAdmin';
grant insert on table tools.menu_defs to role 'ToolsAdmin';
grant insert on table tools.prompt_defs to role 'ToolsAdmin';
go


-- Desktop Admin
create role 'DesktopAdmin' comment 'Desktop Administration';
grant insert on table alerts.col_visuals to role 'DesktopAdmin';
grant insert on table alerts.objclass to role 'DesktopAdmin';
grant insert on table alerts.conversions to role 'DesktopAdmin';
grant insert on table alerts.colors to role 'DesktopAdmin';
grant insert on table alerts.objmenuitems to role 'DesktopAdmin';
grant insert on table alerts.objmenus to role 'DesktopAdmin';
grant insert on table alerts.resolutions to role 'DesktopAdmin';
grant update on table alerts.col_visuals to role 'DesktopAdmin';
grant update on table alerts.objclass to role 'DesktopAdmin';
grant update on table alerts.conversions to role 'DesktopAdmin';
grant update on table alerts.colors to role 'DesktopAdmin';
grant update on table alerts.objmenuitems to role 'DesktopAdmin';
grant update on table alerts.objmenus to role 'DesktopAdmin';
grant update on table alerts.resolutions to role 'DesktopAdmin';
grant delete on table alerts.col_visuals to role 'DesktopAdmin';
grant delete on table alerts.objclass to role 'DesktopAdmin';
grant delete on table alerts.conversions to role 'DesktopAdmin';
grant delete on table alerts.colors to role 'DesktopAdmin';
grant delete on table alerts.objmenuitems to role 'DesktopAdmin';
grant delete on table alerts.objmenus to role 'DesktopAdmin';
grant delete on table alerts.resolutions to role 'DesktopAdmin';
grant delete on table alerts.iduc_messages to role 'DesktopAdmin';
go

-- ISQL role
create role 'ISQL' comment 'Read only ISQL access';
grant isql to role 'ISQL';
go

-- ISQL Write role
create role 'ISQLWrite' comment 'Write ISQL access';
grant isql write to role 'ISQLWrite';
go

-- Channel Admin
create role 'ChannelAdmin' comment 'Notification channel Administration';
grant insert on table iduc_system.channel to role 'ChannelAdmin';
grant insert on table iduc_system.channel_interest to role 'ChannelAdmin';
grant insert on table iduc_system.channel_summary to role 'ChannelAdmin';
grant insert on table iduc_system.channel_summary_cols to role 'ChannelAdmin';
grant update on table iduc_system.channel to role 'ChannelAdmin';
grant update on table iduc_system.channel_interest to role 'ChannelAdmin';
grant update on table iduc_system.channel_summary to role 'ChannelAdmin';
grant update on table iduc_system.channel_summary_cols to role 'ChannelAdmin';
grant delete on table iduc_system.channel to role 'ChannelAdmin';
grant delete on table iduc_system.channel_interest to role 'ChannelAdmin';
grant delete on table iduc_system.channel_summary to role 'ChannelAdmin';
grant delete on table iduc_system.channel_summary_cols to role 'ChannelAdmin';
go

-- OSLC Service Provider Registration Role
create role 'OSLCAdmin' comment 'OSLC Service Provider Registration Administration';
grant insert on table registry.oslcsp to role 'OSLCAdmin';
grant delete on table registry.oslcsp to role 'OSLCAdmin';
grant select on table registry.oslcsp to role 'OSLCAdmin';
grant insert on table registry.oslcecip to role 'OSLCAdmin';
grant update on table registry.oslcecip to role 'OSLCAdmin';
grant delete on table registry.oslcecip to role 'OSLCAdmin';
grant select on table registry.oslcecip to role 'OSLCAdmin';
grant insert on table registry.oslcecip_regs to role 'OSLCAdmin';
grant update on table registry.oslcecip_regs to role 'OSLCAdmin';
grant delete on table registry.oslcecip_regs to role 'OSLCAdmin';
grant select on table registry.oslcecip_regs to role 'OSLCAdmin';
go

-------------------------------------------------------------------------------------
--
--	Groups for administering subsystems. 
--
-------------------------------------------------------------------------------------



-- ProbeUser group
create group 'Probe' comment 'Permissions required for a probe user';
grant role 'CatalogUser' to group 'Probe';
grant role 'AlertsUser' to group 'Probe';
grant role 'AlertsProbe' to group 'Probe';
grant role 'RegisterProbe' to group 'Probe';
go

-- GatewayUser group
create group 'Gateway' comment 'Permissions required for a gateway user';
grant role 'CatalogUser' to group 'Gateway';
grant role 'AlertsUser' to group 'Gateway';
grant role 'AlertsGateway' to group 'Gateway';
grant role 'RegistryAdmin' to group 'Gateway';
go

-- Normal user group.
grant role 'CatalogUser' to group 'Normal';
grant role 'AlertsUser' to group 'Normal';
grant role 'ChannelUser' to group 'Normal';
grant role 'RegistryReader' to group 'Normal';
go

-- Administrator user group
grant role 'CatalogUser' to group 'Administrator';
grant role 'AlertsUser' to group 'Administrator';
grant role 'ChannelUser' to group 'Administrator';
grant role 'ToolsAdmin' to group 'Administrator';
grant role 'DesktopAdmin' to group 'Administrator';
grant role 'ChannelAdmin' to group 'Administrator';
grant role 'OSLCAdmin' to group 'Administrator';
grant role 'RegistryAdmin' to group 'Administrator';
go

-- System user group
grant role 'SuperUser' to group 'System';
grant role 'CatalogUser' to group 'System';
grant role 'AlertsUser' to group 'System';
grant role 'ChannelUser' to group 'System';
grant role 'ToolsAdmin' to group 'System';
grant role 'DesktopAdmin' to group 'System';
grant role 'AlertsProbe' to group 'System';
grant role 'AlertsGateway' to group 'System';
grant role 'DatabaseAdmin' to group 'System';
grant role 'AutoAdmin' to group 'System';
grant role 'SecurityAdmin' to group 'System';
grant role 'ChannelAdmin' to group 'System';
grant role 'RegistryAdmin' to group 'System';
grant role 'ISQL' to group 'System';
grant role 'ISQLWrite' to group 'System';
grant role 'OSLCAdmin' to group 'System';
go


-- ISQL Write Group
create group 'ISQLWrite' comment 'Write ISQL access';
grant role 'ISQLWrite' to group 'ISQLWrite';
go

-- ISQL Group
create group 'ISQL' comment 'Read only ISQL access';
grant role 'ISQL' to group 'ISQL';
go

-- Set up group conversions
create procedure setup_group_conversions()
declare
	found boolean;
begin
	for each row newgrp in security.groups
	begin
		set found = false;
		for each row oldconv in alerts.conversions where oldconv.Colname = 'OwnerGID' and oldconv.Value = newgrp.GroupID 
		begin
			set found = true;
		end;
		
		if( found = false ) then
			insert into alerts.conversions values ( 'OwnerGID'+ to_char( newgrp.GroupID ), 'OwnerGID', newgrp.GroupID, newgrp.GroupName );
		end if;
	end;
end;
execute setup_group_conversions;
go
drop procedure setup_group_conversions;
go


-- End of file

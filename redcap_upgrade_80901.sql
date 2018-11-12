-- --- SQL to upgrade REDCap to version 8.9.1 from 8.3.0 --- --
USE `redcap`;
SET SESSION SQL_SAFE_UPDATES = 0;

-- SQL for Version 8.3.1 --
INSERT INTO redcap_crons (cron_name, cron_description, cron_enabled, cron_frequency, cron_max_run_time, cron_instances_max, cron_instances_current, cron_last_run_end, cron_times_failed, cron_external_url) VALUES
('CheckREDCapRepoUpdates', 'Check if any installed External Modules have updates available on the REDCap Repo.', 'ENABLED', 10800, 300, 1, 0, NULL, 0, NULL);
INSERT INTO redcap_config (field_name, value) VALUES
('external_modules_updates_available', ''),
('external_modules_updates_available_last_check', '');
-- SQL for Version 8.3.2 --
-- Generate system notification from REDCap Messenger
insert into redcap_messages (thread_id, sent_time, message_body) values (1, '2018-11-12 12:58:39', '[{\"title\":\"Survey-specific email invitation fields\",\"description\":\"A new feature has been added to the Survey Settings page in the Online Designer: survey-specific email invitation fields. This can be enabled for any given survey, in which you can designate any email field in your project to use for sending survey invitations for that particular survey. Thus, you can collect several email addresses (e.g., for a student, a parent, and a teacher) and utilize each email for a different survey in the project. Then you can send each person an invitation to their own survey, after which all the survey responses get stored as one single record in the project.\\r\\n\\r\\nThe survey-specific email field is similar to the project-level email invitation field except that it is employed only for the survey where it has been enabled. In this way, the survey-level email can override an existing email address originally entered into the Participant List or the project-level email field (if used). This new feature allows users to have data entry workflows that require multiple surveys where the participant is different for each survey. (Note: The email field can exist on any instrument in the project, and you may use a different email field on each survey. You may also use the same email field for multiple surveys.)\\r\\n\\r\\nSee the Survey Settings page in the Online Designer to enable this feature for any of your surveys.\",\"link\":\"\",\"action\":\"what-new\"}]');
insert into redcap_messages_status (message_id, recipient_id, recipient_user_id)
select last_insert_id(), '1', ui_id from redcap_user_information where user_suspended_time is null;

-- SQL for Version 8.3.2 --
ALTER TABLE `redcap_surveys_emails` ADD `append_survey_link` TINYINT(1) NOT NULL DEFAULT '1' AFTER `delivery_type`;
-- SQL for Version 8.4.0 --
-- Generate system notification from REDCap Messenger
insert into redcap_messages (thread_id, sent_time, message_body) values (1, '2018-11-12 12:58:39', '[{\"title\":\"Introducing \\\"Smart Variables\\\"\",\"description\":\"Smart Variables are dynamic variables that can be used in calculated fields, conditional\\/branching logic, and piping. Similar to using project variable names inside square brackets - e.g., [heart_rate], Smart Variables are also represented inside brackets - e.g., [user-name], [survey-link], [previous-event-name][weight], or [heart_rate][previous-instance]. But instead of pointing to data fields, Smart Variables are context-aware and thus adapt to the current situation. Some can be used with field variables or other Smart Variables, and some are meant to be used as stand-alone. There are many possibilities.\\r\\n\\r\\nSmart Variables can reference things with regard to users, records, forms, surveys, events\\/arms, or repeating instances. To learn more, visit the <a href=\\\"\\/redcap\\/redcap_v8.9.1\\/Design\\/smart_variable_explain.php\\\">Smart Variables informational page<\\/a>.\",\"link\":\"\",\"action\":\"what-new\"}]');
insert into redcap_messages_status (message_id, recipient_id, recipient_user_id)
select last_insert_id(), '1', ui_id from redcap_user_information where user_suspended_time is null;
update redcap_surveys_scheduler ss, redcap_surveys s, redcap_projects p 
			set ss.email_content = concat(if(ss.email_content is null,'',ss.email_content), 
			convert(cast('\n\nYou may open the survey in your web browser by clicking the link below:\n[survey-link]\n\nIf the link above does not work, try copying the link below into your web browser:\n[survey-url]\n\nThis link is unique to you and should not be forwarded to others.' as binary) using latin1))
			where p.project_id = s.project_id and s.survey_id = ss.survey_id 
			and p.project_language = 'English' and ss.delivery_type = 'EMAIL';
update redcap_surveys_scheduler ss, redcap_surveys s, redcap_projects p 
			set ss.email_content = concat(if(ss.email_content is null,'',ss.email_content), 
			convert(cast(' -- To begin the survey, visit [survey-url]' as binary) using latin1))
			where p.project_id = s.project_id and s.survey_id = ss.survey_id 
			and p.project_language = 'English' and ss.delivery_type = 'SMS_INVITE_WEB';
update redcap_projects set custom_record_label = replace(custom_record_label, '[', '[first-event-name][')
where project_id in ('');

-- SQL for Version 8.4.0 --
ALTER TABLE `redcap_external_modules_downloads` ADD INDEX(`time_downloaded`);
ALTER TABLE `redcap_external_modules_downloads` ADD INDEX(`time_deleted`);
update redcap_config set value = 'https://data.bioontology.org/' where field_name = 'bioportal_api_url' and value = 'http://data.bioontology.org/';
-- Add new table for future functionality
drop table if exists redcap_record_list;
CREATE TABLE `redcap_record_list` (
`project_id` int(10) NOT NULL,
`arm` tinyint(2) NOT NULL,
`record` varchar(100) COLLATE utf8_unicode_ci NOT NULL,
`dag_id` int(10) DEFAULT NULL,
`sort` mediumint(7) DEFAULT NULL,
PRIMARY KEY (`project_id`,`arm`,`record`),
UNIQUE KEY `sort_project_arm` (`sort`,`project_id`,`arm`),
KEY `dag_project_arm` (`dag_id`,`project_id`,`arm`),
KEY `project_record` (`project_id`,`record`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
ALTER TABLE `redcap_record_list`
ADD FOREIGN KEY (`dag_id`) REFERENCES `redcap_data_access_groups` (`group_id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD FOREIGN KEY (`project_id`) REFERENCES `redcap_projects` (`project_id`) ON DELETE CASCADE ON UPDATE CASCADE;
-- SQL for Version 8.4.4 --
ALTER TABLE `redcap_projects` 
	ADD `pdf_custom_header_text` TEXT NULL DEFAULT NULL AFTER `custom_public_survey_links`, 
	ADD `pdf_show_logo_url` TINYINT(1) NOT NULL DEFAULT '1' AFTER `pdf_custom_header_text`;
-- SQL for Version 8.5.0 --
-- Reduce some varchar(255) to varchar(191) for consistency with new installations using utf8mb4 collation
ALTER TABLE `redcap_auth` CHANGE `username` `username` varchar(191) COLLATE utf8_unicode_ci NOT NULL;
ALTER TABLE `redcap_auth` CHANGE `password_reset_key` `password_reset_key` varchar(191) COLLATE utf8_unicode_ci DEFAULT NULL;
ALTER TABLE `redcap_config` CHANGE `field_name` `field_name` varchar(191) COLLATE utf8_unicode_ci NOT NULL DEFAULT '';
ALTER TABLE `redcap_ehr_access_tokens` CHANGE `patient` `patient` varchar(191) COLLATE utf8_unicode_ci DEFAULT NULL;
ALTER TABLE `redcap_ehr_access_tokens` CHANGE `mrn` `mrn` varchar(191) COLLATE utf8_unicode_ci DEFAULT NULL COMMENT 'If different from patient id';
ALTER TABLE `redcap_ehr_user_map` CHANGE `ehr_username` `ehr_username` varchar(191) COLLATE utf8_unicode_ci DEFAULT NULL;
ALTER TABLE `redcap_external_links_users` CHANGE `username` `username` varchar(191) COLLATE utf8_unicode_ci NOT NULL DEFAULT '';
ALTER TABLE `redcap_external_modules` CHANGE `directory_prefix` `directory_prefix` varchar(191) COLLATE utf8_unicode_ci NOT NULL;
ALTER TABLE `redcap_external_modules_downloads` CHANGE `module_name` `module_name` varchar(191) COLLATE utf8_unicode_ci NOT NULL;
ALTER TABLE `redcap_instrument_zip` CHANGE `instrument_id` `instrument_id` varchar(191) COLLATE utf8_unicode_ci NOT NULL DEFAULT '';
ALTER TABLE `redcap_instrument_zip_authors` CHANGE `author_name` `author_name` varchar(191) COLLATE utf8_unicode_ci DEFAULT NULL;
ALTER TABLE `redcap_instrument_zip_origins` CHANGE `server_name` `server_name` varchar(191) COLLATE utf8_unicode_ci NOT NULL DEFAULT '';
ALTER TABLE `redcap_locking_data` CHANGE `username` `username` varchar(191) COLLATE utf8_unicode_ci DEFAULT NULL;
ALTER TABLE `redcap_reports_access_users` CHANGE `username` `username` varchar(191) COLLATE utf8_unicode_ci NOT NULL DEFAULT '';
ALTER TABLE `redcap_surveys_erase_twilio_log` CHANGE `sid` `sid` varchar(191) COLLATE utf8_unicode_ci DEFAULT NULL;
ALTER TABLE `redcap_surveys_response_users` CHANGE `username` `username` varchar(191) COLLATE utf8_unicode_ci DEFAULT NULL;
ALTER TABLE `redcap_user_information` CHANGE `username` `username` varchar(191) COLLATE utf8_unicode_ci DEFAULT NULL;
ALTER TABLE `redcap_user_rights` CHANGE `username` `username` varchar(191) COLLATE utf8_unicode_ci NOT NULL;
ALTER TABLE `redcap_user_whitelist` CHANGE `username` `username` varchar(191) COLLATE utf8_unicode_ci NOT NULL DEFAULT '';
ALTER TABLE `redcap_validation_types` CHANGE `validation_name` `validation_name` varchar(191) COLLATE utf8_unicode_ci NOT NULL COMMENT 'Unique name for Data Dictionary';
ALTER TABLE `redcap_ddp_records_data` DROP INDEX `map_id_mr_id_timestamp_value`;
ALTER TABLE `redcap_ddp_records_data` ADD KEY `map_id_mr_id_timestamp_value` (`map_id`,`mr_id`,`source_timestamp`,`source_value2`(128));
ALTER TABLE `redcap_docs` DROP INDEX `project_id_comment`;
ALTER TABLE `redcap_docs` ADD KEY `project_id_comment` (`project_id`,`docs_comment`(190));
ALTER TABLE `redcap_ehr_access_tokens` DROP INDEX `access_token`;
ALTER TABLE `redcap_ehr_access_tokens` ADD KEY `access_token` (`access_token`(190));
ALTER TABLE `redcap_external_module_settings` DROP INDEX `value`;
ALTER TABLE `redcap_external_module_settings` ADD KEY `value` (`value`(190));
ALTER TABLE `redcap_messages` DROP INDEX `message_body`;
ALTER TABLE `redcap_messages` ADD KEY `message_body` (`message_body`(190));
ALTER TABLE `redcap_projects` DROP INDEX `app_title`;
ALTER TABLE `redcap_projects` ADD KEY `app_title` (`app_title`(190));
ALTER TABLE `redcap_projects` DROP INDEX `project_note`;
ALTER TABLE `redcap_projects` ADD KEY `project_note` (`project_note`(190));
ALTER TABLE `redcap_user_information` DROP INDEX `user_comments`;
ALTER TABLE `redcap_user_information` ADD KEY `user_comments` (`user_comments`(190));
-- Remove DDP on FHIR early adopter
delete from redcap_config where field_name = 'fhir_ddp_expose';
-- SQL for Version 8.5.1 --
INSERT INTO `redcap_validation_types` (`validation_name`, `validation_label`, `regex_js`, `regex_php`, `data_type`, `visible`)  
VALUES ('postalcode_germany', 'Postal Code (Germany)', '/^(0[1-9]|[1-9]\\d)\\d{3}$/',  '/^(0[1-9]|[1-9]\\d)\\d{3}$/', 'postal_code', 0);
-- SQL for Version 8.5.2 --
INSERT INTO `redcap_validation_types` (`validation_name`, `validation_label`, `regex_js`, `regex_php`, `data_type`, `legacy_value`, `visible`) 
VALUES ('postalcode_french', 'Code Postal 5 caracteres (France)', '/^((0?[1-9])|([1-8][0-9])|(9[0-8]))[0-9]{3}$/', '/^((0?[1-9])|([1-8][0-9])|(9[0-8]))[0-9]{3}$/', 'postal_code', NULL, '0');
INSERT INTO redcap_config (field_name, value) VALUES
('realtime_webservice_convert_timestamp_from_gmt', '0'),
('fhir_convert_timestamp_from_gmt', '0');
-- SQL for Version 8.6.0 --

-- Add new table for future functionality
drop table if exists redcap_record_list;
CREATE TABLE `redcap_record_list` (
`project_id` int(10) NOT NULL,
`arm` tinyint(2) NOT NULL,
`record` varchar(100) COLLATE utf8_unicode_ci NOT NULL,
`dag_id` int(10) DEFAULT NULL,
`sort` mediumint(7) DEFAULT NULL,
PRIMARY KEY (`project_id`,`arm`,`record`),
UNIQUE KEY `sort_project_arm` (`sort`,`project_id`,`arm`),
KEY `dag_project_arm` (`dag_id`,`project_id`,`arm`),
KEY `project_record` (`project_id`,`record`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
ALTER TABLE `redcap_record_list`
ADD FOREIGN KEY (`dag_id`) REFERENCES `redcap_data_access_groups` (`group_id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD FOREIGN KEY (`project_id`) REFERENCES `redcap_projects` (`project_id`) ON DELETE CASCADE ON UPDATE CASCADE;

CREATE TABLE `redcap_reports_folders` (
`folder_id` int(10) NOT NULL AUTO_INCREMENT,
`ui_id` int(10) DEFAULT NULL,
`project_id` int(10) DEFAULT NULL,
`name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
`position` smallint(3) DEFAULT NULL,
`collapsed` tinyint(1) NOT NULL DEFAULT '0',
PRIMARY KEY (`folder_id`),
KEY `project_id_ui_id` (`project_id`,`ui_id`),
KEY `ui_id` (`ui_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `redcap_reports_folders_items` (
`folder_id` int(10) DEFAULT NULL,
`report_id` int(10) DEFAULT NULL,
UNIQUE KEY `folder_id_report_id` (`folder_id`,`report_id`),
KEY `report_id` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

ALTER TABLE `redcap_reports_folders`
ADD FOREIGN KEY (`project_id`) REFERENCES `redcap_projects` (`project_id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD FOREIGN KEY (`ui_id`) REFERENCES `redcap_user_information` (`ui_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `redcap_reports_folders_items`
ADD FOREIGN KEY (`folder_id`) REFERENCES `redcap_reports_folders` (`folder_id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD FOREIGN KEY (`report_id`) REFERENCES `redcap_reports` (`report_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- SQL for Version 8.6.0 --
INSERT INTO redcap_crons (cron_name, cron_description, cron_enabled, cron_frequency, cron_max_run_time, cron_instances_max, cron_instances_current, cron_last_run_end, cron_times_failed, cron_external_url) VALUES
('CheckREDCapVersionUpdates', 'Check if there is a newer REDCap version available', 'ENABLED', 10800, 300, 1, 0, NULL, 0, NULL);

INSERT INTO redcap_config (field_name, value) VALUES
('redcap_updates_available', ''),
('redcap_updates_available_last_check', ''),
('redcap_updates_user', ''),
('redcap_updates_password', ''),
('redcap_updates_community_user', ''),
('redcap_updates_community_password', '');
-- SQL for Version 8.6.2 --
-- Remove unused database tables (trust us, these have never been used for anything)
drop table redcap_surveys_response_users;
drop table redcap_surveys_response_values;
replace into redcap_config (field_name, value) values ('redcap_updates_password_encrypted', '1');
ALTER TABLE `redcap_projects` ADD `shared_library_enabled` TINYINT(1) NOT NULL DEFAULT '1' AFTER `pdf_show_logo_url`;

-- SQL for Version 8.7.0 --

-- Tables required by External Modules Framework
CREATE TABLE IF NOT EXISTS `redcap_external_modules_log` (
`log_id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
`timestamp` datetime NOT NULL,
`ui_id` int(11) DEFAULT NULL,
`ip` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
`external_module_id` int(11) DEFAULT NULL,
`project_id` int(11) DEFAULT NULL,
`record` varchar(100) COLLATE utf8_unicode_ci DEFAULT NULL,
`message` mediumtext COLLATE utf8_unicode_ci NOT NULL,
PRIMARY KEY (`log_id`),
KEY `message` (`message`(190)),
KEY `record` (`record`),
KEY `external_module_id` (`external_module_id`),
KEY `redcap_log_redcap_projects_record` (`project_id`,`record`),
KEY `ui_id` (`ui_id`),
KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
CREATE TABLE IF NOT EXISTS `redcap_external_modules_log_parameters` (
`log_id` bigint(20) unsigned NOT NULL,
`name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
`value` mediumtext COLLATE utf8_unicode_ci NOT NULL,
PRIMARY KEY (`log_id`,`name`),
KEY `name` (`name`),
KEY `value` (`value`(190))
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
ALTER TABLE `redcap_external_modules_log_parameters`
ADD FOREIGN KEY (`log_id`) REFERENCES `redcap_external_modules_log` (`log_id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- SQL for Version 8.7.0 --
INSERT INTO redcap_config (field_name, value) VALUES
('azure_app_name', ''),
('azure_app_secret', ''),
('azure_container', '');
-- SQL for Version 8.7.2 --
ALTER TABLE `redcap_record_counts` 
	ADD `record_list_status` ENUM('NOT_STARTED','PROCESSING','COMPLETE') 
	NOT NULL DEFAULT 'NOT_STARTED' AFTER `time_of_count`;
ALTER TABLE `redcap_reports` 
	ADD `description` TEXT NULL DEFAULT NULL AFTER `user_access`, 
	ADD `combine_checkbox_values` TINYINT(1) NOT NULL DEFAULT '0' AFTER `description`;
-- SQL for Version 8.7.3 --

-- Reset this temporary table so that it can be rebuilt dynamically
TRUNCATE TABLE `redcap_record_counts`;
-- Add new status option
ALTER TABLE `redcap_record_counts` CHANGE `record_list_status` `record_list_status` 
	ENUM('NOT_STARTED','PROCESSING','COMPLETE','FIX_SORT') COLLATE utf8_unicode_ci NOT NULL DEFAULT 'NOT_STARTED';

-- SQL for Version 8.8.0 --
-- Adding new PROMIS Battery functionality
ALTER TABLE `redcap_library_map` ADD `battery` TINYINT(1) NOT NULL DEFAULT '0' AFTER `scoring_type`;
-- Fix record list issue for multi-arm projects
delete r.* from redcap_record_counts r, (select a.project_id from redcap_events_arms a, redcap_record_counts c 
where c.project_id = a.project_id group by a.project_id having count(*) > 1) x where r.project_id = x.project_id;
-- SQL for Version 8.8.1 --
INSERT INTO redcap_config (field_name, value) VALUES
('homepage_announcement_login', '1');
INSERT INTO redcap_config (field_name, value) VALUES
('user_messaging_prevent_admin_messaging', '0');
ALTER TABLE `redcap_projects` ADD `pdf_hide_secondary_field` TINYINT(1) NOT NULL DEFAULT '0' AFTER `pdf_show_logo_url`;
delete from redcap_record_counts;
-- SQL for Version 8.8.2 --

SET FOREIGN_KEY_CHECKS=0;
DROP TABLE `redcap_reports_folders_items`;
DROP TABLE `redcap_reports_folders`;
SET FOREIGN_KEY_CHECKS=1;

CREATE TABLE `redcap_reports_folders` (
`folder_id` int(10) NOT NULL AUTO_INCREMENT,
`project_id` int(10) DEFAULT NULL,
`name` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
`position` smallint(4) DEFAULT NULL,
PRIMARY KEY (`folder_id`),
KEY `project_id` (`project_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `redcap_reports_folders_items` (
`folder_id` int(10) DEFAULT NULL,
`report_id` int(10) DEFAULT NULL,
UNIQUE KEY `folder_id_report_id` (`folder_id`,`report_id`),
KEY `report_id` (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

ALTER TABLE `redcap_reports_folders`
ADD FOREIGN KEY (`project_id`) REFERENCES `redcap_projects` (`project_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `redcap_reports_folders_items`
ADD FOREIGN KEY (`folder_id`) REFERENCES `redcap_reports_folders` (`folder_id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD FOREIGN KEY (`report_id`) REFERENCES `redcap_reports` (`report_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `redcap_reports_folders` ADD UNIQUE `position_project_id` (`position`, `project_id`);

ALTER TABLE `redcap_record_list` DROP INDEX `sort_project_arm`, ADD INDEX `sort_project_arm` (`sort`, `project_id`, `arm`);

-- SQL for Version 8.9.0 --

CREATE TABLE `redcap_reports_edit_access_dags` (
`report_id` int(10) NOT NULL AUTO_INCREMENT,
`group_id` int(10) NOT NULL DEFAULT '0',
PRIMARY KEY (`report_id`,`group_id`),
KEY `group_id` (`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `redcap_reports_edit_access_roles` (
`report_id` int(10) NOT NULL DEFAULT '0',
`role_id` int(10) NOT NULL DEFAULT '0',
PRIMARY KEY (`report_id`,`role_id`),
KEY `role_id` (`role_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `redcap_reports_edit_access_users` (
`report_id` int(10) NOT NULL AUTO_INCREMENT,
`username` varchar(191) COLLATE utf8_unicode_ci NOT NULL DEFAULT '',
PRIMARY KEY (`report_id`,`username`),
KEY `username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

ALTER TABLE `redcap_reports_edit_access_dags`
ADD FOREIGN KEY (`group_id`) REFERENCES `redcap_data_access_groups` (`group_id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD FOREIGN KEY (`report_id`) REFERENCES `redcap_reports` (`report_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `redcap_reports_edit_access_roles`
ADD FOREIGN KEY (`report_id`) REFERENCES `redcap_reports` (`report_id`) ON DELETE CASCADE ON UPDATE CASCADE,
ADD FOREIGN KEY (`role_id`) REFERENCES `redcap_user_roles` (`role_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `redcap_reports_edit_access_users`
ADD FOREIGN KEY (`report_id`) REFERENCES `redcap_reports` (`report_id`) ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE `redcap_reports` ADD `user_edit_access` ENUM('ALL', 'SELECTED') NOT NULL DEFAULT 'ALL' AFTER `user_access`;

-- Generate system notification from REDCap Messenger
insert into redcap_messages (thread_id, sent_time, message_body) values (1, '2018-11-12 12:58:39', '[{\"title\":\"Enhancements to Reports\",\"description\":\"Reports can now be organized into folders (called Report Folders) in any given project. If you have \\\"Add\\/Edit Reports\\\" privileges, you will see an \\\"Organize\\\" link on the left-hand project menu above your reports. You will be able to create folders and then assign your reports to a folder, after which the project\'s reports will be displayed in collapsible groups on the left-hand menu. Report Folders are a great way to organize reports if your project has a lot of them.\\r\\n\\r\\nAlso, in addition to setting \\\"View Access\\\" when creating or editing a report, you can now set the report\'s \\\"Edit Access\\\" (under Step 1) to control who in the project can edit, copy, or delete the report. This setting will be very useful if you wish to prevent certain users from modifying or deleting particular reports.\\r\\n\\r\\nThere is also a new search feature on the left-hand menu to allow you to search within the title of your reports to help you navigate to a report very quickly. ENJOY!\",\"link\":\"\",\"action\":\"what-new\"}]');
insert into redcap_messages_status (message_id, recipient_id, recipient_user_id)
select last_insert_id(), '1', ui_id from redcap_user_information where user_suspended_time is null;


-- Set date of upgrade --
UPDATE redcap_config SET value = '2018-11-12' WHERE field_name = 'redcap_last_install_date' LIMIT 1;
REPLACE INTO redcap_history_version (`date`, redcap_version) values ('2018-11-12', '8.9.1');
-- Set new version number --
UPDATE redcap_config SET value = '8.9.1' WHERE field_name = 'redcap_version' LIMIT 1;

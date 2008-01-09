-- acs-mail-lite/sql/oracle/upgrade/upgrade-5.4.0d2-5.4.0d3.sql
--
-- Upgrade acs_mail_lite_queue; 
--

-- new columns

alter table acs_mail_lite_queue add column  creation_date       varchar(4000);
alter table acs_mail_lite_queue add column  locking_server      varchar(4000);
alter table acs_mail_lite_queue add column  cc_addr             clob;
alter table acs_mail_lite_queue add column  reply_to            varchar(400);
alter table acs_mail_lite_queue add column  file_ids            varchar(4000);
alter table acs_mail_lite_queue add column  mime_type           varchar(200);
alter table acs_mail_lite_queue add column  object_id           integer;
alter table acs_mail_lite_queue add column  no_callback_p       char(1)
                                            constraint amlq_no_callback_p_ck
                                            check (no_callback_p in ('t','f'));
alter table acs_mail_lite_queue add column  use_sender_p        char(1)
                                            constraint amlq_use_sender_p_ck
                                            check (use_sender_p in ('t','f'));

-- renamed columns
alter table acs_mail_lite_queue rename column bcc to bcc_addr;
alter table acs_mail_lite_queue rename column extra_headers to extraheaders;

-- datatype changes
alter table acs_mail_lite_queue modify    to_addr             varchar(4000);
alter table acs_mail_lite_queue modify    from_addr           varchar(400);
alter table acs_mail_lite_queue modify    subject             varchar(4000);

<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="acs_mail_lite::send.create_queue_entry">
        <querytext>
            insert into acs_mail_lite_queue 
            (message_id, to_addr, from_addr, subject, body, extra_headers, bcc)
            values
            (acs_mail_lite_id_seq.nextval, :to_addr, :from_addr, :subject, :body, :eh_list, :bcc)
        </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::sweeper.get_queued_messages">
        <querytext>
            select message_id,
                   to_addr,
                   from_addr,
                   subject,
                   body,
                   extra_headers,
                   bcc
            from acs_mail_lite_queue
        </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::sweeper.delete_queue_entry">
        <querytext>
            delete
            from acs_mail_lite_queue
            where message_id = :message_id
        </querytext>
    </fullquery>

</queryset>

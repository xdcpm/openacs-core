--
-- packages/acs-messaging/sql/acs-messaging-packages.sql
--
-- @author John Prevost <jmp@arsdigita.com>
-- @author Phong Nguyen <phong@arsdigita.com>
-- @author Jon Griffin <jon@jongriffin.com>
-- @creation-date 2000-08-27
-- @cvs-id $Id$
--
-- updated for OpenACS by Jon Griffin
--

create function acs_message__edit (integer,varchar,varchar,varchar,
text,timestamp,integer,varchar,boolean)
returns integer as '
declaration
    p_message_id    alias for $1;
    p_title         alias for $2;    -- default null
    p_description   alias for $3;    -- default null
    p_mime_type     alias for $4;    -- default ''text/plain''
    p_text          alias for $5;    -- default null
    p_data          alias for $6;    -- default null
    p_creation_date alias for $7;    -- default sysdate
    p_creation_user alias for $8;    -- default null
    p_creation_ip   alias for $9;    -- default null
    p_is_live       alias for $10;   -- default ''t''
    v_revision_id cr_revisions.revision_id%TYPE;
begin
    -- create a new revision using whichever call is appropriate
    if p_data is not null then
        v_revision_id := content_revision__new (
            item_id        => p_message_id,
            title          => p_title,
            description    => p_description,
            data           => p_data,
            mime_type      => p_mime_type,
            creation_date  => p_creation_date,
            creation_user  => p_creation_user,
            creation_ip    => p_creation_ip
        );
    else if p_title is not null or p_text is not null then
        v_revision_id := content_revision.new (
            item_id        => p_message_id,
            title          => p_title,
            description    => p_description,
            text           => p_text,
            mime_type      => p_mime_type,
            creation_date  => p_creation_date,
            creation_user  => p_creation_user,
            creation_ip    => p_creation_ip
        );      
    end if;

    -- test for auto approval of revision   
    if p_is_live = ''t'' then 
        content_item__set_live_revision(v_revision_id);
    end if;
    return v_revision_id;
end;' language 'plpgsql';
   
----------------
-- MAJOR NOTE OF NON-COMPLIANCE
-- I am exercising my rights as the porter here!
-- I can only use 16 parameters so I am changing one
-- creation_date will default to sysdate and not be a parameter
-- possibly another function can be made to change that
-- although I really don't see much need for this.
-- Jon Griffin 05-21-2001
----------------

create function acs_message__new (integer,integer,timestamp,integer,
varchar,varchar,varchar,varchar,varchar,text,integer,integer,integer,
varchar,integer,boolean)
returns integer as '
declare
        p_message_id    alias for $1;  --default null,
        p_reply_to      alias for $2;  --default null,
        p_sent_date     alias for $3;  --default sysdate,
        p_sender        alias for $4;  --default null,
        p_rfc822_id     alias for $5;  --default null,
        p_title         alias for $6;  --default null,
        p_description   alias for $7;  --default null,
        p_mime_type     alias for $8;  --default ''text/plain'',
        p_text          alias for $9;  --default null,
        p_data          alias for $10; --default null,
        p_parent_id     alias for $11; --default 0,
        p_context_id    alias for $12;
        p_creation_date timestamp := current_timestamp;  -- alias for $13 --default sysdate,
        p_creation_user alias for $13; --default null,
        p_creation_ip   alias for $14; --default null,
        p_object_type   alias for $15; --default ''acs_message'',
        p_is_live       alias for $16; --default ''t''
        v_message_id   acs_messages.message_id%TYPE;
        v_rfc822_id    acs_messages.rfc822_id%TYPE;
        v_revision_id  cr_revisions.revision_id%TYPE;
    begin
 
        -- generate a message id now so we can get an rfc822 message-id
        if p_message_id is null then
            select acs_object_id_seq.nextval into v_message_id;
        else
            v_message_id := p_message_id;
        end if;

        -- need to make this mandatory also - jg
        -- this needs to be fixed up, but Oracle doesn't give us a way
        -- to get the FQDN
        -- if rfc822_id is null then
        --    v_rfc822_id := now || ''.'' || v_message_id || ''@'' ||
        --        utl_inaddr.get_host_name || ''.hate'';
        --else
            v_rfc822_id := p_rfc822_id;
        --end if;

        v_message_id := content_item__new (
            name           => v_rfc822_id,
            parent_id      => p_parent_id,
            content_type   => ''acs_message_revision'',
            item_id        => p_message_id,
            context_id     => p_context_id,
            creation_date  => p_creation_date,
            creation_user  => p_creation_user,
            creation_ip    => p_creation_ip,
            item_subtype   => p_object_type
        );

        insert into acs_messages 
            (message_id, reply_to, sent_date, sender, rfc822_id)
        values 
            (v_message_id, p_reply_to, p_sent_date, p_sender, v_rfc822_id);

        -- create an initial revision for the new message
        v_revision_id := acs_message__edit (
            message_id     => v_message_id,
            title          => p_title,
            description    => p_description,
            mime_type      => p_mime_type,
            text           => p_text,
            data           => p_data,
            creation_date  => p_creation_date,
            creation_user  => p_creation_user,
            creation_ip    => p_creation_ip,
            is_live        => p_is_live
        );

        return v_message_id;
end;' language 'plpgsql';

create function acs_message__delete (integer)
returns integer as '
declaration
    p_message_id    in acs_messages.message_id%TYPE;
begin
    delete from acs_messages
        where p_message_id = acs_message.delete.message_id;
    content_item.delete(p_message_id);
    return 1;
end;' language 'plpgsql';

create function acs_message__message_p (integer)
returns boolean as '
declaration
    p_message_id          alias for $1;
    v_check_message_id  integer;
begin
    select (case when count(message_id) = 0 then 0 else 1 end) into v_check_message_id
        from acs_messages
            where message_id = p_message_id;
    if v_check_message_id <> 0 then
        return ''t'';
    else
        return ''f'';
    end if;
end;' language 'plpgsql';

create function acs_message__send (integer,varchar,integer,timestamp)
returns integer as '
declaration
    p_message_id    alias for $1;
    p_to_address    alias for $2;
    p_grouping_id   alias for $3;    -- default null
    p_wait_until    alias for $4;    -- default sysdate
    v_wait_until timestamp;
begin
    v_wait_until := coalesce(p_wait_until, current_timestamp);
    insert into acs_messages_outgoing
        (message_id, to_address, grouping_id, wait_until)
    values
        (p_message_id, p_to_address, p_grouping_id, v_wait_until);
    return 1;
end;' language 'plpgsql';

create function acs_message__send (integer,integer,integer,timestamp)
returns integer as '
declaration
    p_message_id    alias for $1;
    p_recipient_id  alias for $2;
    p_grouping_id   alias for $3;    -- default null
    p_wait_until    alias for $4;    -- default sysdate
    v_wait_until timestamp;
begin
    v_wait_until := coalesce (p_wait_until, current_timestamp);
    insert into acs_messages_outgoing
        (message_id, to_address, grouping_id, wait_until)
    select send.message_id, p.email, send.grouping_id, v_wait_until
        from parties p
        where p.party_id = send.recipient_id;
    return 1;
end;' language 'plpgsql';


-- This needs work as there is no connect by

create function acs_message__first_ancestor (integer)
returns integer as '
declaration
    message_id alias for $1;
    v_message_id acs_messages.message_id%TYPE;
begin
    select message_id into v_message_id
    from (select message_id, reply_to
          from acs_messages
          connect by message_id = prior reply_to
          start with message_id = first_ancestor.message_id) ancestors
          where reply_to is null;

    return v_message_id;
end;' language 'plpgsql';

    -- ACHTUNG!  WARNING!  ACHTUNG!  WARNING!  ACHTUNG!  WARNING! --

    -- Developers: Please don't depend on the following functionality
    -- to remain in the same place.  Chances are very good these
    -- functions will migrate to another PL/SQL package or be replaced
    -- by direct calls to CR code in the near future.

create function acs_message__new_file (integer,integer,varchar,varchar,
text,varchar,text,timestamp,integer,varchar,boolean)
returns integer as '
    p_message_id    alias for $1;
    p_file_id       alias for $2;    -- default null
    p_file_name     alias for $3;
    p_title         alias for $4;    -- default null
    p_description   alias for $5;    -- default null
    p_mime_type     alias for $6;    -- default ''text/plain''
    p_content       alias for $7;    -- default null
    p_creation_date alias for $8;    -- default sysdate
    p_creation_user alias for $9;    -- default null
    p_creation_ip   alias for $10;   -- default null
    p_is_live       alias for $11;   -- default ''t''
    v_file_id      cr_items.item_id%TYPE;
    v_revision_id  cr_revisions.revision_id%TYPE;
begin
    v_file_id := content_item__new (
        name           => p_file_name,
        parent_id      => p_message_id,
        item_id        => p_file_id,
        creation_date  => p_creation_date,
        creation_user  => p_creation_user,
        creation_ip    => p_creation_ip
    );

    -- create an initial revision for the new attachment
    v_revision_id := acs_file__edit_file (
        file_id         => v_file_id,
        title           => p_title,
        description     => p_description,
        mime_type       => p_mime_type,
        content         => p_content,
        creation_date   => p_creation_date,
        creation_user   => p_creation_user,
        creation_ip     => p_creation_ip,
        is_live         => p_is_live
    );

    return v_file_id;
end;' language 'plpgsql';

create function acs_message__edit_file (integer,varchar,text,varchar,
text,timestamp,integer,varchar,boolean)
returns integer as '
declare
    p_file_id       alias for $1;
    p_title         alias for $2;    -- default null
    p_description   alias for $3;    -- default null
    p_mime_type     alias for $4;    -- default ''text/plain''
    p_content       alias for $5;    -- default null
    p_creation_date alias for $6;    -- default sysdate
    p_creation_user alias for $7;    -- default null
    p_creation_ip   alias for $8;    -- default null
    p_is_live       alias for $9;    -- default ''t''
    v_revision_id  cr_revisions.revision_id%TYPE;
begin
    v_revision_id := content_revision.new (
        title         => p_title,
        mime_type     => p_mime_type,
        data          => p_content,
        item_id       => p_file_id,
        creation_date => p_creation_date,
        creation_user => p_creation_user,
        creation_ip   => p_creation_ip
    );

    -- test for auto approval of revision
    if is_live = ''t'' then 
        content_item__set_live_revision(v_revision_id);
    end if;

    return v_revision_id;
end;' language 'plpgsql';

create function acs_message__delete_file (integer)
returns integer as '
declaration
    p_file_id  alias for $1;
begin
    content_item__delete(p_file_id);       
    return 1;
end;' language 'plpgsql';

create function acs_message__new_image (integer,integer,varchar,varchar,
text,varchar,text,integer,integer,timestamp,integer,varchar,boolean)
returns integer as '
declaration
    p_message_id     alias for $1;
    p_image_id       alias for $2;    -- default null
    p_file_name      alias for $3;
    p_title          alias for $4;    -- default null
    p_description    alias for $5;    -- default null
    p_mime_type      alias for $6;    -- default ''text/plain''
    p_content        alias for $7;    -- default null
    p_width          alias for $8;    -- default null
    p_height         alias for $9;    -- default null
    p_creation_date  alias for $10;   -- default sysdate
    p_creation_user  alias for $11;   -- default null
    p_creation_ip    alias for $12;   -- default null
    p_is_live        alias for $13;   -- default ''t''
    v_image_id     cr_items.item_id%TYPE;
    v_revision_id  cr_revisions.revision_id%TYPE;
begin
    v_image_id := content_item__new (
        name           => p_file_name,
        parent_id      => p_message_id,
        item_id        => p_image_id,
        creation_date  => p_creation_date,
        creation_user  => p_creation_user,
        creation_ip    => p_creation_ip
    );

    -- create an initial revision for the new attachment
    v_revision_id := acs_message__edit_image (
        image_id       => v_image_id,
        title          => p_title,
        description    => p_description,
        mime_type      => p_mime_type,
        content        => p_content,
        width          => p_width,
        height         => p_height,
        creation_date  => p_creation_date,
        creation_user  => p_creation_user,
        creation_ip    => p_creation_ip,
        is_live        => p_is_live
    );

    return v_image_id;
end;' language 'plpgsql';

create function acs_message__edit_image (integer,varchar,text,varchar,
text,integer,integer,timestamp,integer,varchar,boolean)
returns integer as '
declaration
    p_image_id       alias for $1;
    p_title          alias for $2;    -- default null
    p_description    alias for $3;    -- default null
    p_mime_type      alias for $4;    -- default ''text/plain''
    p_content        alias for $5;    -- default null
    p_width          alias for $6;    -- default null
    p_height         alias for $7;    -- default null
    p_creation_date  alias for $8;    -- default sysdate
    p_creation_user  alias for $9;    -- default null
    p_creation_ip    alias for $10;   -- default null
    p_is_live        alias for $11;   -- default ''t''
    v_revision_id  cr_revisions.revision_id%TYPE;
begin
    v_revision_id := content_revision__new (
        title          => p_title,
        mime_type      => p_mime_type,
        data           => p_content,
        item_id        => p_image_id,
        creation_date  => p_creation_date,
        creation_user  => p_creation_user,
        creation_ip    => p_creation_ip       
    );      

    -- insert new width and height values
    -- XXX fix after image.new exists
    insert into images
        (image_id, width, height)
    values
        (v_revision_id, p_width, p_height);

    -- test for auto approval of revision   
    if p_is_live = ''t'' then 
        content_item__set_live_revision(v_revision_id);
    end if;

    return v_revision_id;
end;' language 'plpgsql';

create function acs_message__delete_image (integer)
returns integer as '
declaration
    p_image_id  alias for $1;
begin
    -- XXX fix after image.delete exists
    delete from images
        where image_id = p_image_id;
    content_item__delete(p_image_id);
    return 1;
end;' language 'plpgsql';

    -- XXX should just call content_extlink.new
create function acs_message__new_extlink (varchar,integer,varchar,
varchar,text,integer,timestamp,integer,varchar)
returns integer as '
declaration
    p_name           alias for $1;    -- default null
    p_extlink_id     alias for $2;    -- default null
    p_url            alias for $3;   
    p_label          alias for $4;    -- default null
    p_description    alias for $5;    -- default null
    p_parent_id      alias for $6;
    p_creation_date  alias for $7;    -- default sysdate
    p_creation_user  alias for $8;    -- default null
    p_creation_ip    alias for $9;    -- default null
    v_extlink_id  cr_extlinks.extlink_id%TYPE;
begin
    v_extlink_id := content_extlink.new (
        name           => p_name,
        url            => p_url,
        label          => p_label,
        description    => p_description,
        parent_id      => p_parent_id,
        extlink_id     => p_extlink_id,   
        creation_date  => p_creation_date,
        creation_user  => p_creation_user,
        creation_ip    => p_creation_ip 
    );
end;' language 'plpgsql';
    
-- XXX should just edit extlink
create function acs_message__edit_extlink (integer,varchar,varchar,text)
returns integer as '
declaration
    p_extlink_id   alias for $1;
    p_url          alias for $2;
    p_label        alias for $3;    -- default null
    p_description  alias for $4;    --  default null
    v_is_extlink  char;
begin
    v_is_extlink := content_extlink__is_extlink(p_extlink_id);
    if v_is_extlink = ''t'' then
        update cr_extlinks
        set url = p_url,
            label = p_label,
            description = p_description
        where extlink_id = p_extlink_id;
    end if;
    return v_is_extlink;
end;' language 'plpgsql';

create function acs_message__delete_extlink (integer)
returns integer as '
declaration
    p_extlink_id    alias for $1;
begin
    content_extlink__delete(p_extlink_id);
end;' language 'plpgsql';

create function acs_message__name (integer)
returns varchar as '
    p_message_id   alias for $1;
    v_message_name   acs_messages_all.title%TYPE;
begin
    select title into v_message_name
        from acs_messages_all
        where message_id = p_message_id;
    return v_message_name;
end;' language 'plpgsql';


<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_relation_types">      
      <querytext>
      FIX ME CONNECT BY

    select t.pretty_name, t.object_type as rel_type,
    replace(lpad(' ', (level - 1) * 4), ' ', '&nbsp;') as indent
    from acs_object_types t
    where t.object_type not in (select s.rel_type from rel_segments s where s.group_id = :group_id)
    connect by prior t.object_type = t.supertype
    start with t.object_type in ('membership_rel', 'composition_rel')
    order by lower(t.pretty_name) desc

      </querytext>
</fullquery>

 
<fullquery name="select_basic_info">      
      <querytext>
      
    select acs_group__name(:group_id) as group_name
      

      </querytext>
</fullquery>

 
</queryset>

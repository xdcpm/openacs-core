<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="adminable_objects">      
      <querytext>
      
  select distinct o.object_id, acs_object__name(o.object_id) as name
  from acs_objects o, all_object_party_privilege_map map
  where map.object_id = o.object_id
    and map.party_id = :user_id
    and map.privilege = 'admin'

      </querytext>
</fullquery>

 
</queryset>

select schema_name(tabs.schema_id) as schema_name,
       tabs.name as table_name, 
       tabs.create_date as created,  
       tabs.modify_date as last_modified, 
       p.rows as num_rows, 
       ep.value as comments 
  from sys.tables tabs
       inner join (select distinct 
                          part.object_id,
                          sum(part.rows) rows
                     from sys.tables t
                          inner join sys.partitions part 
                              on part.object_id = t.object_id 
                    group by part.object_id,
                          part.index_id) p
            on p.object_id = tabs.object_id
        left join sys.extended_properties ep 
            on tabs.object_id = ep.major_id
           and ep.name = 'MS_Description'
           and ep.minor_id = 0
           and ep.class_desc = 'OBJECT_OR_COLUMN'
  order by schema_name,
        table_name

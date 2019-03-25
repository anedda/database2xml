DECLARE @xmldata xml

SET @xmldata = (
    SELECT 'sqlserver' AS "@name",(
        SELECT(
            SELECT name AS "@name", ( 
                SELECT ( 
                    SELECT c.name AS "@name" , 
                        CASE WHEN TYPE_NAME ( c.user_TYPE_id ) = 'decimal' THEN 'number' 
                                                                        ELSE TYPE_NAME ( c.user_TYPE_id )
                        END AS "@TYPE",
                        CASE TYPE_NAME ( c.user_TYPE_id ) 
                            WHEN 'char' THEN LTRIM(str(max_length))
                            WHEN 'varchar' THEN LTRIM(str(max_length))
                            WHEN 'integer' THEN LTRIM(str(precision))+','+LTRIM(str(scale))
                            WHEN 'decimal' THEN LTRIM(str(precision))+','+LTRIM(str(scale))
                            WHEN 'int' THEN LTRIM(str(precision))+','+LTRIM(str(scale))
                        END AS "@length",
                        CASE WHEN c.is_nullable<>'0' THEN 'true' 
                        END AS "@nullable",
                        ep.value AS "@comment"
                    FROM sys.columns c 
                    LEFT JOIN sys.extended_properties ep
                        ON ep.major_id = c.object_id AND ep.minor_id = c.column_id
                    WHERE c.object_id = t.object_id 
                    ORDER BY c.column_id
                    FOR xml PATH('column'), TYPE
                )
                FOR xml PATH('columns'), TYPE),( 
                    SELECT ( 
                        SELECT i.name AS "@name", 
                            CASE i.is_unique 
                                WHEN 1 THEN 'true' 
                                    ELSE 'false' 
                            END AS "@unique",( 
                                SELECT (
                                    SELECT icc.name AS "@name", 
                                        CASE WHEN ic.is_descending_key=0 THEN 'ASC' 
                                                                        ELSE 'DESC'
                                        END AS "@order"
                                    FROM sys.index_columns  ic 
                                    INNER JOIN sys.columns icc 
                                        ON ic.column_id = icc.column_id AND icc.object_id=t.object_id
                                    WHERE ic.object_id=t.object_id AND i.index_id = ic.index_id
                                    FOR xml PATH('column'), TYPE)
                                FOR xml PATH('columns'), TYPE
                            )
                        FROM sys.indexes i 
                        WHERE i.object_id=t.object_id AND i.TYPE NOT IN (0)
                        ORDER by i.name
                        FOR xml PATH('index'), TYPE
                    )
                    FOR xml PATH('indexes'), TYPE)
                    FROM sys.tables t 
                    ORDER BY t.name
                FOR xml PATH('table'), TYPE)
            FOR xml PATH('tables'), TYPE
    ),
    (
        SELECT (
            SELECT distinct  v.name AS "@name", 
                CASE WHEN referenced_entity_name IS NULL THEN 'true' 
                                                        ELSE 'false' end
                AS "@valid",
                sys.fn_repl_hash_binary(CONVERT(VARBINARY(MAX),definition)) AS "@hash"
            FROM sys.views v
            LEFT JOIN sys.sql_expression_dependencies ed
                ON v.object_id=ed.referencing_id
                    AND is_ambiguous = 0
                    AND object_id(referenced_entity_name) IS NULL AND referenced_id IS NULL
                    AND object_name(referencing_id) IN ( 
                        SELECT object_name(sm.object_id) AS object_name
                        FROM sys.sql_modules AS sm
                        INNER JOIN sys.objects AS o 
                            ON sm.object_id = o.object_id)
            INNER JOIN sys.objects o
                ON o.object_id = v.object_id
            JOIN sys.sql_modules M ON m.object_id = o.object_id
            ORDER by v.name 
            FOR xml PATH('view'), TYPE
        )
        FOR xml PATH('views'), TYPE
    ),
    (
        SELECT ( 
            SELECT distinct  p.name AS "@name",
                CASE WHEN referenced_entity_name IS NULL THEN 'true' 
                    ELSE 'false' end
                AS "@valid",
                sys.fn_repl_hash_binary(CONVERT(VARBINARY(MAX),definition)) AS "@hash"
            FROM sys.procedures p
            LEFT JOIN sys.sql_expression_dependencies ed
            ON p.object_id=ed.referencing_id
                AND is_ambiguous = 0
                AND object_id(referenced_entity_name) IS NULL AND referenced_id IS NULL
                AND object_name(referencing_id) IN (
                    SELECT object_name(sm.object_id) AS object_name
                    FROM sys.sql_modules AS sm
                    INNER JOIN sys.objects AS o 
                        ON sm.object_id = o.object_id )
            INNER JOIN sys.objects o
                ON o.object_id = p.object_id
            JOIN sys.sql_modules M ON m.object_id = o.object_id
            ORDER BY p.name 
            FOR xml PATH('procedure'), TYPE
        )
        FOR xml PATH('procedures'), TYPE
    )
    FOR xml PATH('database')
)

SELECT @xmldata AS returnXml

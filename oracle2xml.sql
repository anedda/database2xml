SELECT XMLSERIALIZE(DOCUMENT 
    XMLElement("database", 
        XMLAttributes('oracle' AS "name"),(
            SELECT XMLElement("tables", 
                XMLAGG(
                    XMLElement("table",  
                        XMLAttributes(TABLE_NAME AS "name"), 
                            XMLElement("columns",(
                                SELECT XMLAGG(
                                    XMLElement( "column", 
                                        XMLAttributes(
                                            COL.COLUMN_NAME AS "name", 
                                            CASE LOWER(COL.DATA_TYPE) 
                                                WHEN 'varchar2' THEN 'varchar' 
                                                ELSE LOWER(COL.DATA_TYPE)
                                            END AS "type", 
                                            CASE WHEN COL.DATA_PRECISION IS NOT NULL THEN TO_CHAR(COL.DATA_PRECISION)||','||TO_CHAR(DATA_SCALE) ELSE TO_CHAR(CHAR_LENGTH) END AS "length", 
                                            CASE WHEN COL.NULLABLE='Y' THEN 'true' END AS "nullable",
                                            CASE WHEN PRIMARY_KEY.CONSTRAINT_NAME IS NOT NULL THEN 'true' END AS "primary_key",
                                            COM.COMMENTS AS "comment"
                                        )
                                    )
                                    ORDER BY COL.COLUMN_ID
                                )
                                FROM USER_TAB_COLUMNS COL
                                INNER JOIN USER_COL_COMMENTS COM
                                    ON COL.TABLE_NAME=COM.TABLE_NAME AND COL.COLUMN_NAME=COM.COLUMN_NAME
                                LEFT JOIN( 
                                    SELECT CON_COLS.TABLE_NAME, CON_COLS.COLUMN_NAME, CON_COLS.CONSTRAINT_NAME
                                    FROM USER_CONS_COLUMNS CON_COLS
                                    INNER JOIN USER_CONSTRAINTS CONS
                                        ON CONS.CONSTRAINT_TYPE = 'P' AND CONS.CONSTRAINT_NAME = CON_COLS.CONSTRAINT_NAME
                                ) PRIMARY_KEY
                                    ON COL.TABLE_NAME=PRIMARY_KEY.TABLE_NAME AND COL.COLUMN_NAME=PRIMARY_KEY.COLUMN_NAME
                                WHERE TAB.TABLE_NAME=COL.TABLE_NAME
                            )),
                        XMLElement("indexes",(
                            SELECT XMLAgg(
                                XMLElement( "index", 
                                    XMLAttributes(  IND.INDEX_NAME AS "name",
                                        CASE WHEN IND.UNIQUENESS = 'UNIQUE' THEN 'true' 
                                                                            ELSE 'false'
                                        END AS "unique"
                                    ),
                                    XMLElement("columns",(
                                        SELECT XMLAgg(
                                            XMLElement( "column", 
                                                XMLAttributes( 
                                                    INDCOL.COLUMN_NAME AS "name",
                                                    INDCOL.DESCEND AS "order"
                                                )
                                            )
                                            ORDER BY INDCOL.COLUMN_POSITION
                                        ) 
                                        FROM USER_IND_COLUMNS INDCOL
                                        WHERE INDCOL.TABLE_NAME=IND.TABLE_NAME AND INDCOL.INDEX_NAME=IND.INDEX_NAME
                                    ))
                                )
                                ORDER BY NLSSORT(IND.INDEX_NAME, 'NLS_SORT = BINARY_CI')
                            )
                            FROM USER_INDEXES IND
                            WHERE IND.TABLE_NAME=TAB.TABLE_NAME AND INDEX_TYPE = 'NORMAL'
                        ))
                    )
                    ORDER BY NLSSORT(TAB.TABLE_NAME, 'NLS_SORT = BINARY_CI')
                )
            )
            FROM USER_TABLES TAB
        ),(
            SELECT XMLElement("views", 
                XMLAGG(
                    XMLElement("view",
                        XMLAttributes(VIEW_NAME AS "name")
                    )
                    ORDER BY VIEW_NAME
                )
            )
            FROM USER_VIEWS
        ),
        (
            SELECT XMLElement("procedures", 
                XMLAGG(
                    XMLElement("procedure",
                        XMLAttributes(OBJECT_NAME AS "name")
                        )
                        ORDER BY OBJECT_NAME
                    )
                )
            FROM USER_PROCEDURES 
            WHERE OBJECT_TYPE='PROCEDURE'
        ),
        (
            SELECT XMLElement("packages", 
                XMLAGG(
                    XMLElement("package",
                        XMLAttributes(OBJECT_NAME AS "name")
                    )
                    ORDER BY OBJECT_NAME
                )
            )
            FROM USER_PROCEDURES
            WHERE OBJECT_TYPE='PACKAGE' AND SUBPROGRAM_ID=1
        )
    ) AS CLOB INDENT SIZE = 2
) AS XML
FROM DUAL;

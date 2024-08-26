template = """
    LAYER #
        NAME tropical_cyclone_lines_{year}

        PROJECTION
            "init=epsg:4326"
        END

        CONNECTIONTYPE   postgis
        CONNECTION       "%(POSTGIS_CONNECTION_STRING)s"
        DATA             "geom from tropical_cyclone_lines_{year}"
        STATUS           ON
        TYPE             LINE
        DUMP             TRUE
        HEADER           ./templates/layer_query_header.html
        TEMPLATE         ./templates/layer_query_body.html

        CLASS
            NAME "Tropical Cyclone Lines {year}"
            STYLE
                COLOR        0 100 0
                OUTLINECOLOR 0 0 0
            END
        END
        METADATA
            "wms_title"          "tropical_cyclone_lines_{year}"
            "wms_abstract"       "tropical_cyclone_lines_{year}"
            "gml_include_items"  "name,iso_time,wmo_wind,wmo_pres,usa_wind,usa_pres"
        END  # end METADATA
    END # end Layer
"""

for year in range(1980, 2024):
    print(template.format(year=year))

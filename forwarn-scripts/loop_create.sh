#!/bin/bash

for year in {1980..2023}; do
    # Create shapefile for each year
    ogr2ogr -f "ESRI Shapefile" -sql "SELECT * FROM \"IBTrACS.since1980.list.v04r00.lines\" WHERE season = '$year'" tropical_cyclone_lines_$year.shp ~/Downloads/hurricane_tracks/IBTrACS.since1980.list.v04r00.lines.shp

    # Create SQL file for each year
    shp2pgsql -I -s 4326 tropical_cyclone_lines_$year.shp > tropical_cyclone_lines_$year.sql
done

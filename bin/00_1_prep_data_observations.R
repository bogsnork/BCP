#Search for occurrences online

#packages-----
library(tidyverse)
library(rgeos)
library(sp)
library(rgdal)
# library(rgbif)
# library(rnrfa)
# library(NBN4R)
# # #if required
# # library(devtools)
# # install_github("fozy81/NBN4R") 

#set variables-----

#occurrence data to import
#path to raw occurrence data
path.occ <- "data/observations"
#filename raw occurrence data
fn.occ <- "occurrence_NBN_raw.csv"

#shapefiles to import
#path to shapefiles
path.shp <- "data/boundaries"
#filename boundary
fn.bound <- "SouthWest_boundary"
#filename bounding box
#fn.bbox <- "batlinks_bounding"

# #Coordinate reference systems
# #CRS for NBN search (requires lon lat)
p4.NBN <- "+proj=longlat +datum=WGS84"

#load data-----

#load project boundary
bound <- readOGR(dsn = path.shp, layer = fn.bound)
bbox <- as(extent(bound), "SpatialPolygons")
proj4string(bbox) <- proj4string(bound)

plot(bbox); plot(bound, add = TRUE)


#load occurrence data

#load occurence from single csv file, source = NBN
speciesdf <- read_csv(file = paste0(path.occ, "/", fn.occ))

# #load occurrence from shapefile
# occ_shp <- readOGR(dsn = path.occ, layer = fn.occ)

# #load occurrence from batch of csvs
# files_to_load <- list.files(path = path.occ, full.names = TRUE)
# files_to_load
# 
# occ_NBN_raw <- map_df(files_to_load, read_csv)
# warnings()


# Clean data ----

#remove duplicates
paste("Raw data has ", nrow(speciesdf), "records")
speciesdf <- distinct(speciesdf) 
paste("After removal of duplicates there are now ", nrow(speciesdf), "records.")  

# Make spatial ----

species_sp <- SpatialPointsDataFrame(coords = select(speciesdf, easting, northing), 
                                     data = speciesdf, 
                                     proj4string = crs)
plot(bound)
plot(species_sp, add = T)

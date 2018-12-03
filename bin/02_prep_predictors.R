## Predictors mostly prepared in ArcGIS

#packages
library(spatial)
library(raster)
library(rgeos)
library(tidyverse)
library(rgdal)

#paths

path_preds <- "data/predictors" #path to predictors

path_rasters <- "data/predictors/rasters" #path to prepared rasters


#list data
egvs_all <- list.files(path = path_preds, pattern = ".asc$", recursive = T); egvs

#set coordinate reference system
crs <- CRS("+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs")

# ##Prepare habitat diversity layers ----
# 
# #read LCM layers to raster stack
# path_LCM <- "data/predictors/LCM_rasters" #path to LCM rasters
# egvs_LCM <- list.files(path = path_LCM, pattern = ".asc$")
# egvs_LCM_full <- list.files(path = path_LCM, pattern = ".asc$", full.names = T)
# name_LCM <- egvs_LCM %>% 
#   gsub(pattern = "lcm_", replacement = "") %>% 
#   gsub(pattern = "_1000_cover.asc", replacement = "")   
# 
# #save to a raster stack object
# LCM_stack <- raster::stack(x = egvs_LCM_full, native = TRUE)  
# names(LCM_stack) <- name_LCM
# 
# #index of seminatural layers (excluding urban and suburban)
# layers_seminatural <- name_LCM[which(name_LCM != c("urban", "suburban"))]
# 
# 
# # #calculate number of cover classes in each cell
# # LCM_lgl_stack <- LCM_stack 
# # LCM_lgl_stack[LCM_lgl_stack > 0] <- 1 #make logical
# # LCM_lgl_stack <- stack(LCM_lgl_stack) #brick to stack
# # names(LCM_lgl_stack) <- name_LCM #write names
# # LCM_n_landcover <- sum(LCM_lgl_stack) #number of all land cover classes in each cell
# # LCM_n_habitats <-sum(LCM_lgl_stack[[layers_seminatural]]) #number of all semi-natural habiats in each cell
# 
# 
# #calculate Shannon diversity of habitats in each cell
# 
# LCM_stack_prop <- LCM_stack[[layers_seminatural]]/100 #convert percentage to proportion
# 
# LCM_log <- log10(LCM_stack_prop)
# hist(LCM_log)
# LCM_log[is.na(LCM_log)] <- 0  #replace NA  {log(0)} with 0
# hist(LCM_log)
# plot(LCM_log)
# ##problem here as I have made the entire sea 0.  Need to crop it by the boundary. 
# 
# boundary <- rgdal::readOGR(dsn = "data/boundaries/SouthWest_boundary.shp")
# LCM_log <- raster::mask(x = LCM_log, mask = boundary)
# plot(LCM_log)
# #plot(boundary, col = "red", add= T)  
# 
# LCM_log_prop <- stack()
# for(i in 1:nlayers(LCM_log)){
#   LCM_log_prop <- stack(LCM_log_prop, 
#                         LCM_log[[i]]*LCM_stack_prop[[i]])
# }
# 
# LCM_shannon_habitats <- -sum(LCM_log_prop)
# plot(LCM_shannon_habitats)
# raster::writeRaster(x = LCM_shannon_habitats, filename = "data/predictors/LCM_shannon_habitats.tif")



## Read in raster files ----

#get list of rasters
raster_files <- list.files(path = "data/predictors/rasters", pattern = ".asc$", full.names = T)
raster_files

var_stack <- stack() #to stack the rasters into

for(i in 1:length(raster_files)){
  temp <- raster(raster_files[i])
  proj4string(temp) <- crs
  var_stack <- stack(var_stack, temp) 
}

# add land cover diversity index raster
LCM_shannon_habitats <- raster("data/predictors/LCM_shannon_habitats.tif")
proj4string(LCM_shannon_habitats) <- crs
LCM_shannon_habitats <- resample(x = LCM_shannon_habitats, y = var_stack$awi_ancientwoodland_all_1000_cover)

var_stack <- stack(var_stack, LCM_shannon_habitats)

#add terrain
raster_files <- list.files(path = "data/predictors/terrain", pattern = "[.asc|.tif]$", full.names = T)
raster_files

terrain_stack <- stack() #to stack the rasters into

for(i in 1:length(raster_files)){
  temp <- raster(raster_files[i])
  proj4string(temp) <- crs
  temp <- resample(temp, var_stack)
  terrain_stack <- stack(terrain_stack, temp) 
}

var_stack <- stack(var_stack, terrain_stack)

## Rename raster stack layers ----
library(stringr)
stacknames <- names(var_stack)

stacknames <- ifelse(test = grepl("niwt_[0-9]", stacknames), 
                     yes = gsub(pattern = "niwt_", 
                                replacement = "woodland_NIWT_", 
                                x = stacknames), 
                     no = stacknames)


patterns <- c("awi_", "niwt_", "osvecdist_", "ons_")

for(i in patterns){
stacknames <- stringr::str_remove(string = stacknames, pattern = i)
}

names(var_stack) <- stacknames

var_stack

raster::writeRaster(var_stack, "data/predictors/var_stack.grd")

## Extract predictor values from observation locations ----

observations_sp <- occ_NBN_sp

training_data <- raster::extract(x = var_stack, y = observations_sp)

names(training_data) <- names(var_stack)

obs_vars_alldata <- data.frame(observations_sp@data, training_data)

write.csv(obs_vars_alldata, "data/training/observations_variables_NBN.csv", row.names = F)



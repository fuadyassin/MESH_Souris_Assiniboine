# Define the custom library paths
custom_lib_paths <- c("/home/fuaday/R/x86_64-pc-linux-gnu-library/4.3")
# Uncomment and use this path if needed
# custom_lib_paths <- c("/project/6008034/Climate_Forcing_Data/assets/r-envs/exact-extract-env/v5/R-4.1/x86_64-pc-linux-gnu")
# Set the custom library paths
.libPaths(custom_lib_paths)
# Install and load required packages
library(dplyr)
library(sf)
##
#######################################################################################################################
basin_aggregation <- function(input_basin, input_river, min_subarea, min_slope, min_length) {
########################################################################################################################
input_basin = left_join(input_basin, input_river[,c("COMID","NextDownID","uparea")] %>% as.data.frame() %>% select(-geometry), by = "COMID")
input_river$slope[input_river$slope < min_slope] <- min_slope
input_river$slope[input_river$slope >= 1] <- min_slope  
input_river$lengthkm[input_river$lengthkm < min_length] <- min_length
##
input_basin$agg <- input_basin$COMID
input_basin$aggdown <- input_basin$NextDownID
agg_basin <- input_basin[,c("agg","aggdown","unitarea","uparea")] %>% as.data.frame() %>% select(-geometry)
agg_basin <- agg_basin[agg_basin$aggdown > 0,]
##
for (qq in 1 : length(input_basin$COMID)) {
#########################################################################################################################################
######### Aggregated the headwaters sub-basins ##########################################################################################
#########################################################################################################################################
small_subbasin = agg_basin[!(agg_basin$agg %in% agg_basin$aggdown),]              ## Select headwaters sub-basins
small_subbasin = small_subbasin[small_subbasin$unitarea < min_subarea,]           ## Select sub-basins with less than the minimum area
if (length(small_subbasin$unitarea) > 0) {
xx = small_subbasin[order(-small_subbasin$uparea),]       ## Rearrange the order of the aggregation
colnames(xx) <- c("aggold","agg","unitarea","uparea")
yy = left_join(xx, agg_basin[,c("agg","aggdown")], by = "agg")
##
for (i in 1 : length(yy$aggold)) {
input_basin$aggdown[which(input_basin$agg == yy$aggold[i])] <- yy$aggdown[i]
input_basin$agg[which(input_basin$agg == yy$aggold[i])] <- yy$agg[i]
}
}
##
agg_basin = aggregate(input_basin[,c("unitarea")] %>% as.data.frame() %>% select(-geometry), by = list(input_basin$agg,input_basin$aggdown), FUN = sum)
colnames(agg_basin) <- c("COMID","NextDownID","unitarea")
agg_basin = left_join(agg_basin, input_basin[,c("COMID","uparea")] %>% as.data.frame() %>% select(-geometry), by = "COMID")
colnames(agg_basin) <- c("agg","aggdown","unitarea","uparea")
agg_basin <- agg_basin[agg_basin$aggdown > 0,]
##
#############################################################################################################################################
############ Aggregated the intermediate sub-basins #########################################################################################
#############################################################################################################################################
small_subbasin = agg_basin[which(agg_basin$agg %in% agg_basin$aggdown),]            ## select intermediate sub-basins excluding the outlet
small_subbasin = small_subbasin[small_subbasin$unitarea < min_subarea,]             ## select sub-basins with less than the minimum area
if (length(small_subbasin$unitarea) > 0) {
xx = small_subbasin[order(-small_subbasin$uparea),]
for (i in 1 : length(xx$agg)) {
yy = which(input_basin$COMID == xx$agg[i])
if (sum(input_basin$unitarea[which(input_basin$agg == input_basin$agg[yy])]) < min_subarea) {
xy = which(input_basin$NextDownID == input_basin$COMID[yy])
if (length(xy) > 0) {
xz = xy[which(input_basin$uparea[xy] == max(input_basin$uparea[xy]))]
xz = xz[1]
zz = which(input_basin$aggdown == input_basin$agg[xz])
input_basin$agg[which(input_basin$agg == input_basin$agg[xz])] <- input_basin$agg[yy][1]
input_basin$aggdown[which(input_basin$agg == input_basin$agg[xz])] <- input_basin$aggdown[yy][1]
if (length(zz) > 0) { input_basin$aggdown[zz] <- input_basin$agg[yy][1] }
##
}}}}
##
agg_basin = aggregate(input_basin[,c("unitarea")] %>% as.data.frame() %>% select(-geometry), by = list(input_basin$agg,input_basin$aggdown), FUN = sum)
colnames(agg_basin) <- c("COMID","NextDownID","unitarea")
agg_basin = left_join(agg_basin, input_basin[,c("COMID","uparea")] %>% as.data.frame() %>% select(-geometry), by = "COMID")
colnames(agg_basin) <- c("agg","aggdown","unitarea","uparea")
agg_basin <- agg_basin[agg_basin$aggdown > 0,]    
##
# #########################################################################################################################################
# ######### Aggregated the headwaters sub-basins ##########################################################################################
# #########################################################################################################################################
# small_subbasin = agg_basin[!(agg_basin$agg %in% agg_basin$aggdown),]              ## Select headwaters sub-basins
# small_subbasin = small_subbasin[small_subbasin$unitarea < min_subarea,]           ## Select sub-basins with less than the minimum area
# if (length(small_subbasin$unitarea) > 0) {
# xx = small_subbasin[order(-small_subbasin$uparea),]       ## Rearrange the order of the aggregation
# colnames(xx) <- c("aggold","agg","unitarea","uparea")
# yy = left_join(xx, agg_basin[,c("agg","aggdown")], by = "agg")
# ##
# for (i in 1 : length(yy$aggold)) {
# input_basin$aggdown[which(input_basin$agg == yy$aggold[i])] <- yy$aggdown[i]
# input_basin$agg[which(input_basin$agg == yy$aggold[i])] <- yy$agg[i]
# }
# }
# ##
# agg_basin = aggregate(input_basin[,c("unitarea")] %>% as.data.frame() %>% select(-geometry), by = list(input_basin$agg,input_basin$aggdown), FUN = sum)
# colnames(agg_basin) <- c("COMID","NextDownID","unitarea")
# agg_basin = left_join(agg_basin, input_basin[,c("COMID","uparea")] %>% as.data.frame() %>% select(-geometry), by = "COMID")
# colnames(agg_basin) <- c("agg","aggdown","unitarea","uparea")
# ##
if (min(agg_basin$unitarea) >= min_subarea) { break }
}
########################################################################################################################################
agg_basin = aggregate(input_basin[,c("unitarea")], st_drop_geometry(input_basin[,c("agg")]), FUN = sum)
colnames(agg_basin)[1] <- "COMID"
agg_basin = left_join(agg_basin, input_basin[,c("COMID","aggdown","uparea")] %>% as.data.frame() %>% select(-geometry), by = "COMID")
colnames(agg_basin) <- c("COMID","unitarea","NextDownID","uparea","geometry")
########################################################################################################################################
######### Aggregating river network based on the aggregated sub-basins #################################################################
########################################################################################################################################
agg_river = left_join(input_river, input_basin[,c("COMID","agg")] %>% as.data.frame() %>% select(-geometry), by = "COMID")
agg_river$mask <- 0
kk = agg_river$agg[!duplicated(agg_river$agg)]
for (i in kk) {
xx = which(agg_river$agg == i)
for (qq in 1 : 1000) {
yy <- xx[which(agg_river$uparea[xx] == max(agg_river$uparea[xx]))]
agg_river$mask[yy] <- 1
xx = which(agg_river$NextDownID == agg_river$COMID[yy])
if (length(xx) < 1) { break }
}}
##
agg_river = agg_river[agg_river$mask == 1,]
agg_river$slope = agg_river$slope*agg_river$lengthkm
##
agg_river = aggregate(agg_river[,c("lengthkm","slope")], st_drop_geometry(agg_river[,"agg"]), sum)
colnames(agg_river)[1] <- "COMID"
agg_river$slope = agg_river$slope / agg_river$lengthkm
agg_river = left_join(agg_river, agg_basin[,c("COMID","NextDownID","uparea")] %>% as.data.frame() %>% select(-geometry), by = "COMID")
agg_river = left_join(agg_river, input_river[,c("COMID","order","hillslope")] %>% as.data.frame() %>% select(-geometry), by = "COMID")
##
aggregated_out <- list("output_basin" = agg_basin, "output_river" = agg_river)
##
return(aggregated_out)
##
}    
##
# Main script to read arguments and call the function
args <- commandArgs(trailingOnly = TRUE)

# Expecting args: input_basin_path, input_river_path, min_subarea, min_slope, min_length, output_basin_path, output_river_path
input_basin_path <- args[1]
input_river_path <- args[2]
min_subarea <- as.numeric(args[3])
min_slope <- as.numeric(args[4])
min_length <- as.numeric(args[5])
output_basin_path <- args[6]
output_river_path <- args[7]

# Read input data
input_basin <- st_read(input_basin_path)
input_river <- st_read(input_river_path)

# Call the function
result <- basin_aggregation(input_basin, input_river, min_subarea, min_slope, min_length)

# Save the results
write_sf(result$output_basin, output_basin_path, overwrite=TRUE)
write_sf(result$output_river, output_river_path, overwrite=TRUE)
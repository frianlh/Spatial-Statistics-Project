# Library
library(readxl)
library(dplyr)
library(ggplot2)
library(rgdal)
library(spatstat)
library(splancs)
library(sf)
library(shapefiles)
library(raster)
library(maptools)
library(Rcpp)
library(sp)
library(rgeos)
library(tigris)

# Import Data
df <- read_excel("Downloads/Data Coffee Shop Depok.xlsx")
summary(df)

# Membuat CityLine Kota Depok
setwd("~/Downloads/KOTA DEPOK")
CityLine <- readOGR(dsn = ".", layer = "ADMINISTRASIDESA_AR_25K")

# Plot Data
plot(df$Longitude, df$Latitude,
    main = "Titik Koordinat Coffee Shop di Kota Depok",
    xlab = "Longitude",
    ylab = "Latitude")
ggplot() +
    geom_path(data = CityLine, aes(x = long, y = lat, group = group)) +
    geom_point(data = df, aes(x = Longitude, y = Latitude), colour = "blue") +
    labs(title = "Titik Koordinat Coffee Shop di Kota Depok")

# Density Plot
PointCoordinate <- data.frame(lon=df$Longitude, lat=df$Latitude)
coordinates(PointCoordinate) <- c("lon", "lat")
plot(PointCoordinate)
proj4string(PointCoordinate) <- CRS("+init=epsg:4326")
PointTransformed <- spTransform(PointCoordinate, CRS("+init=epsg:3857"))
PointTransformedDf <- data.frame(PointTransformed)
View(PointTransformedDf)

# Import City Border
CityLine <- st_read('ADMINISTRASIDESA_AR_25K.shp')
plot(CityLine)

# Merge all subregion
regionOfInterest <- st_union(CityLine[c(1:93), ])
plot(regionOfInterest)

# Transform Coordinate to X Y (EPSG3857)
CityLine_flat <- st_transform(regionOfInterest, crs = 3857)
plot(CityLine_flat)
CityLine_flat_df <- data.frame(CityLine_flat[[1]])

# Create owin (Window/Map Border)
CityLine_owin <- as.owin(CityLine_flat)

# Add Point to Map
flppp <- ppp(PointTransformedDf$lon, PointTransformedDf$lat, window=CityLine_owin)
plot(flppp, pch = 20, main = "Titik Koordinat Coffee Shop di Kota Depok")
plot(density(flppp, sigma = 500), main = "Density Plot (flpp, sigma = 500)")

# Uji Quadrat
P <- ppp(df$Latitude, df$Longitude, c(-6.49043, -6.31903), c(106.7324, 106.8973), unitname = c("derajat","derajat"))
summary(P)

# Quadrat Counting
qc <- quadratcount(flppp, nx = 10, ny = 10)
plot(flppp, main = "Planar Point Pattern (PPP)", lwd = 2, pch = 20)
plot(qc, add = TRUE, cex = 1, col = "blue")

# Quadrat Test
qt <- quadrat.test(flppp, nx = 10, ny = 10)
qt
qt$expected

# Plot
plot(flppp, main = "Plot Qudarat Methods", lwd = 2, pch = 20)
plot(qt, add = TRUE, cex = .5, col = "blue")

# Intensity Plot
qc <- quadratcount(flppp, nx = 10, ny = 10)
tess <- as.tess(qc)
tile_area <- data.frame(tile.areas(tess))$tile.areas.tess.
qc_df <- data.frame(qc)
plot(tess, do.col = TRUE, values = qc_df$Freq/tile_area, main = "Intensity Plot")

#Uji Lanjutan
xbar <- sum(qc_df$Freq)/79; xbar
var <- sum((qc_df$Freq-mean)^2)/78; var
I <- var/xbar; I
ICS <- I-1; ICS
ICF <- xbar/ICS; ICF
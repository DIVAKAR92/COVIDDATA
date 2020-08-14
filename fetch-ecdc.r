library(lubridate)
library(utils)
library(httr)

# date_offset <- 0
url <- "https://opendata.ecdc.europa.eu/covid19/casedistribution/csv/"
# date_iso <- as.character(Sys.Date() - date_offset)
# url <- sprintf(url_string, date_iso)

url_page <- "https://www.ecdc.europa.eu/en/publications-data/download-todays-data-geographic-distribution-covid-19-cases-worldwide"
tryCatch({
  #download the dataset from the ECDC website to a local temporary file
  r <- RETRY("GET", "https://opendata.ecdc.europa.eu/covid19/casedistribution/csv/", 
             write_disk("data/COVID-19-up-to-date.csv", overwrite=TRUE))
  
  if (http_error(r)) {
    stop("Error downloading file")
  }
},
error = function(e) {
  stop(sprintf("Error downloading file '%s': %s, please check %s",
               url, e$message, url_page))
})

d <- read.csv("data/COVID-19-up-to-date.csv", stringsAsFactors = FALSE)



d$dateRep = as.Date(d$dateRep, format = "%d/%m/%Y")
d$t <- lubridate::decimal_date(as.Date(d$dateRep, format = "%d/%m/%Y"))
d <- d[order(d$'countriesAndTerritories', d$t, decreasing = FALSE), ]
names(d)[names(d) == "countriesAndTerritories"] <- "Country"
# Read which countires to use
countries <- readRDS('nature/data/regions.rds')
d = d %>% filter(Country %in% countries$Regions)
names(d)[names(d) == "deaths"] <- "Deaths"
names(d)[names(d) == "cases"] <- "Cases"
names(d)[names(d) == "dateRep"] <- "DateRep"
# d$Cases = abs(d$Cases)
# d$Deaths = abs(d$Deaths)

## Correct for negaive deaths and cases 
id = which(d$Cases < 0)
d$Cases[id[1:2]] = abs(d$Cases[id[1:2]])
d$Cases[id[3]] = round(mean(d$Cases[c((id[3]-1),(id[3]+1))]), 0)
d$Cases[id[4]] = round(mean(d$Cases[c((id[4]-1),(id[4]+1))]), 0)

id = which(d$Deaths < 0)
d$Deaths[id[1]] = abs(d$Deaths[id[1]])
d$Deaths[id[2]] = round(mean(d$Deaths[c((id[2]-1),(id[2]+1))]), 0)
d$Deaths[id[3]] = abs(d$Deaths[id[3]])
d$Deaths[id[4]] = abs(d$Deaths[id[4]])

saveRDS(d, "data/COVID-19-up-to-date.rds")
saveRDS(d, "nature/data/COVID-19-up-to-date.rds")


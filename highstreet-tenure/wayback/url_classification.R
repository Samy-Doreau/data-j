library(dplyr)
library(readr)
# Load URLs
df <- read.csv('wayback/wayback_links.csv', stringsAsFactors = FALSE)

# Force lowercase on found_href first
df$found_href <- tolower(ifelse(is.na(df$found_href), "", as.character(df$found_href)))

# Choose the URL column to classify
url_col <- 'found_href'  # or 'wayback_download_url'

# Decode and (still) lowercase for matching
norm <- tolower(utils::URLdecode(df[[url_col]]))

# Classify
category <- rep("other", nrow(df))

idx1 <- grepl("nndr.*accounts.*no.*relief", norm, perl = TRUE)
category[idx1] <- "accounts_no_relief"

idx2 <- grepl(".*accounts.*relief", norm, perl = TRUE) & !grepl("no\\s*relief", norm, perl = TRUE)
category[idx2] <- "accounts_relief"

idx3 <- grepl("new\\s*businesses", norm, perl = TRUE)
category[idx3] <- "new_businesses"

idx4 <- grepl("nndr.*closed.*account", norm, perl = TRUE)
category[idx4] <- "accounts_closed"

# Updated: More flexible pattern for "current account/accounts in credit/credits"
# - accounts? matches "account" (singular) or "accounts" (plural)
# - credit(s)? matches "credit" (singular) or "credits" (plural)
# - \\s+ requires at least one whitespace between words
idx5 <- grepl("current\\s+accounts?\\s+in\\s+credit(s)?", norm, perl = TRUE)
category[idx5] <- "accounts_current_in_credit"

df$category <- category

df <- df %>% filter(category != 'other')

# Write data back
write_csv(df,'url_classified.csv')



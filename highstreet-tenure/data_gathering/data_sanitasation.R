library(readxl)

paths = list(
  "New%20Businesses%20from%20April22%20to%20August22.xlsx",
  "New%20businesses%20from%20February%20to%20June21.xlsx",
  "New%20Businesses%20from%20July%20to%20September21.xlsx",
  "New%20Businesses%20from%20October%202021%20to%20March%202022.xlsx",
  "New%20Businesses%20July-Sept20_0.xlsx",
  "NNDR_New%20Businesses%20from%20Nov23%20to%20March24.xlsx",
  "NNDR_New%20Businesses%20from%20October20%20to%20January21.xlsx",
  "NNDR%20New%20Businesses_February%20to%20May2023.xlsx",
  "NNDR%20New%20Businesses%20from%20June%20to%20October%202023.xlsx",
  "NNDR%20New%20Businesses%20from%20September%202022%20to%20January%202023.xlsx"
)

for(p in paths){
  full_access_name <- paste0('raw_files/new_businesses/',p)
  df <- read_excel(full_access_name, sheet = 1, n_max = 1000)
  names(df)
}





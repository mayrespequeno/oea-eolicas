# Instala o pacote caso você não tenha
if (!require("writexl")) install.packages("writexl")
library(writexl)

# Exporta para um arquivo Excel
write_xlsx(amostra_base, "amostra_experimento_analise.xlsx")

# Mostra onde o arquivo foi salvo no seu computador
cat("✅ Arquivo salvo em:", getwd(), "/amostra_experimento_analise.xlsx")

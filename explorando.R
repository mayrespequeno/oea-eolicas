# BASE DA GESTÃO CENTRALIZADA (GRANDES USINAS) DO SIGA (Sistema de Informações de Geração da ANEEL)
# Instalação de pacotes (caso não tenha)
if (!require("tidyverse")) install.packages("tidyverse")
if (!require("jsonlite")) install.packages("jsonlite")
if (!require("janitor")) install.packages("janitor")
if (!require("lubridate")) install.packages("lubridate")
if (!require("leaflet")) install.packages("leaflet")

# Ultima Atualização em 5 de fevereiro de 2026

# -------------------------------------------------------------------------
# 1. DOWNLOAD ROBUSTO 
# -------------------------------------------------------------------------
url_csv_siga <- "https://dadosabertos.aneel.gov.br/dataset/siga-sistema-de-informacoes-de-geracao-da-aneel/resource/2f65a1b0-19b8-4360-8238-b34ab4693d55/download/siga-empreendimentos-geracao-diario.csv"

arquivo_destino <- "siga_dados_completo.csv"

cat("🔄 Baixando arquivo CSV direto (pode demorar 1-2 min)... \n")

if (!file.exists(arquivo_destino)) {
  tryCatch({
    download.file(url_csv_siga, destfile = arquivo_destino, mode = "wb", 
                  method = "curl", extra = "-k") 
  }, error = function(e) {
    download.file(url_csv_siga, destfile = arquivo_destino, mode = "wb")
  })
}

cat("✅ Download concluído (ou arquivo já existente)! Carregando no R...\n")

# -------------------------------------------------------------------------
# 2. LEITURA E LIMPEZA
# -------------------------------------------------------------------------
dados_brutos <- read.csv(arquivo_destino, 
                         sep = ";", 
                         fileEncoding = "latin1", # Solução para 'Operao' e 'Cear'
                         check.names = FALSE,
                         stringsAsFactors = FALSE)

# Limpeza dos nomes das colunas 
dados_limpos <- dados_brutos %>%
  clean_names()

eolicas_brasil <- dados_limpos %>%
  filter(sig_tipo_geracao == "EOL") %>% # Filtra apenas Eólicas
  mutate(
   
    potencia_mw = as.numeric(str_replace_all(mda_potencia_outorgada_kw, ",", ".")) / 1000,
    
  
    lat = as.numeric(str_replace(num_coord_n_empreendimento, ",", ".")),
    lon = as.numeric(str_replace(num_coord_e_empreendimento, ",", ".")),
    
  
    lat = ifelse(nom_empreendimento == "Seridó 5", -6.69, lat),
    lon = ifelse(nom_empreendimento == "Seridó 5", -36.65, lon),
    
  
    inicio_fase = substr(dsc_fase_usina, 1, 3),
    status = case_when(
      inicio_fase == "Ope" ~ "Em Operação",    # Pega "Operação", "Operao", etc.
      inicio_fase == "Con" ~ "Em Obras",       # Pega "Construção", "Construo"
      TRUE ~ "Projeto/Outorga"
    )
  ) %>%
  filter(!is.na(lat), !is.na(lon))

cat("Total de usinas eólicas carregadas:", nrow(eolicas_brasil), "\n")

# -------------------------------------------------------------------------
# ONDE ESTÁ A ENERGIA? (Ranking por Estado)
# -------------------------------------------------------------------------
cat("\n📊 POTÊNCIA EÓLICA POR ESTADO (Top 10):\n")
ranking_estados <- eolicas_brasil %>%
  group_by(sig_uf_principal) %>%
  summarise(
    total_mw = sum(potencia_mw, na.rm = TRUE),
    qtd_parques = n()
  ) %>%
  arrange(desc(total_mw)) %>%
  head(10)

print(ranking_estados)

# Gráfico de Barras
ggplot(ranking_estados, aes(x = reorder(sig_uf_principal, -total_mw), y = total_mw)) +
  geom_col(fill = "green") +
  labs(title = "Top 10 Estados em Energia Eólica (MW)",
       x = "Estado", y = "Potência Outorgada (MW)") +
  theme_minimal()+
  geom_text(
    aes(label = round(total_mw, 0)), 
    vjust = -0.5,                   
    size = 3.5,                      
    fontface = "bold"               
  )
  

# -------------------------------------------------------------------------
# 4.OPERAÇÃO vs. OBRAS
# -------------------------------------------------------------------------
cat("\n🏗️ SITUAÇÃO ATUAL DOS PARQUES:\n")
resumo_fase <- eolicas_brasil %>%
  group_by(status) %>%
  summarise(MW = sum(potencia_mw, na.rm = TRUE))

print(resumo_fase)


library(tidyverse)
library(stringr)
library(writexl)

# ==============================================================================
# 1. PREPARAÇÃO E LIMPEZA (Usando os nomes exatos do seu colnames)
# ==============================================================================
dados_match <- eolicas_brasil %>%
  # 1. Renomeia a coluna problemática para facilitar (Corrige 'muninicpios')
  rename(Municipio = dsc_muninicpios) %>%
  
  # 2. Filtros básicos (Nordeste + Grande Porte)
  filter(sig_uf_principal %in% c("RN", "BA", "CE", "PI", "PE")) %>%
  filter(potencia_mw >= 30) %>%
  
  mutate(
    # 3. Define os Grupos do Experimento
    grupo_experimento = case_when(
      status == "Em Operação" ~ "Grupo A (Legado)",
      status %in% c("Em Obras", "Projeto/Outorga") ~ "Grupo B (Pré-2026)",
      TRUE ~ NA_character_
    ),
    
    # 4. Cria a EMPRESA MÃE (Limpando 'dsc_propri_regime_pariticipacao')
    nome_sujo = dsc_propri_regime_pariticipacao, 
    # Remove lixo: "100%", "para", números, pontos
    nome_limpo = str_remove_all(nome_sujo, "100%|para|PARA|[0-9]|%|\\.|-"),
    nome_limpo = str_trim(nome_limpo),
    # Pega a primeira palavra chave
    Empresa_Mae = word(nome_limpo, 1),
    Empresa_Mae = str_to_upper(Empresa_Mae)
  ) %>%
  # Remove quem não tem classificação de grupo
  filter(!is.na(grupo_experimento))

# ==============================================================================
# 2. SEPARAÇÃO DOS TIMES (A vs B)
# ==============================================================================
df_A <- dados_match %>%
  filter(grupo_experimento == "Grupo A (Legado)") %>%
  select(Empresa_Mae, Mun_A = Municipio, Parque_A = nom_empreendimento, MW_A = potencia_mw)

df_B <- dados_match %>%
  filter(grupo_experimento == "Grupo B (Pré-2026)") %>%
  select(Empresa_Mae, Mun_B = Municipio, Parque_B = nom_empreendimento, MW_B = potencia_mw)

# ==============================================================================
# 3. O ENCONTRO (MATCHING)
# ==============================================================================
# Cruza as tabelas pela Empresa
pares_finais <- inner_join(df_A, df_B, by = "Empresa_Mae", relationship = "many-to-many") %>%
  mutate(
    # Calcula a diferença
    diff_mw = abs(MW_A - MW_B),
    diff_perc = diff_mw / MW_A
  ) %>%
  # FILTRO DE QUALIDADE: Aceita diferença de até 20% na potência
  filter(diff_perc <= 0.20) %>%
  arrange(Empresa_Mae, diff_perc) %>%
  select(
    Empresa = Empresa_Mae,
    Municipio_Legado = Mun_A, 
    Parque_Legado = Parque_A, 
    MW_Legado = MW_A,
    
    Municipio_Novo = Mun_B, 
    Parque_Novo = Parque_B, 
    MW_Novo = MW_B,
    
    Diferenca_MW = diff_mw
  )

# ==============================================================================
# 4. RESULTADOS E EXPORTAÇÃO
# ==============================================================================
cat("✅ Processamento Concluído!\n")
cat("Total de pares comparáveis encontrados:", nrow(pares_finais), "\n")

# Salva o arquivo Excel para sua análise
if (!require("writexl")) install.packages("writexl")
write_xlsx(pares_finais, "Base_Pares_Experimento_Final.xlsx")

# Mostra os primeiros resultados na tela
print(head(pares_finais))

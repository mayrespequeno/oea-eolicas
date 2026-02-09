library(tidyverse)
library(stringr)

# ==============================================================================
# 1. REFAZENDO A LIMPEZA (Para eliminar "PARQUE" e "CENTRAL")
# ==============================================================================
# Palavras proibidas (Stopwords) que não identificam a empresa
termos_genericos <- c("100%", "PARA", "PARQUE", "EOLICA", "CENTRAL", "GERADORA", 
                      "ENERGIA", "RENOVAVEIS", "S.A.", "LTDA", "SPE", "DO", "DE", "DA", 
                      "[0-9]", "\\.", "-")
# Cria uma "regex" gigante: "PARA|PARQUE|EOLICA|..."
padrao_remocao <- paste(termos_genericos, collapse = "|")

dados_limpos <- eolicas_brasil %>%
  rename(Municipio = dsc_muninicpios) %>% # Usa o nome certo da coluna
  filter(sig_uf_principal %in% c("RN", "BA", "CE", "PI", "PE")) %>%
  filter(potencia_mw >= 30) %>%
  mutate(
    grupo_experimento = case_when(
      status == "Em Operação" ~ "Legado",
      status %in% c("Em Obras", "Projeto/Outorga") ~ "Novo",
      TRUE ~ NA_character_
    ),
    # LIMPEZA PROFUNDA: Remove tudo que é genérico
    nome_sujo = toupper(dsc_propri_regime_pariticipacao),
    nome_limpo = str_remove_all(nome_sujo, padrao_remocao),
    nome_limpo = str_trim(nome_limpo), # Tira espaços das pontas
    # Pega a primeira palavra que sobrou (agora deve ser o nome real)
    Empresa_Mae = word(nome_limpo, 1)
  ) %>%
  filter(!is.na(grupo_experimento)) %>%
  # Remove se o nome da empresa ficou vazio ou muito curto
  filter(nchar(Empresa_Mae) > 2)

# ==============================================================================
# 2. MATCHING (CRUZAMENTO)
# ==============================================================================
df_A <- dados_limpos %>% filter(grupo_experimento == "Legado") %>% 
  select(Empresa_Mae, Mun_A = Municipio, Parque_A = nom_empreendimento, MW_A = potencia_mw)

df_B <- dados_limpos %>% filter(grupo_experimento == "Novo") %>% 
  select(Empresa_Mae, Mun_B = Municipio, Parque_B = nom_empreendimento, MW_B = potencia_mw)

todos_matches <- inner_join(df_A, df_B, by = "Empresa_Mae", relationship = "many-to-many") %>%
  mutate(diff_mw = abs(MW_A - MW_B), diff_perc = diff_mw / MW_A) %>%
  filter(diff_perc <= 0.15) # Aceita max 15% de diferença

# ==============================================================================
# 3. ESTRATÉGIA DE PRIORIZAÇÃO (O "Pulo do Gato")
# ==============================================================================
# Temos milhares de linhas. Vamos pegar apenas O MELHOR PAR para cada Parque Antigo.
melhores_casos <- todos_matches %>%
  group_by(Parque_A) %>% # Para cada parque antigo...
  arrange(diff_mw) %>%   # ...ordena pelo match mais perfeito...
  slice(1) %>%           # ...e pega só o primeiro (o campeão).
  ungroup() %>%
  
  # AGORA APLICAMOS OS FILTROS DE "INTELIGÊNCIA":
  # 1. Queremos ver empresas diferentes (não 50 linhas da mesma empresa)
  # 2. Queremos os maiores parques (mais impacto social)
  arrange(desc(MW_A)) %>% 
  group_by(Empresa_Mae) %>%
  slice_head(n = 2) %>% # Pega no máximo 2 exemplos por Empresa para variar
  ungroup() %>%
  head(20) # Top 20 Geral

# ==============================================================================
# 4. VISUALIZAÇÃO CORRIGIDA
# ==============================================================================
dados_plot <- melhores_casos %>%
  mutate(
    rotulo = paste0(Empresa_Mae, ": ", Mun_A, " (", round(MW_A,0), ") vs ", Mun_B, " (", round(MW_B,0), ")"),
    rotulo = reorder(rotulo, MW_A)
  )

ggplot(dados_plot) +
  geom_segment(aes(x = MW_A, xend = MW_B, y = rotulo, yend = rotulo), color = "grey60") +
  geom_point(aes(x = MW_A, y = rotulo, color = "Legado"), size = 3) +
  geom_point(aes(x = MW_B, y = rotulo, color = "Novo"), size = 3) +
  labs(
    title = "Top 20 Pares Comparáveis (Filtrados)",
    subtitle = "Prioridade: Grandes Parques (>MW) com Match de Potência",
    x = "Potência (MW)", y = "", color = "Fase"
  ) +
  theme_minimal() +
  scale_color_manual(values = c("Legado"="#27AE60", "Novo"="#E67E22"))

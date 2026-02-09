library(tidyverse)
library(janitor)

# 1. PREPARAÇÃO DA BASE (Corrigindo o nome da coluna de Agente)
amostra_base <- eolicas_brasil %>%
  # Foco no Nordeste
  filter(sig_uf_principal %in% c("RN", "BA", "CE", "PI", "PE")) %>%
  
  # Remove parques muito pequenos (< 30MW)
  filter(potencia_mw >= 30) %>%
  
  mutate(
    grupo_experimento = case_when(
      status == "Em Operação" ~ "Grupo A (Legado)",
      status %in% c("Em Obras", "Projeto/Outorga") ~ "Grupo B (Pré-2026)",
      TRUE ~ NA_character_
    ),
    
    # --- CORREÇÃO AQUI ---
    # Usamos a coluna 'dsc_propri_regime_pariticipacao' que consta no dicionário
    # Como essa coluna pode ter texto longo (ex: "100% AES Tietê"), pegamos os primeiros 20 caracteres
    agente_sujo = dsc_propri_regime_pariticipacao,
    agente_simples = substr(agente_sujo, 1, 25) 
  ) %>%
  filter(!is.na(grupo_experimento))

# 2. ESTRATÉGIA: MATCH CORPORATIVO
# Identifica empresas que aparecem nos dois grupos
empresas_ambos_lados <- amostra_base %>%
  group_by(agente_simples) %>%
  summarise(
    tem_grupo_A = any(grupo_experimento == "Grupo A (Legado)"),
    tem_grupo_B = any(grupo_experimento == "Grupo B (Pré-2026)"),
    total_mw = sum(potencia_mw)
  ) %>%
  filter(tem_grupo_A & tem_grupo_B) %>%
  arrange(desc(total_mw))

cat("Empresas com projetos nos dois lados (Operação e Expansão):", nrow(empresas_ambos_lados), "\n")

# 3. LISTA DE ALVOS PRIORITÁRIOS
alvos_prioritarios <- amostra_base %>%
  filter(agente_simples %in% empresas_ambos_lados$agente_simples) %>%
  select(
    Empresa_Estimada = agente_simples,
    # GARANTINDO QUE O MUNICÍPIO ESTÁ AQUI
    Municipio = dsc_muninicpios, 
    MW = potencia_mw,
    Grupo = grupo_experimento
  ) %>%
  mutate(
    # AQUI ESTÁ O TRUQUE: Criamos um texto que junta Cidade e Empresa
    # substr(..., 1, 15) corta o nome da empresa para não ficar gigante
    rotulo_visual = paste0(Municipio, " - ", substr(Empresa_Estimada, 1, 15), "...")
  ) %>%
  arrange(Empresa_Estimada, Grupo)

# Visualiza os primeiros alvos
print(head(alvos_prioritarios, 20))

# Se quiser salvar:
# write.csv(alvos_prioritarios, "alvos_experimento_climae.csv")

# 4. GRÁFICO DO EXPERIMENTO
ggplot(alvos_prioritarios, aes(x = reorder(rotulo_visual, MW), y = MW, fill = Grupo)) +
  
  # Barras lado a lado
  geom_col(position = "dodge") +
  
  # Vira o gráfico deitado
  coord_flip() +
  
  # Títulos e Legendas
  labs(
    title = "Alvos do Experimento: Localização e Empresa",
    subtitle = "Comparação: Operação (A) vs. Licenciamento (B) por Município",
    y = "Potência (MW)", 
    x = "Município - Empresa",
    fill = "Situação"
  ) +
  
  theme_minimal() +
  
  # Cores do Experimento
  scale_fill_manual(values = c("Grupo A (Legado)" = "#27AE60", 
                               "Grupo B (Pré-2026)" = "#E67E22")) +
  
  # Ajuste fino para o texto do eixo Y não ficar cortado
  theme(axis.text.y = element_text(size = 9))

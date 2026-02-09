library(tidyverse)
library(writexl)

# ==============================================================================
# 1. PREPARAÇÃO DOS DICIONÁRIOS (Quem é quem?)
# ==============================================================================
# Vamos criar um "mini-banco" só com nomes e códigos para facilitar o cruzamento
dicionario_usinas <- dados_limpos %>%
  select(nom_empreendimento, cod_ceg, sig_uf_principal, dsc_fase_usina)

# ==============================================================================
# 2. ENRIQUECIMENTO DA TABELA DE PARES
# ==============================================================================
# Pegamos a tabela 'melhores_casos' que gerou o gráfico e buscamos os códigos
lista_ouro_identificada <- melhores_casos %>%
  
  # --- LADO A (LEGADO) ---
  # Trazemos o CEG e UF baseados no nome do parque antigo
  left_join(dicionario_usinas, by = c("Parque_A" = "nom_empreendimento")) %>%
  rename(
    CEG_Legado = cod_ceg,
    UF_Legado = sig_uf_principal,
    Fase_Legado_Detalhada = dsc_fase_usina
  ) %>%
  
  # --- LADO B (NOVO) ---
  # Trazemos o CEG e UF baseados no nome do parque novo
  left_join(dicionario_usinas, by = c("Parque_B" = "nom_empreendimento")) %>%
  rename(
    CEG_Novo = cod_ceg,
    UF_Novo = sig_uf_principal,
    Fase_Novo_Detalhada = dsc_fase_usina
  ) %>%
  
  # --- ORGANIZAÇÃO FINAL ---
  select(
    Empresa_Mae,
    
    # Bloco A (Referência)
    Parque_Legado = Parque_A,
    Codigo_CEG_Legado = CEG_Legado,
    UF_Legado,
    MW_Legado = MW_A,
    
    # Bloco B (Alvo da Comparação)
    Parque_Novo = Parque_B,
    Codigo_CEG_Novo = CEG_Novo,
    UF_Novo,
    MW_Novo = MW_B,
    
    # Dados Técnicos
    Diferenca_MW = diff_mw
  )

# ==============================================================================
# 3. EXPORTAÇÃO
# ==============================================================================
write_xlsx(lista_ouro_identificada, "Lista_Ouro_com_Codigos_CEG.xlsx")

cat("✅ Arquivo gerado com sucesso: 'Lista_Ouro_com_Codigos_CEG.xlsx' \n")
print(head(lista_ouro_identificada))

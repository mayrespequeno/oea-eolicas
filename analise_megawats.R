top_10_estados <- eolicas_brasil %>%
  group_by(sig_uf_principal) %>%
  summarise(total_mw = sum(potencia_mw, na.rm = TRUE)) %>%
  arrange(desc(total_mw)) %>%
  head(10) %>%
  pull(sig_uf_principal) # Cria uma lista apenas com os nomes: "BA", "RN", etc.

dados_grafico <- eolicas_brasil %>%
  filter(sig_uf_principal %in% top_10_estados) %>%
  group_by(sig_uf_principal, status) %>%
  summarise(mw = sum(potencia_mw, na.rm = TRUE), .groups = "drop") %>%
  filter(status %in% c("Em Operação", "Em Obras"))

ggplot(dados_grafico, aes(x = reorder(sig_uf_principal, -mw), y = mw, fill = status)) +
  
 
  geom_col() +
  

  geom_text(
    aes(label = round(mw, 0)), 
    position = position_stack(vjust = 0.5), 
    color = "white",                        
    fontface = "bold",
    size = 3.5
  ) +
  
  scale_fill_manual(values = c("Em Operação" = "#27AE60",  # Verde
                               "Em Obras" = "#E67E22")) +  # Laranja

  labs(
    title = "Potência Eólica: Operação vs. Obras (Top 10 Estados)",
    subtitle = "Valores em Megawatts (MW)",
    x = "Estado",
    y = "Potência (MW)",
    fill = "Situação"
  ) +
  theme_minimal()

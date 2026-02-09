
top_10_qtd <- eolicas_brasil %>%
  count(sig_uf_principal, sort = TRUE) %>% # Conta quantos parques cada estado tem
  head(10) %>%
  pull(sig_uf_principal)

dados_grafico_qtd <- eolicas_brasil %>%
  filter(sig_uf_principal %in% top_10_qtd) %>%
  filter(status %in% c("Em Operação", "Em Obras")) %>%
  count(sig_uf_principal, status) 


ggplot(dados_grafico_qtd, aes(x = reorder(sig_uf_principal, -n), y = n, fill = status)) +
  geom_col() +
  geom_text(
    aes(label = n), 
    position = position_stack(vjust = 0.5), 
    color = "white",
    fontface = "bold",
    size = 3.5
  ) +
  
  scale_fill_manual(values = c("Em Operação" = "#27AE60", 
                               "Em Obras" = "#E67E22")) +
  
  labs(
    title = "Quantidade de Parques Eólicos: Operação vs. Obras",
    subtitle = "Número de Empreendimentos (Top 10 Estados)",
    x = "Estado",
    y = "Quantidade de Parques",
    fill = "Situação"
  ) +
  theme_minimal()

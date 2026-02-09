# -------------------------------------------------------------------------
# 5. ANÁLISE 3: MAPA DE CALOR (Localização)
# -------------------------------------------------------------------------
leaflet(eolicas_brasil) %>%
  addTiles() %>%
  addCircleMarkers(
    lng = ~lon, lat = ~lat,
    radius = ~sqrt(potencia_mw),
    
    # Cores baseadas no status corrigido
    color = ~case_when(
      status == "Em Operação" ~ "green",
      status == "Em Obras" ~ "orange",
      TRUE ~ "red"
    ),
    
    stroke = FALSE, fillOpacity = 0.6,
    
    # Popup informativo
    popup = ~paste("<b>", nom_empreendimento, "</b><br>",
                   "Fase Real:", dsc_fase_usina, "<br>",
                   "Status:", status, "<br>",
                   "Potência:", round(potencia_mw, 1), "MW")
  ) %>%
  addLegend("bottomright", 
            colors = c("green", "orange", "red"), 
            labels = c("Operação", "Obras", "Projeto/Outorga"))

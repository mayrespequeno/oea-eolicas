library(tidyverse)
library(leaflet)

# ==============================================================================
# PASSO 1: RECUPERAR COORDENADAS E CRIAR O TEXTO (Atualizado)
# ==============================================================================

# 1.1. Dicionário de Coordenadas
geo_usinas <- eolicas_brasil %>%
  select(nom_empreendimento, lat, lon) %>%
  distinct(nom_empreendimento, .keep_all = TRUE)

# 1.2. Criar o mapa_pares com o NOVO TEXTO
mapa_pares <- melhores_casos %>%
  
  # Traz coordenadas A
  left_join(geo_usinas, by = c("Parque_A" = "nom_empreendimento")) %>%
  rename(lat_A = lat, lon_A = lon) %>%
  
  # Traz coordenadas B
  left_join(geo_usinas, by = c("Parque_B" = "nom_empreendimento")) %>%
  rename(lat_B = lat, lon_B = lon) %>%
  
  filter(!is.na(lat_A) & !is.na(lat_B)) %>%
  
  # --- AQUI ESTÁ A MUDANÇA ---
  # Adicionamos Mun_A e Mun_B no texto do popup
  mutate(
    popup_texto = paste0(
      "<div style='font-family: Arial; font-size: 13px;'>",
      "<b>🏭 EMPRESA:</b> ", Empresa_Mae, "<hr>",
      
      "<b>🟢 LEGADO (", Mun_A, "):</b><br>",
      "Parque: ", Parque_A, "<br>",
      "Potência: ", round(MW_A, 1), " MW<br><br>",
      
      "<b>🟠 NOVO (", Mun_B, "):</b><br>",
      "Parque: ", Parque_B, "<br>",
      "Potência: ", round(MW_B, 1), " MW<br>",
      "<hr>",
      "<i>Diferença de Tamanho: ", round(diff_mw, 1), " MW</i>",
      "</div>"
    )
  )

# ==============================================================================
# PASSO 2: CALCULAR O CENTRO
# ==============================================================================
mapa_com_centro <- mapa_pares %>%
  mutate(
    lat_meio = (lat_A + lat_B) / 2,
    lon_meio = (lon_A + lon_B) / 2,
    id_visual = paste0(Empresa_Mae, " #", row_number())
  )

# ==============================================================================
# PASSO 3: PLOTAR O MAPA
# ==============================================================================
leaflet(mapa_com_centro) %>%
  addTiles() %>% 
  
  # Linhas de conexão
  {
    map_temp <- .
    for(i in 1:nrow(mapa_com_centro)) {
      map_temp <- addPolylines(
        map_temp,
        lng = c(mapa_com_centro$lon_A[i], mapa_com_centro$lon_B[i]),
        lat = c(mapa_com_centro$lat_A[i], mapa_com_centro$lat_B[i]),
        color = "#555", weight = 2, dashArray = "5, 5", opacity = 0.6
      )
    }
    map_temp
  } %>%
  
  # Parques Antigos (Verde)
  addCircleMarkers(
    lng = ~lon_A, lat = ~lat_A, group = "Parques",
    color = "#27AE60", radius = 6, fillOpacity = 0.9, stroke = FALSE,
    popup = ~popup_texto # Popup completo
  ) %>%
  
  # Parques Novos (Laranja)
  addCircleMarkers(
    lng = ~lon_B, lat = ~lat_B, group = "Parques",
    color = "#E67E22", radius = 6, fillOpacity = 0.9, stroke = FALSE,
    popup = ~popup_texto # Popup completo
  ) %>%
  
  # Rótulo Visual no meio da linha
  addLabelOnlyMarkers(
    lng = ~lon_meio, lat = ~lat_meio,
    label = ~id_visual, 
    labelOptions = labelOptions(
      noHide = TRUE, direction = 'top', textOnly = TRUE,
      style = list("color" = "black", "font-weight" = "bold", "font-size" = "11px", "text-shadow" = "2px 2px 0px white")
    )
  ) %>%
  
  # Pin Central (Clicável com Info Completa)
  addMarkers(
    lng = ~lon_meio, lat = ~lat_meio,
    popup = ~popup_texto,
    group = "Info do Par"
  ) %>%
  
  addLayersControl(overlayGroups = c("Parques", "Info do Par"), options = layersControlOptions(collapsed = FALSE))

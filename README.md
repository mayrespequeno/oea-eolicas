# 🌬️ Monitoramento e Comparação de Parques Eólicos - CLIMAE

![Status](https://img.shields.io/badge/Status-Em_Desenvolvimento-yellow)
![R](https://img.shields.io/badge/Made_with-R_Shiny-blue)
![License](https://img.shields.io/badge/License-MIT-green)

Este repositório contém uma aplicação web interativa desenvolvida em **R Shiny** para monitoramento, análise e comparação de empreendimentos eólicos no Nordeste brasileiro. 

O projeto utiliza dados abertos da ANEEL e implementa uma metodologia algorítmica para identificar "pares comparáveis" de usinas eólicas (Legado vs. Novo) para estudos de impacto socioambiental e corporativo.

🔗 **Acesse a aplicação online:** [Eólicas Parques - ShinyApps](https://mayres-pequeno.shinyapps.io/Eolicas_Parques/)

---

## 🎯 Objetivo do Projeto

O objetivo principal é fornecer uma ferramenta visual para pesquisadoresvisualizarem a expansão eólica no polígono das secas e dos ventos. Além da visualização geral, a ferramenta propõe um **Experimento de Pareamento** para isolar variáveis um estudo de caso.

## 🔬 Metodologia: O Experimento de Pares

Uma das funcionalidades centrais deste app é a identificação automática de pares de usinas eólicas.

1.  **Mineração de Texto:** Limpeza dos nomes dos proprietários na base da ANEEL para identificar grupos econômicos (ex: remove "SPE", "S.A.", "LTDA" para encontrar a "Empresa Mãe").
2.  **Categorização:** Separação dos parques em dois grupos:
    * 🟢 **Legado:** Parques já em operação consolidada.
    * 🟠 **Novo:** Parques em obras ou em fase de outorga recente.
3.  **Algoritmo de Matching:** O sistema cruza a base de dados consigo mesma para encontrar pares que atendam a **todos** os critérios:
    * Pertencem ao mesmo Grupo Econômico.
    * Estão localizados na região Nordeste.
    * Possuem **potência instalada (MW)** similar (diferença máxima de 15%).
4.  **Visualização:** Os pares selecionados são conectados no mapa, permitindo a análise geográfica da expansão da empresa (se é uma ampliação no mesmo terreno ou migração para novos municípios).
---

## 📂 Fonte de Dados

Os dados são públicos e obtidos diretamente do Portal de Dados Abertos da ANEEL:
* **Fonte:** [SIGA - Sistema de Informações de Geração da ANEEL](https://dadosabertos.aneel.gov.br/dataset/siga-sistema-de-informacoes-de-geracao-da-aneel)
* **Atualização:** O código baixa a versão diária mais recente disponível no portal.

---

## 👩‍💻 Autora

**Mayres Pequeno** | CLIMAE*


---

*Projeto desenvolvido como parte de pesquisas sobre transição energética e impactos socioambientais no Nordeste.*

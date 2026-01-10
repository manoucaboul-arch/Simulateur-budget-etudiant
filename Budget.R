# On charge les bibliothèques installées au préalable
install.packages("rsconnect")
library(shiny)
library(shinydashboard)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(rsconnect)
rsconnect::deployApp()

generer_donnees_temporelles <- function(montant, jour, nom, debut, fin, type) {
  sequence_mois <- seq(from = floor_date(debut, "month"), 
                       to = floor_date(fin, "month"), by = "month")
  
  jours_max <- days_in_month(sequence_mois)
  dates_flux <- as.Date(paste0(format(sequence_mois, "%Y-%m-"), pmin(jour, jours_max)))
  
  res <- tibble(
    date = dates_flux,
    montant = abs(montant) * if_else(type == "depense", -1, 1),
    label = nom
  )
  
  return(res %>% filter(date >= debut, date <= fin))
}

simuler_evolution_budget <- function(solde_init, debut, fin, flux_auto, flux_imprevus) {
  calendrier <- tibble(date = seq.Date(debut, fin, by = "day"))
  
  tous_flux <- bind_rows(flux_auto, flux_imprevus) %>% 
    group_by(date) %>% 
    summarise(m = sum(montant), .groups = "drop")
  
  res <- calendrier %>% 
    left_join(tous_flux, by = "date") %>%
    mutate(m = replace_na(m, 0), 
           solde = solde_init + cumsum(m)) 
  return(res)
}

analyser_risques_financiers <- function(df_evolution) {
  point_bas <- min(df_evolution$solde, na.rm = TRUE)
  # Utilisation de if_else pour la consistance Tidyverse
  tibble(
    mini = point_bas, 
    alerte = if_else(point_bas < 0, "DANGER", "OK"),
    couleur = if_else(point_bas < 0, "red", "green")
  )
}

# NOUVEAU: Option 1 - Analyse des dépenses moyennes
analyser_depenses <- function(flux_table) {
  depenses <- flux_table %>% filter(montant < 0)
  if(nrow(depenses) == 0) {
    return(tibble(moyenne = 0, mediane = 0, total = 0, nb = 0))
  }
  tibble(
    moyenne = mean(abs(depenses$montant)),
    mediane = median(abs(depenses$montant)),
    total = sum(abs(depenses$montant)),
    nb = nrow(depenses)
  )
}

# NOUVEAU: Option 2 - Prédiction avec tendance linéaire
predire_solde <- function(df_evolution, jours_futurs = 30) {
  # Régression linéaire simple sur les données existantes
  df_evolution$jour_num <- as.numeric(df_evolution$date - min(df_evolution$date))
  modele <- lm(solde ~ jour_num, data = df_evolution)
  
  # Projection
  derniere_date <- max(df_evolution$date)
  dates_futures <- seq.Date(derniere_date + 1, derniere_date + jours_futurs, by = "day")
  jours_futurs_num <- as.numeric(dates_futures - min(df_evolution$date))
  
  predictions <- predict(modele, newdata = tibble(jour_num = jours_futurs_num))
  
  tibble(
    date = dates_futures,
    solde_predit = predictions,
    type = "prédiction"
  )
}

ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(title = "Budget Master"),
  
  dashboardSidebar(
    h4("Paramètres", style="margin-left:15px"),
    numericInput("mon_solde_r", "Solde initial (€)", 1200),
    dateRangeInput("ma_periode_r", "Analyse sur", start = Sys.Date(), end = Sys.Date() + 120),
    
    hr(),
    h4("Flux Fixes", style="margin-left:15px"),
    numericInput("salaire_r", "Salaire (€)", 1800),
    sliderInput("jour_sal_r", "Jour de paye", 1, 31, 1),
    numericInput("loyer_r", "Loyer (€)", 700),
    sliderInput("jour_loy_r", "Jour loyer", 1, 31, 5),
    
    hr(),
    h4("Nouvel Imprévu", style="margin-left:15px"),
    textInput("nom_op", "Nom", ""),
    numericInput("prix_op", "Montant (€)", 0),
    selectInput("type_op", "Type", choices = c("Dépense" = "depense", "Revenu" = "revenu")),
    actionButton("bouton_ajout", "Ajouter", class = "btn-primary", style="width: 80%; margin-left:15px"),
    br(), br(),
    
    # NOUVEAU: Option 3 - Export CSV
    downloadButton("export_csv", "Exporter CSV", class = "btn-success", style="width: 80%; margin-left:15px"),
    br(), br(),
    
    actionButton("bouton_reset", "Reset", class = "btn-danger btn-xs", style="margin-left:15px")
  ),
  
  dashboardBody(
    fluidRow(
      valueBoxOutput("box_final"),
      valueBoxOutput("box_bas"),
      valueBoxOutput("box_alerte")
    ),
    
    # NOUVEAU: Option 1 - Statistiques des dépenses
    fluidRow(
      valueBoxOutput("box_moy_depense"),
      valueBoxOutput("box_total_depense"),
      valueBoxOutput("box_nb_depense")
    ),
    
    fluidRow(
      box(title = "Évolution de la Trésorerie", plotOutput("graph_principal"), width = 8),
      box(title = "Répartition", plotOutput("graph_camembert"), width = 4)
    ),
    
    # NOUVEAU: Option 2 - Graphique de prédiction
    fluidRow(
      box(title = "Prédiction Tendance (30 jours)", plotOutput("graph_prediction"), width = 12)
    ),
    
    box(title = "Détail des flux financiers", tableOutput("table_flux"), width = 12)
  )
)

server <- function(input, output, session) {
  mes_achats <- reactiveVal(tibble())
  
  observeEvent(input$bouton_ajout, {
    if(input$prix_op != 0 && input$nom_op != "") {
      nouveau <- tibble(
        date = Sys.Date(),
        montant = if_else(input$type_op == "depense", -abs(input$prix_op), abs(input$prix_op)),
        label = input$nom_op
      )
      mes_achats(bind_rows(mes_achats(), nouveau))
      updateTextInput(session, "nom_op", value = "")
      updateNumericInput(session, "prix_op", value = 0)
    }
  })
  
  observeEvent(input$bouton_reset, { mes_achats(tibble()) })
  
  calculs <- reactive({
    sal <- generer_donnees_temporelles(input$salaire_r, input$jour_sal_r, "Salaire", input$ma_periode_r[1], input$ma_periode_r[2], "revenu")
    loy <- generer_donnees_temporelles(input$loyer_r, input$jour_loy_r, "Loyer", input$ma_periode_r[1], input$ma_periode_r[2], "depense")
    
    flux_fixes <- bind_rows(sal, loy)
    evolution_df <- simuler_evolution_budget(input$mon_solde_r, input$ma_periode_r[1], input$ma_periode_r[2], flux_fixes, mes_achats())
    analyse <- analyser_risques_financiers(evolution_df)
    
    # NOUVEAU: Calcul des statistiques et prédictions
    flux_complet <- bind_rows(flux_fixes, mes_achats())
    stats_depenses <- analyser_depenses(flux_complet)
    prediction <- predire_solde(evolution_df)
    
    list(
      evolution = evolution_df, 
      table = flux_complet %>% arrange(date), 
      analyse = analyse,
      stats = stats_depenses,
      prediction = prediction
    )
  })
  
  output$graph_principal <- renderPlot({
    ggplot(calculs()$evolution, aes(date, solde)) +
      geom_line(color="#605ca8", size=1.2) + 
      geom_area(fill="#605ca8", alpha=0.1) +
      theme_minimal() + labs(x = NULL, y = "Solde Disponibles (€)")
  })
  
  # NOUVEAU: Option 2 - Graphique de prédiction
  output$graph_prediction <- renderPlot({
    df_reel <- calculs()$evolution %>% mutate(type = "réel")
    df_pred <- calculs()$prediction
    
    df_combine <- bind_rows(
      df_reel %>% select(date, solde_value = solde, type),
      df_pred %>% select(date, solde_value = solde_predit, type)
    )
    
    ggplot(df_combine, aes(x = date, y = solde_value, color = type, linetype = type)) +
      geom_line(size = 1) +
      scale_color_manual(values = c("réel" = "#605ca8", "prédiction" = "#ff7f0e")) +
      scale_linetype_manual(values = c("réel" = "solid", "prédiction" = "dashed")) +
      theme_minimal() +
      labs(x = NULL, y = "Solde (€)", color = "Type", linetype = "Type", 
           title = "Projection basée sur la tendance actuelle")
  })
  
  output$graph_camembert <- renderPlot({
    depenses <- calculs()$table %>% filter(montant < 0)
    if(nrow(depenses) > 0) {
      cam_data <- depenses %>% group_by(label) %>% summarise(total = sum(abs(montant)))
      ggplot(cam_data, aes(x="", y=total, fill=label)) +
        geom_bar(stat="identity") + coord_polar("y") +
        theme_void() + labs(fill="Poste")
    }
  })
  
  output$box_final <- renderValueBox({ valueBox(paste0(round(tail(calculs()$evolution$solde, 1), 2), "€"), "Solde Fin de Période") })
  output$box_bas <- renderValueBox({ valueBox(paste0(round(calculs()$analyse$mini, 2), "€"), "Point le plus bas", color = "orange") })
  output$box_alerte <- renderValueBox({ valueBox(calculs()$analyse$alerte, "Risque Découvert", color = calculs()$analyse$couleur) })
  
  # NOUVEAU: Option 1 - ValueBox des statistiques
  output$box_moy_depense <- renderValueBox({ 
    valueBox(paste0(round(calculs()$stats$moyenne, 2), "€"), "Dépense Moyenne", icon = icon("chart-line"), color = "blue") 
  })
  output$box_total_depense <- renderValueBox({ 
    valueBox(paste0(round(calculs()$stats$total, 2), "€"), "Total Dépenses", icon = icon("wallet"), color = "purple") 
  })
  output$box_nb_depense <- renderValueBox({ 
    valueBox(calculs()$stats$nb, "Nombre de Dépenses", icon = icon("list"), color = "teal") 
  })
  
  output$table_flux <- renderTable({ calculs()$table %>% mutate(date = as.character(date)) })
  
  # NOUVEAU: Option 3 - Export CSV
  output$export_csv <- downloadHandler(
    filename = function() {
      paste0("budget_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      write.csv(calculs()$evolution, file, row.names = FALSE)
    }
  )
}

shinyApp(ui, server)


# On charge les bibliothèques installées au préalable 

library(shiny)
library(shinydashboard)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)


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
    actionButton("bouton_reset", "Reset", class = "btn-danger btn-xs", style="margin-left:15px")
  ),
  
  dashboardBody(
    fluidRow(
      valueBoxOutput("box_final"),
      valueBoxOutput("box_bas"),
      valueBoxOutput("box_alerte")
    ),
    fluidRow(
      box(title = "Évolution de la Trésorerie", plotOutput("graph_principal"), width = 8),
      box(title = "Répartition", plotOutput("graph_camembert"), width = 4)
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
    
    list(
      evolution = evolution_df, 
      table = bind_rows(flux_fixes, mes_achats()) %>% arrange(date), 
      analyse = analyse
    )
  })
  
  output$graph_principal <- renderPlot({
    ggplot(calculs()$evolution, aes(date, solde)) +
      geom_line(color="#605ca8", size=1.2) + 
      geom_area(fill="#605ca8", alpha=0.1) +
      theme_minimal() + labs(x = NULL, y = "Solde Disponibles (€)")
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
  
  output$table_flux <- renderTable({ calculs()$table %>% mutate(date = as.character(date)) })
}

shinyApp(ui, server)

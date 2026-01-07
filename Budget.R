library(shiny)
library(shinydashboard)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(rsconnect)
# ============================================================
# PARTIE 1 : LES FONCTIONS DE CALCUL (LE "MOTEUR")
# ============================================================

# Fonction pour transformer un montant mensuel en plusieurs dates
generer_repetitions <- function(montant, jour_vise, nom, debut, fin, type) {
  
  sequence_mois <- seq(from = as.Date(format(debut, "%Y-%m-01")),
                       to   = as.Date(format(fin, "%Y-%m-01")),
                       by   = "month")
  
  multiplicateur <- if(type == "depense") -1 else 1
  df_final <- data.frame()
  
  for(m in as.character(sequence_mois)) {
    date_en_cours <- as.Date(m)
    jour_reel <- min(jour_vise, days_in_month(date_en_cours))
    
    ligne <- data.frame(
      date = as.Date(format(date_en_cours, paste0("%Y-%m-", jour_reel))),
      montant = abs(montant) * multiplicateur,
      label = nom
    )
    df_final <- bind_rows(df_final, ligne)
  }
  return(df_final %>% filter(date >= debut, date <= fin))
}

# ============================================================
# PARTIE 2 : L'INTERFACE (UI)
# ============================================================
ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(title = "Gestion Budget Emma"),
  
  dashboardSidebar(
    h4("Configuration", style="margin-left:15px"),
    numericInput("mon_solde_r", "Argent au départ (€)", 1200),
    dateRangeInput("ma_periode_r", "Période d'analyse", start = Sys.Date(), end = Sys.Date() + 120),
    
    hr(),
    h4("Automatique", style="margin-left:15px"),
    numericInput("salaire_r", "Mon Salaire (€)", 1800),
    sliderInput("jour_sal_r", "Jour de paye", 1, 31, 1),
    numericInput("loyer_r", "Mon Loyer (€)", 700),
    sliderInput("jour_loy_r", "Jour loyer", 1, 31, 5),
    
    hr(),
    h4("Ajouter un imprévu", style="margin-left:15px"),
    textInput("nom_op", "Libellé", ""),
    numericInput("prix_op", "Montant (€)", 0),
    selectInput("type_op", "Type", choices = c("Dépense" = "depense", "Revenu" = "revenu")),
    actionButton("bouton_ajout", "Valider", class = "btn-primary", style="width: 80%; margin-left:15px"),
    
    br(), br(),
    # LE BOUTON REINITIALISER
    actionButton("bouton_reset", "Réinitialiser les imprévus", class = "btn-danger btn-xs", style="margin-left:15px")
  ),
  
  dashboardBody(
    tags$head(tags$script(src = "https://cdn.jsdelivr.net/npm/canvas-confetti@1.5.1/dist/confetti.browser.min.js")),
    
    fluidRow(
      valueBoxOutput("box_final"),
      valueBoxOutput("box_bas"),
      valueBoxOutput("box_alerte")
    ),
    fluidRow(
      box(title = "Graphique de Trésorerie", plotOutput("graph_principal"), width = 8),
      box(title = "Répartition", plotOutput("graph_camembert"), width = 4)
    ),
    box(title = "Historique des opérations", tableOutput("table_flux"), width = 12)
  )
)

# ============================================================
# PARTIE 3 : LE SERVEUR
# ============================================================
server <- function(input, output, session) {
  
  # Mémoire pour les ajouts manuels (le reactiveVal est comme une boîte vide au début)
  mes_achats <- reactiveVal(data.frame())
  
  # Action quand on clique sur Valider
  observeEvent(input$bouton_ajout, {
    if(input$prix_op != 0 && input$nom_op != "") {
      nouveau <- data.frame(
        date = Sys.Date(),
        montant = if(input$type_op == "depense") -abs(input$prix_op) else abs(input$prix_op),
        label = input$nom_op
      )
      mes_achats(bind_rows(mes_achats(), nouveau))
      
      # On vide les cases après l'ajout pour faire propre
      updateTextInput(session, "nom_op", value = "")
      updateNumericInput(session, "prix_op", value = 0)
    }
  })
  
  # Action quand on clique sur Réinitialiser
  observeEvent(input$bouton_reset, {
    mes_achats(data.frame()) # On remet la boîte à vide
  })
  
  # Le coeur du calcul réactif
  calculs <- reactive({
    sal <- generer_repetitions(input$salaire_r, input$jour_sal_r, "Salaire (Auto)", input$ma_periode_r[1], input$ma_periode_r[2], "revenu")
    loy <- generer_repetitions(input$loyer_r, input$jour_loy_r, "Loyer (Auto)", input$ma_periode_r[1], input$ma_periode_r[2], "depense")
    
    tout <- bind_rows(sal, loy, mes_achats()) %>% arrange(date)
    
    jours <- data.frame(date = seq.Date(input$ma_periode_r[1], input$ma_periode_r[2], by = "day"))
    
    evolution <- jours %>% 
      left_join(tout %>% group_by(date) %>% summarise(m = sum(montant)), by = "date") %>%
      mutate(m = replace_na(m, 0), solde = input$mon_solde_r + cumsum(m))
    
    return(list(evolution = evolution, table = tout, mini = min(evolution$solde)))
  })
  
  # Graphique principal
  output$graph_principal <- renderPlot({
    ggplot(calculs()$evolution, aes(date, solde)) +
      geom_line(color="#605ca8", size=1) + 
      geom_area(fill="#605ca8", alpha=0.2) +
      theme_minimal() + labs(x = "Temps", y = "Argent (€)")
  })
  
  # Camembert simplifié
  output$graph_camembert <- renderPlot({
    depenses <- calculs()$table %>% filter(montant < 0)
    if(nrow(depenses) > 0) {
      # On agrège par label pour ne pas avoir 50 parts si on a 50 fois 'Courses'
      cam_data <- depenses %>% group_by(label) %>% summarise(total = sum(abs(montant)))
      pie(cam_data$total, labels = cam_data$label, col = terrain.colors(nrow(cam_data)), main = "Où part l'argent")
    }
  })
  
  # ValueBoxes
  output$box_final <- renderValueBox({ valueBox(paste0(tail(calculs()$evolution$solde, 1), "€"), "Solde final") })
  output$box_bas <- renderValueBox({ valueBox(paste0(calculs()$mini, "€"), "Point bas", color = "orange") })
  output$box_alerte <- renderValueBox({
    statut <- if(calculs()$mini < 0) "DANGER" else "OK"
    valueBox(statut, "Alerte Découvert", color = if(statut == "OK") "green" else "red")
  })
  
  # Tableau historique
  output$table_flux <- renderTable({ 
    calculs()$table %>% mutate(date = as.character(date)) 
  })
}

shinyApp(ui, server)

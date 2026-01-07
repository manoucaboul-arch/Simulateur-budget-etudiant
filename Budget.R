library(shiny)
library(shinydashboard)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(rsconnect)

# ============================================================
# PARTIE 1 : LES 3 FONCTIONS PILIERS (LE MOTEUR)
# ============================================================

# 1. GÉNÉRATEUR AUTOMATISÉ 
# Transforme une saisie en série de données sur le calendrier
generer_donnees_temporelles <- function(montant, jour, nom, debut, fin, type) {
  sequence <- seq(from = as.Date(format(debut, "%Y-%m-01")), 
                  to = as.Date(format(fin, "%Y-%m-01")), by = "month")
  mult <- if(type == "depense") -1 else 1
  
  df <- lapply(sequence, function(m) {
    d <- as.Date(m)
    date_flux <- as.Date(format(d, paste0("%Y-%m-", min(jour, days_in_month(d)))))
    data.frame(date = date_flux, montant = abs(montant) * mult, label = nom)
  }) %>% bind_rows() 
  
  return(df %>% filter(date >= debut, date <= fin))
}

# 2. SIMULATEUR DE TRÉSORERIE 
# Fusionne les flux et calcule le solde cumulé jour par jour
simuler_evolution_budget <- function(solde_init, debut, fin, flux_auto, flux_imprevus) {
  calendrier <- data.frame(date = seq.Date(debut, fin, by = "day"))
  tous_flux <- bind_rows(flux_auto, flux_imprevus) %>% 
    group_by(date) %>% 
    summarise(m = sum(montant), .groups = "drop")
  
  res <- calendrier %>% 
    left_join(tous_flux, by = "date") %>%
    mutate(m = replace_na(m, 0), 
           solde = solde_init + cumsum(m))
  return(res)
}

# 3. ANALYSEUR DE RISQUE 
# Extrait les indicateurs de sécurité financière
analyser_risques_financiers <- function(df_evolution) {
  point_bas <- min(df_evolution$solde)
  list(
    mini = point_bas, 
    alerte = if(point_bas < 0) "DANGER" else "OK",
    couleur = if(point_bas < 0) "red" else "green"
  )
}

# ============================================================
# PARTIE 2 : L'INTERFACE (UI)
# ============================================================
ui <- dashboardPage(
  skin = "purple",
  dashboardHeader(title = "Gestion Budget"),
  
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
    actionButton("bouton_reset", "Réinitialiser", class = "btn-danger btn-xs", style="margin-left:15px")
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
# PARTIE 3 : LE SERVEUR (LOGIQUE RÉACTIVE)
# ============================================================
server <- function(input, output, session) {
  
  # Mémoire réactive pour les imprévus
  mes_achats <- reactiveVal(data.frame())
  
  observeEvent(input$bouton_ajout, {
    if(input$prix_op != 0 && input$nom_op != "") {
      nouveau <- data.frame(
        date = Sys.Date(),
        montant = if(input$type_op == "depense") -abs(input$prix_op) else abs(input$prix_op),
        label = input$nom_op
      )
      mes_achats(bind_rows(mes_achats(), nouveau))
      updateTextInput(session, "nom_op", value = "")
      updateNumericInput(session, "prix_op", value = 0)
    }
  })
  
  observeEvent(input$bouton_reset, { mes_achats(data.frame()) })
  
  # Bloc de calcul central utilisant les 3 fonctions piliers
  calculs <- reactive({
    # Utilisation Pilier 1 : Génération des flux fixes
    sal <- generer_donnees_temporelles(input$salaire_r, input$jour_sal_r, "Salaire", input$ma_periode_r[1], input$ma_periode_r[2], "revenu")
    loy <- generer_donnees_temporelles(input$loyer_r, input$jour_loy_r, "Loyer", input$ma_periode_r[1], input$ma_periode_r[2], "depense")
    flux_fixes <- bind_rows(sal, loy)
    
    # Utilisation Pilier 2 : Simulation globale
    evolution_df <- simuler_evolution_budget(input$mon_solde_r, input$ma_periode_r[1], input$ma_periode_r[2], flux_fixes, mes_achats())
    
    # Utilisation Pilier 3 : Analyse des risques
    analyse <- analyser_risques_financiers(evolution_df)
    
    return(list(evolution = evolution_df, table = bind_rows(flux_fixes, mes_achats()) %>% arrange(date), analyse = analyse))
  })
  
  # Sorties graphiques et indicateurs
  output$graph_principal <- renderPlot({
    ggplot(calculs()$evolution, aes(date, solde)) +
      geom_line(color="#605ca8", size=1) + geom_area(fill="#605ca8", alpha=0.2) +
      theme_minimal() + labs(x = "Temps", y = "Argent (€)")
  })
  
  output$graph_camembert <- renderPlot({
    depenses <- calculs()$table %>% filter(montant < 0)
    if(nrow(depenses) > 0) {
      cam_data <- depenses %>% group_by(label) %>% summarise(total = sum(abs(montant)))
      pie(cam_data$total, labels = cam_data$label, col = terrain.colors(nrow(cam_data)), main = "Où part l'argent")
    }
  })
  
  output$box_final <- renderValueBox({ valueBox(paste0(tail(calculs()$evolution$solde, 1), "€"), "Solde final") })
  output$box_bas <- renderValueBox({ valueBox(paste0(calculs()$analyse$mini, "€"), "Point bas", color = "orange") })
  output$box_alerte <- renderValueBox({
    valueBox(calculs()$analyse$alerte, "Alerte Découvert", color = calculs()$analyse$couleur)
  })
  
  output$table_flux <- renderTable({ calculs()$table %>% mutate(date = as.character(date)) })
}

shinyApp(ui, server)

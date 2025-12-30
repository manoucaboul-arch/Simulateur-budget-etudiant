
on commence par importer les libraries 


install.packages(c(
  "dplyr",
  "tidyr",
  "lubridate",
  "ggplot2",
  "shiny",
  "shinydashboard"
))


on regroupe les données saisies par l'utilisateur dans une seule structure propre : 

charger_parametres <- function(solde_initial,
                               revenu_mensuel,
                               charges_fixes,
                               depenses_variables) {
  
  list(
    solde_initial = solde_initial,
    revenu_mensuel = revenu_mensuel,
    charges_fixes = charges_fixes,
    depenses_variables = depenses_variables
  )
}


On transforme les données utilisateur en mouvement datés (

generer_flux_journaliers <- function(params, date_debut, date_fin) {
  
  # Séquence de dates du mois
  dates <- seq.Date(date_debut, date_fin, by = "day")
  
  # 1. Revenu(s) : l'utilisateur doit fournir un data.frame
  #    avec au minimum : date, montant, categorie
  revenus <- params$revenus %>%
    mutate(type = "credit")
  
  # 2. Charges fixes : déjà datées par l'utilisateur
  charges <- params$charges_fixes %>%
    mutate(type = "debit")
  
  # 3. Dépenses variables : l'utilisateur fournit un tableau
  #    avec (date, montant, categorie) OU une logique externe
  depenses_var <- params$depenses_variables %>%
    mutate(type = "debit")
  
  # 4. Fusionner tous les flux
  flux <- bind_rows(revenus, charges, depenses_var) %>%
    filter(date >= date_debut, date <= date_fin) %>%
    arrange(date)
  
  return(flux)
}


Calculer le solde jour par jour 

simuler_solde <- function(flux, solde_initial, date_debut, date_fin) {
  
  dates <- seq.Date(date_debut, date_fin, by = "day")
  base <- data.frame(date = dates)
  
  flux_jour <- flux %>%
    group_by(date) %>%
    summarise(montant_jour = sum(montant), .groups = "drop")
  
  df <- base %>%
    left_join(flux_jour, by = "date") %>%
    mutate(montant_jour = ifelse(is.na(montant_jour), 0, montant_jour),
           solde = solde_initial + cumsum(montant_jour))
  
  df
}


Analyser la simulation et détecter un éventuel découvert 

detecter_risque <- function(df_solde) {
  
  solde_min <- min(df_solde$solde)
  risque <- ifelse(solde_min < 0, "Découvert", "OK")
  
  date_decouvert <- if (risque == "Découvert") {
    df_solde$date[df_solde$solde < 0][1]
  } else {
    NA
  }
  
  list(
    risque = risque,
    solde_min = solde_min,
    date_decouvert = date_decouvert
  )
}
# ============================================================================
# SIMULATEUR BUDGET ÉTUDIANT - APPLICATION SHINY COMPLÈTE
# ============================================================================

# Installation des packages (à exécuter une seule fois)
# install.packages(c("dplyr", "tidyr", "lubridate", "ggplot2", "shiny", "shinydashboard"))

# Chargement des bibliothèques
library(shiny)
library(shinydashboard)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)

# ============================================================================
# FONCTIONS MÉTIER (créées par votre binôme)
# ============================================================================

# Fonction 1 : Charger les paramètres utilisateur
charger_parametres <- function(solde_initial,
                               revenu_mensuel,
                               charges_fixes,
                               depenses_variables) {
  
  list(
    solde_initial = solde_initial,
    revenu_mensuel = revenu_mensuel,
    charges_fixes = charges_fixes,
    depenses_variables = depenses_variables
  )
}

# Fonction 2 : Générer les flux journaliers
generer_flux_journaliers <- function(params, date_debut, date_fin) {
  
  # Séquence de dates du mois
  dates <- seq.Date(date_debut, date_fin, by = "day")
  
  # 1. Revenus
  revenus <- params$revenus %>%
    mutate(type = "credit")
  
  # 2. Charges fixes
  charges <- params$charges_fixes %>%
    mutate(type = "debit")
  
  # 3. Dépenses variables
  depenses_var <- params$depenses_variables %>%
    mutate(type = "debit")
  
  # 4. Fusionner tous les flux
  flux <- bind_rows(revenus, charges, depenses_var) %>%
    filter(date >= date_debut, date <= date_fin) %>%
    arrange(date)
  
  return(flux)
}

# Fonction 3 : Simuler le solde jour par jour
simuler_solde <- function(flux, solde_initial, date_debut, date_fin) {
  
  dates <- seq.Date(date_debut, date_fin, by = "day")
  base <- data.frame(date = dates)
  
  flux_jour <- flux %>%
    group_by(date) %>%
    summarise(montant_jour = sum(montant), .groups = "drop")
  
  df <- base %>%
    left_join(flux_jour, by = "date") %>%
    mutate(montant_jour = ifelse(is.na(montant_jour), 0, montant_jour),
           solde = solde_initial + cumsum(montant_jour))
  
  df
}

# Fonction 4 : Détecter les risques de découvert
detecter_risque <- function(df_solde) {
  
  solde_min <- min(df_solde$solde)
  risque <- ifelse(solde_min < 0, "Découvert", "OK")
  
  date_decouvert <- if (risque == "Découvert") {
    df_solde$date[df_solde$solde < 0][1]
  } else {
    NA
  }
  
  list(
    risque = risque,
    solde_min = solde_min,
    date_decouvert = date_decouvert
  )
}

# ============================================================================
# INTERFACE UTILISATEUR (UI)
# ============================================================================

ui <- dashboardPage(
  
  # En-tête
  dashboardHeader(title = "💰 Budget Étudiant"),
  
  # Barre latérale
  dashboardSidebar(
    sidebarMenu(
      menuItem("🏠 Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("⚙️ Paramètres", tabName = "parametres", icon = icon("cogs")),
      menuItem("📊 Analyse", tabName = "analyse", icon = icon("chart-line"))
    )
  ),
  
  # Corps principal
  dashboardBody(
    
    tags$head(
      tags$style(HTML("
        .box.box-solid.box-primary>.box-header {
          color:#fff;
          background:#3c8dbc
        }
        .box.box-solid.box-success>.box-header {
          color:#fff;
          background:#00a65a
        }
        .box.box-solid.box-danger>.box-header {
          color:#fff;
          background:#dd4b39
        }
      "))
    ),
    
    tabItems(
      
      # ========== ONGLET 1 : DASHBOARD ==========
      tabItem(
        tabName = "dashboard",
        
        fluidRow(
          # Box : Solde actuel
          valueBoxOutput("solde_final_box", width = 4),
          # Box : Solde minimum
          valueBoxOutput("solde_min_box", width = 4),
          # Box : Statut risque
          valueBoxOutput("risque_box", width = 4)
        ),
        
        fluidRow(
          # Graphique : Évolution du solde
          box(
            title = "📈 Évolution du solde journalier",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotOutput("graphique_solde", height = "350px")
          )
        ),
        
        fluidRow(
          # Graphique : Répartition des dépenses
          box(
            title = "🍕 Répartition des dépenses",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotOutput("graphique_repartition", height = "300px")
          ),
          
          # Tableau : Détail des flux
          box(
            title = "📋 Détail des flux",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            tableOutput("tableau_flux")
          )
        )
      ),
      
      # ========== ONGLET 2 : PARAMÈTRES ==========
      tabItem(
        tabName = "parametres",
        
        fluidRow(
          box(
            title = "💵 Paramètres financiers",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            
            numericInput("solde_initial", 
                         "Solde initial (€)", 
                         value = 1000, 
                         min = 0, 
                         step = 50),
            
            dateInput("date_debut", 
                      "Date de début", 
                      value = floor_date(Sys.Date(), "month")),
            
            dateInput("date_fin", 
                      "Date de fin", 
                      value = ceiling_date(Sys.Date(), "month") - days(1)),
            
            hr(),
            
            h4("💰 Revenus"),
            numericInput("revenu_montant", 
                         "Montant du revenu (€)", 
                         value = 800, 
                         min = 0),
            
            dateInput("revenu_date", 
                      "Date de versement", 
                      value = floor_date(Sys.Date(), "month") + days(4)),
            
            textInput("revenu_categorie", 
                      "Catégorie", 
                      value = "Bourse")
          ),
          
          box(
            title = "💳 Charges & Dépenses",
            status = "danger",
            solidHeader = TRUE,
            width = 6,
            
            h4("🏠 Charges fixes"),
            numericInput("loyer_montant", 
                         "Loyer (€)", 
                         value = 400, 
                         min = 0),
            
            dateInput("loyer_date", 
                      "Date de prélèvement", 
                      value = floor_date(Sys.Date(), "month") + days(4)),
            
            numericInput("internet_montant", 
                         "Internet/Téléphone (€)", 
                         value = 30, 
                         min = 0),
            
            dateInput("internet_date", 
                      "Date de prélèvement", 
                      value = floor_date(Sys.Date(), "month") + days(9)),
            
            hr(),
            
            h4("🛒 Dépenses variables quotidiennes"),
            numericInput("depense_quotidienne", 
                         "Dépense moyenne par jour (€)", 
                         value = 15, 
                         min = 0),
            
            sliderInput("variation_depense", 
                        "Variation (+/-)", 
                        min = 0, 
                        max = 20, 
                        value = 10, 
                        step = 1)
          )
        ),
        
        fluidRow(
          box(
            width = 12,
            actionButton("simuler_btn", 
                         "🚀 Lancer la simulation", 
                         class = "btn-primary btn-lg",
                         style = "width: 100%;")
          )
        )
      ),
      
      # ========== ONGLET 3 : ANALYSE ==========
      tabItem(
        tabName = "analyse",
        
        fluidRow(
          box(
            title = "📊 Statistiques détaillées",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            
            verbatimTextOutput("statistiques_texte")
          )
        ),
        
        fluidRow(
          box(
            title = "⚠️ Alertes et recommandations",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            
            uiOutput("alertes_ui")
          )
        )
      )
    )
  )
)

# ============================================================================
# SERVEUR
# ============================================================================

server <- function(input, output, session) {
  
  # Variable réactive pour stocker les résultats de simulation
  simulation_data <- reactiveValues(
    df_solde = NULL,
    flux = NULL,
    risque_info = NULL
  )
  
  # Observer : Lancer la simulation
  observeEvent(input$simuler_btn, {
    
    # Préparer les données de revenus
    revenus_df <- data.frame(
      date = input$revenu_date,
      montant = input$revenu_montant,
      categorie = input$revenu_categorie
    )
    
    # Préparer les charges fixes
    charges_df <- data.frame(
      date = c(input$loyer_date, input$internet_date),
      montant = c(-input$loyer_montant, -input$internet_montant),
      categorie = c("Loyer", "Internet/Téléphone")
    )
    
    # Générer les dépenses variables (quotidiennes avec variation aléatoire)
    dates_periode <- seq.Date(input$date_debut, input$date_fin, by = "day")
    depenses_var_df <- data.frame(
      date = dates_periode,
      montant = -(input$depense_quotidienne + 
                    runif(length(dates_periode), 
                          -input$variation_depense, 
                          input$variation_depense)),
      categorie = "Dépenses courantes"
    )
    
    # Créer les paramètres
    params <- list(
      revenus = revenus_df,
      charges_fixes = charges_df,
      depenses_variables = depenses_var_df
    )
    
    # Générer les flux
    flux <- generer_flux_journaliers(params, input$date_debut, input$date_fin)
    
    # Simuler le solde
    df_solde <- simuler_solde(flux, input$solde_initial, 
                              input$date_debut, input$date_fin)
    
    # Détecter les risques
    risque_info <- detecter_risque(df_solde)
    
    # Sauvegarder dans les variables réactives
    simulation_data$df_solde <- df_solde
    simulation_data$flux <- flux
    simulation_data$risque_info <- risque_info
    
    showNotification("✅ Simulation terminée avec succès !", 
                     type = "message", 
                     duration = 3)
  })
  
  # ========== OUTPUTS DASHBOARD ==========
  
  # ValueBox : Solde final
  output$solde_final_box <- renderValueBox({
    req(simulation_data$df_solde)
    
    solde_final <- tail(simulation_data$df_solde$solde, 1)
    couleur <- ifelse(solde_final >= 0, "green", "red")
    
    valueBox(
      value = paste0(round(solde_final, 2), " €"),
      subtitle = "Solde final du mois",
      icon = icon("wallet"),
      color = couleur
    )
  })
  
  # ValueBox : Solde minimum
  output$solde_min_box <- renderValueBox({
    req(simulation_data$risque_info)
    
    solde_min <- simulation_data$risque_info$solde_min
    couleur <- ifelse(solde_min >= 0, "yellow", "red")
    
    valueBox(
      value = paste0(round(solde_min, 2), " €"),
      subtitle = "Solde minimum atteint",
      icon = icon("chart-line"),
      color = couleur
    )
  })
  
  # ValueBox : Risque
  output$risque_box <- renderValueBox({
    req(simulation_data$risque_info)
    
    risque <- simulation_data$risque_info$risque
    couleur <- ifelse(risque == "OK", "green", "red")
    icone <- ifelse(risque == "OK", "check-circle", "exclamation-triangle")
    
    valueBox(
      value = risque,
      subtitle = "Statut du budget",
      icon = icon(icone),
      color = couleur
    )
  })
  
  # Graphique : Évolution du solde
  output$graphique_solde <- renderPlot({
    req(simulation_data$df_solde)
    
    ggplot(simulation_data$df_solde, aes(x = date, y = solde)) +
      geom_line(color = "#3c8dbc", size = 1.2) +
      geom_hline(yintercept = 0, color = "red", linetype = "dashed", size = 1) +
      geom_point(color = "#3c8dbc", size = 2) +
      labs(title = "Évolution du solde jour par jour",
           x = "Date",
           y = "Solde (€)") +
      theme_minimal(base_size = 14) +
      theme(plot.title = element_text(face = "bold", hjust = 0.5))
  })
  
  # Graphique : Répartition des dépenses
  output$graphique_repartition <- renderPlot({
    req(simulation_data$flux)
    
    depenses <- simulation_data$flux %>%
      filter(type == "debit") %>%
      group_by(categorie) %>%
      summarise(total = sum(abs(montant)), .groups = "drop")
    
    ggplot(depenses, aes(x = "", y = total, fill = categorie)) +
      geom_bar(stat = "identity", width = 1) +
      coord_polar("y") +
      labs(title = "Répartition des dépenses par catégorie",
           fill = "Catégorie") +
      theme_void(base_size = 12) +
      theme(plot.title = element_text(face = "bold", hjust = 0.5))
  })
  
  # Tableau : Détail des flux
  output$tableau_flux <- renderTable({
    req(simulation_data$flux)
    
    simulation_data$flux %>%
      arrange(desc(date)) %>%
      head(10) %>%
      mutate(date = format(date, "%d/%m/%Y"),
             montant = round(montant, 2)) %>%
      select(Date = date, Montant = montant, Catégorie = categorie, Type = type)
  })
  
  # ========== OUTPUTS ANALYSE ==========
  
  # Statistiques textuelles
  output$statistiques_texte <- renderText({
    req(simulation_data$df_solde, simulation_data$flux, simulation_data$risque_info)
    
    solde_final <- tail(simulation_data$df_solde$solde, 1)
    solde_min <- simulation_data$risque_info$solde_min
    
    total_revenus <- sum(simulation_data$flux$montant[simulation_data$flux$type == "credit"])
    total_depenses <- sum(abs(simulation_data$flux$montant[simulation_data$flux$type == "debit"]))
    
    epargne <- solde_final - input$solde_initial
    
    nb_jours_decouvert <- sum(simulation_data$df_solde$solde < 0)
    
    paste0(
      "📊 RAPPORT DE SIMULATION\n",
      "========================\n\n",
      "💰 Solde initial : ", round(input$solde_initial, 2), " €\n",
      "💵 Solde final : ", round(solde_final, 2), " €\n",
      "📉 Solde minimum : ", round(solde_min, 2), " €\n\n",
      "💸 Total des revenus : ", round(total_revenus, 2), " €\n",
      "💳 Total des dépenses : ", round(total_depenses, 2), " €\n\n",
      "💎 Épargne réalisée : ", round(epargne, 2), " €\n",
      "⚠️ Nombre de jours en découvert : ", nb_jours_decouvert, "\n\n",
      "📈 Statut : ", simulation_data$risque_info$risque
    )
  })
  
  # Alertes et recommandations
  output$alertes_ui <- renderUI({
    req(simulation_data$risque_info)
    
    if (simulation_data$risque_info$risque == "Découvert") {
      tagList(
        tags$div(
          class = "alert alert-danger",
          style = "font-size: 16px;",
          tags$strong("⚠️ ALERTE DÉCOUVERT !"),
          tags$p(
            paste0("Votre compte sera en découvert à partir du ",
                   format(simulation_data$risque_info$date_decouvert, "%d/%m/%Y"),
                   ". Solde minimum : ",
                   round(simulation_data$risque_info$solde_min, 2), " €")
          ),
          tags$hr(),
          tags$p(
            tags$strong("💡 Recommandations :"),
            tags$ul(
              tags$li("Réduisez vos dépenses variables quotidiennes"),
              tags$li("Cherchez des revenus complémentaires (job étudiant)"),
              tags$li("Négociez un découvert autorisé avec votre banque")
            )
          )
        )
      )
    } else {
      tagList(
        tags$div(
          class = "alert alert-success",
          style = "font-size: 16px;",
          tags$strong("✅ Budget équilibré !"),
          tags$p("Votre budget est sain ce mois-ci. Continuez ainsi !"),
          tags$hr(),
          tags$p(
            tags$strong("💡 Conseil :"),
            tags$ul(
              tags$li("Constituez une épargne de sécurité"),
              tags$li("Suivez régulièrement vos dépenses"),
              tags$li("Anticipez les dépenses exceptionnelles")
            )
          )
        )
      )
    }
  })
}

# ============================================================================
# LANCER L'APPLICATION
# ============================================================================

shinyApp(ui = ui, server = server)




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




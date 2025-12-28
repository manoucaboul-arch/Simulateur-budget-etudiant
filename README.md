# Simulateur-budget-etudiant
Ce projet à poour but d'être un outil interactif permettant aux étudiant d'estimer automatiquement leur budget mensuel à partir de donnée financière. Le programme simule l'évolution du solde jour par jour, identifie les risques de découvert et visualise les résultats dans un dashboard

## Context et Motivation 

En tant qu'étudiant, on doit souvent
L'argent peut-être une source de stress constante, difficulté à ouvrir son compte d'où l'idée d'avoir un simulateur à partir duquel on pourrait suivre ses dépenses jour après jour et avoir des projections. 


## Bibliothèques 

install.packages(c(
  "dplyr",        # manipulation des données
  "tidyr",        # nettoyage et structuration
  "lubridate",    # gestion des dates (indispensable pour simuler un mois)
  "ggplot2",      # graphiques (solde, dépenses)
  "shiny",        # dashboard interactif
  "shinydashboard" # mise en page du dashboard
))


dplyr : manipulation des données (filtrer, trier, calculer)
tidyr : mise en forme des données (réorganiser, nettoyer)
lubridate : gestion des dates (jours, mois, séquences)
ggplot2 : graphiques (courbe du solde, dépenses)
shiny : créer l’application interactive
shinydashboard : mise en page du dashboard

## On va definir les fonctions 

# Ici, on regroupe les fonctions qui vont être remplies par l'utilisateur 

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




ici on ajoute les mouvements 

generer_flux_journaliers <- function(params, date_debut, date_fin) {
  
  dates <- seq.Date(date_debut, date_fin, by = "day")
  
  # Revenu (ex : le 5 du mois)
  revenu <- data.frame(
    date = date_debut + 4,
    montant = params$revenu_mensuel,
    categorie = "Revenu",
    type = "credit"
  )
  
  # Charges fixes (déjà datées)
  charges <- params$charges_fixes %>%
    mutate(type = "debit")
  
  # Dépenses variables réparties sur le mois (simplifié)
  dep_var <- params$depenses_variables %>%
    rowwise() %>%
    do({
      jours <- sample(dates, 4)
      data.frame(
        date = jours,
        montant = -.$montant_total / 4,
        categorie = .$categorie,
        type = "debit"
      )
    })
  
  bind_rows(revenu, charges, dep_var) %>% arrange(date)
}

### Simuler solde 

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

### Détecter le solde

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


=> définir 

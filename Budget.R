

# On commence par charger et installer les bibliothèques déjà installées au préalables. 
library(dplyr)
library(tidyr)
library(lubridate)

# Première étape :
#  On commence par charger les données utilisateurs

charger_parametres <- function(solde_initial,
                               revenus,
                               charges_fixes,
                               depenses_variables) {
  
  list(
    solde_initial = solde_initial,
    revenus = revenus,
    charges_fixes = charges_fixes,
    depenses_variables = depenses_variables
  )
}

# Deuxième étape : 
# On génère les flux journaliers


generer_flux_journaliers <- function(params, date_debut, date_fin) {
  
  # Vérification minimale des colonnes attendues
  check_cols <- function(df, nom) {
    if (!all(c("date", "montant") %in% names(df))) {
      stop(paste("Le tableau", nom, "doit contenir au moins : date, montant"))
    }
  }
  
  check_cols(params$revenus, "revenus")
  check_cols(params$charges_fixes, "charges_fixes")
  check_cols(params$depenses_variables, "depenses_variables")
  
  # Revenus
  revenus <- params$revenus %>%
    mutate(type = "credit")
  
  # Charges fixes
  charges <- params$charges_fixes %>%
    mutate(type = "debit")
  
  # Dépenses variables
  depenses_var <- params$depenses_variables %>%
    mutate(type = "debit")
  
  # Fusion
  flux <- bind_rows(revenus, charges, depenses_var) %>%
    filter(date >= date_debut, date <= date_fin) %>%
    arrange(date)
  
  return(flux)
}

# Troisième étape
# Simuler le solde jour par jour

simuler_solde <- function(flux, solde_initial, date_debut, date_fin) {
  
  dates <- seq.Date(date_debut, date_fin, by = "day")
  base <- data.frame(date = dates)
  
  flux_jour <- flux %>%
    group_by(date) %>%
    summarise(montant_jour = sum(montant), .groups = "drop")
  
  df <- base %>%
    left_join(flux_jour, by = "date") %>%
    mutate(
      montant_jour = ifelse(is.na(montant_jour), 0, montant_jour),
      solde = solde_initial + cumsum(montant_jour)
    )
  
  return(df)
}


# Quatrième étape

#Détecter un risque de découvert


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


# Cinquième étape
# On automatise les revenus récurrents

generer_revenus_recurrents <- function(liste_revenus, date_debut, date_fin) {
  
  # Séquence de mois
  mois_seq <- seq(from = as.Date(format(date_debut, "%Y-%m-01")),
                  to   = as.Date(format(date_fin, "%Y-%m-01")),
                  by   = "month")
  
  revenus <- do.call(rbind, lapply(mois_seq, function(mois) {
    lapply(1:nrow(liste_revenus), function(i) {
      date_revenu <- as.Date(sprintf("%s-%02d",
                                     format(mois, "%Y-%m"),
                                     liste_revenus$jour[i]))
      
      data.frame(
        date = date_revenu,
        montant = liste_revenus$montant[i],
        categorie = liste_revenus$categorie[i]
      )
    }) |> do.call(rbind, .)
  }))
  
  revenus <- revenus |> 
    dplyr::filter(date >= date_debut, date <= date_fin)
  
  return(revenus)
}


# Sixième étape 
# Ici on veut générer automatiquement les charges fixes récurrentes

# liste_charges : data.frame avec colonnes :
#   - montant
#   - jour
#   - categorie

generer_charges_fixes_recurrentes <- function(liste_charges, date_debut, date_fin) {
  
  mois_seq <- seq(from = as.Date(format(date_debut, "%Y-%m-01")),
                  to   = as.Date(format(date_fin, "%Y-%m-01")),
                  by   = "month")
  
  charges <- do.call(rbind, lapply(mois_seq, function(mois) {
    lapply(1:nrow(liste_charges), function(i) {
      date_charge <- as.Date(sprintf("%s-%02d",
                                     format(mois, "%Y-%m"),
                                     liste_charges$jour[i]))
      
      data.frame(
        date = date_charge,
        montant = -abs(liste_charges$montant[i]),  # toujours négatif
        categorie = liste_charges$categorie[i]
      )
    }) |> do.call(rbind, .)
  }))
  
  charges <- charges |> 
    dplyr::filter(date >= date_debut, date <= date_fin)
  
  return(charges)




  # Cette

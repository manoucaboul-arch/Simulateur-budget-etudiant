# Tests unitaires - Simulateur Budget Étudiant
# Auteur: manoucaboul-arch | Date: 2026-01-10
# 8 tests couvrant toutes les fonctions principales

library(dplyr)
library(lubridate)
source("Budget.R")

cat("\n=== TESTS UNITAIRES ===\n\n")

# Test 1: generer_donnees_temporelles() - Revenus
cat("[1/8] Test revenus...")
test1 <- generer_donnees_temporelles(1800, 1, "Salaire", as.Date("2026-01-01"), as.Date("2026-03-31"), "revenu")
stopifnot(nrow(test1) == 3, all(test1$montant > 0))
cat(" ✓\n")

# Test 2: generer_donnees_temporelles() - Dépenses  
cat("[2/8] Test dépenses...")
test2 <- generer_donnees_temporelles(700, 5, "Loyer", as.Date("2026-01-01"), as.Date("2026-02-28"), "depense")
stopifnot(nrow(test2) == 2, all(test2$montant < 0))
cat(" ✓\n")

# Test 3: simuler_evolution_budget()
cat("[3/8] Test simulation budget...")
flux <- tibble(date = as.Date(c("2026-01-01", "2026-01-05")), montant = c(1800, -700), label = c("Salaire", "Loyer"))
test3 <- simuler_evolution_budget(1000, as.Date("2026-01-01"), as.Date("2026-01-10"), flux, tibble())
stopifnot(nrow(test3) == 10, test3$solde[1] == 2800, test3$solde[5] == 2100)
cat(" ✓\n")

# Test 4: analyser_risques_financiers() - OK
cat("[4/8] Test risques OK...")
df_ok <- tibble(date = seq.Date(as.Date("2026-01-01"), as.Date("2026-01-05"), by = "day"), solde = c(1000, 1100, 1200, 1050, 1150))
test4 <- analyser_risques_financiers(df_ok)
stopifnot(test4$alerte == "OK", test4$couleur == "green", test4$mini == 1000)
cat(" ✓\n")

# Test 5: analyser_risques_financiers() - DANGER
cat("[5/8] Test risques DANGER...")
df_danger <- tibble(date = seq.Date(as.Date("2026-01-01"), as.Date("2026-01-05"), by = "day"), solde = c(100, 50, -20, -10, 0))
test5 <- analyser_risques_financiers(df_danger)
stopifnot(test5$alerte == "DANGER", test5$couleur == "red", test5$mini == -20)
cat(" ✓\n")

# Test 6: analyser_depenses()
cat("[6/8] Test statistiques dépenses...")
flux_dep <- tibble(date = as.Date(c("2026-01-01", "2026-01-02", "2026-01-03")), montant = c(-100, -200, -300), label = c("Courses", "Restaurant", "Transport"))
test6 <- analyser_depenses(flux_dep)
stopifnot(test6$moyenne == 200, test6$mediane == 200, test6$total == 600, test6$nb == 3)
cat(" ✓\n")

# Test 7: predire_solde()
cat("[7/8] Test prédiction...")
df_evol <- tibble(date = seq.Date(as.Date("2026-01-01"), as.Date("2026-01-10"), by = "day"), solde = c(1000, 1010, 1020, 1030, 1040, 1050, 1060, 1070, 1080, 1090))
test7 <- predire_solde(df_evol, 5)
stopifnot(nrow(test7) == 5, all(test7$type == "prédiction"), test7$solde_predit[1] > 1090)
cat(" ✓\n")

# Test 8: Gestion mois courts
cat("[8/8] Test mois février...")
test8 <- generer_donnees_temporelles(1000, 31, "Test", as.Date("2026-02-01"), as.Date("2026-02-28"), "revenu")
stopifnot(day(test8$date[1]) == 28)
cat(" ✓\n")

cat("\n=== RÉSULTAT: 8/8 TESTS PASSÉS ===\n")

# Simulateur-budget-etudiant
Notre projet est un outil interactif qui permet aux étudiant d'estimer automatiquement leur budget mensuel à partir de donnée financière. Le programme simule l'évolution du solde jour par jour, identifie les risques de découvert et visualise les résultats dans un dashboard

1. Anticiper son solde bancaire futur en fonction de ses revvenus et charges
2. Visualiser graphiquement les périodes de vulnérabilité
3. Alerte une alerte automatique en cas de risque de découvert (montant et date)

### On télécharge les bibliothèques

dplyr : manipulation des données (filtrer, trier, calculer)

tidyr : mise en forme des données (réorganiser, nettoyer)

lubridate : gestion des dates (jours, mois, séquences)

ggplot2 : graphiques (courbe du solde, dépenses)

shiny : créer l’application interactive

shinydashboard : mise en page du dashboard

## II - Description du code

1. Les fonctions motrices de l'application.

''' generer_flux_temporel <- function(liste, date_debut, date_fin, type_flux) {
  mois_seq <- seq(from = as.Date(format(date_debut, "%Y-%m-01")),
                  to   = as.Date(format(date_fin, "%Y-%m-01")),
                  by   = "month")
  multiplicateur <- if(type_flux == "debit") -1 else 1
}'''


La fonction .generer_flux_temporel() constitue le cœur du système.
Elle permet de générer automatiquement des flux mensuels (revenus ou charges) entre deux dates, en évitant toute duplication de code.

Elle :

crée une séquence de mois entre la date de début et la date de fin,

applique un signe positif ou négatif selon qu’il s’agit d’un crédit ou d’un débit,

génère les dates exactes en fonction du jour du mois fourni,

assemble l’ensemble des lignes dans un tableau propre,

filtre les flux pour ne conserver que ceux compris dans l’intervalle demandé.

Cette fonction n’est pas destinée à être appelée directement par l’utilisateur, mais sert de moteur aux fonctions de plus haut niveau.


* charger_parametres : Centralise et structure toutes les données. Elle prend les diverses informations de l'utilisateur -> Son solde initial, ses revenus, ses charges fixes et dépense variables.
  -> Elle structure les données
   -> Sépare ce qui va être considérer comme débit et comme crédit


* genere_flux_journalisers : Fonctionne comme un journal de bord et prend les revenus et dépense tout en faisant une chronologie.
 Décidé si un montant est un débit ou un crédit 


* simuler_solde : Fait le travail mathématique et la somme cumulée en prenant la liste crée précédemment et crée un calendrier complet du mois.


* Detecter_risque reregarde le résultat de la simuler_solde est cherche l'erreur.
Elle déclenche l'alerte si un chiffre est en dessous de zéro et préviens le risque de découvert


*Generer_revenus_ Recurrents & Generer_chargers_fixes_recurrentes automatisent la saisie des données pour éviter d'avoir à taper chaque ligne à chaque fois 



#### Architecture 

Architecture : Le Moteur Temporel
Le cœur de notre système est une fonction "moteur" interne. Elle permet d'éviter la répétition de code en automatisant la création de dates mensuelles pour n'importe quel type de flux.

Extrait de code

.generer_flux_temporel <- function(liste, date_debut, date_fin, type_flux) {
  #### Création de la séquence de mois
  
  ''' 
  mois_seq <- seq(from = as.Date(format(date_debut, "%Y-%m-01")),
                  to   = as.Date(format(date_fin, "%Y-%m-01")),
                  by   = "month")'''
  
  #### Application du signe : + pour crédit, - pour débit
  multiplicateur <- if(type_flux == "debit") -1 else 1
  #### suite du calcul
}
'''

Fonctions Utilisateur (Interface)
L'utilisateur interagit avec des fonctions simplifiées qui masquent la complexité du moteur interne.

Génération de revenus et charges : Ces fonctions automatisent la répétition des flux sur toute la période demandée.




# Pour les revenus
rev <- generer_revenus_recurrents(liste_revenus, date_debut, date_fin)

# Pour les charges
cha <- generer_charges_fixes_recurrentes(liste_charges, date_debut, date_fin)
Chargement des paramètres : Cette fonction centralise le solde initial et tous les tableaux de flux dans une structure unique.

Extrait de code

params <- charger_parametres(solde_initial = 200, revenus, charges, depenses_var)
Génération des Flux et Simulation
C'est ici que le travail mathématique s'opère. Le programme fusionne toutes les données pour créer un calendrier financier complet.

Le Journal de bord journalier : Le programme fusionne les revenus, charges et dépenses variables tout en s'assurant que les dépenses portent bien un signe négatif.

Extrait de code

flux <- generer_flux_journaliers(params, date_debut, date_fin)
Le calcul du solde cumulé : La fonction crée un calendrier jour par jour et calcule le solde grâce à une somme cumulée (cumsum).

Extrait de code

df_solde <- simuler_solde(flux, params$solde_initial, date_debut, date_fin)
Analyse et Détection de Risque
La dernière étape est cruciale : elle analyse le résultat de la simulation pour chercher d'éventuels problèmes de trésorerie.

Détection du risque : Le programme vérifie si le solde descend sous la barre de zéro.

Localisation de l'erreur : Si un risque est détecté, il renvoie la date précise du premier découvert et le montant minimum atteint.

Extrait de code

''' detecter_risque <- function(df_solde) {
  solde_min <- min(df_solde$solde)
  risque <- ifelse(solde_min < 0, "Découvert", "OK")
}
'''


## Démonstration et Visualisation


Nous allons désormais vous montrer le résultat de la simulation. Le programme génère un graphique de l'évolution du solde avec une ligne rouge d'alerte (abline) située au niveau 0 pour identifier immédiatement les zones critiques.


#### Affichage du diagnostic final
'''print(detecter_risque(df_solde))'''

### Tracé du graphique

'''plot(df_solde$date, df_solde$solde, type="l", col="blue")
abline(h=0, col="red", lty=2)'''







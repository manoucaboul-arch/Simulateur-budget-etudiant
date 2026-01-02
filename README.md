# Simulateur-budget-etudiant
Notre projet est un outil interactif qui permet aux étudiant d'estimer automatiquement leur budget mensuel à partir de donnée financière. Le programme simule l'évolution du solde jour par jour, identifie les risques de découvert et visualise les résultats dans un dashboard



### On télécharge les bibliothèques

dplyr : manipulation des données (filtrer, trier, calculer)

tidyr : mise en forme des données (réorganiser, nettoyer)

lubridate : gestion des dates (jours, mois, séquences)

ggplot2 : graphiques (courbe du solde, dépenses)

shiny : créer l’application interactive

shinydashboard : mise en page du dashboard

## II - Description du code

1. Les fonctions motrices de l'application.

   * charger_parametres : Centralise et tructure toutes les données. Elle prend les diverses informations de l'utilisateur -> Son solde initial, ses revenus, ses charges fixes et dépense variables.
  -> Elle structure les données
   -> Sépare ce qui va être considérer comme débit et comme crédit
     
 La fonction  * genere_flux_journalisers * fonctionne comme un journal de bord et prend les revenus et dépense tout en faisant une chronologie.
 Décidé si un montant est un débit ou un crédit 

  
   * simuler_solde est la fonction qui fait le travail mathématique. Elle fait la somme cumulée en prenant la liste crée précédemment et crée un calendrier complet du mois.

   * Detecter_risque reregarde le résultat de la simuler_solde est cherche l'erreur.
Elle déclenche l'alerte si un chiffre est en dessous de zéro et préviens le risque de découvert







## Quel fonctionnement ?

En tant qu'utilisateur, 



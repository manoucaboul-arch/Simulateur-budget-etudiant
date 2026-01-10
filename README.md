# Simulateur-budget-etudiant

Notre projet est un outil interactif qui permet aux étudiant d'estimer automatiquement leur budget mensuel à partir de donnée financière. Le programme simule l'évolution du solde jour par jour, identifie les risques de découvert et visualise les résultats dans un dashboard.

1. Anticiper son solde bancaire futur en fonction de ses revvenus et charges
2. Visualiser graphiquement les périodes de vulnérabilité  
3. Alerte une alerte automatique en cas de risque de découvert (montant et date)

## Le site est directement disponible

https://manoucaboul-arch.shinyapps.io/monbudget/

## Installation

### Bibliothèques requises

```r
library(shiny)
library(shinydashboard)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
```

Pour installer ces packages :

```r
install.packages(c("shiny", "shinydashboard", "dplyr", "tidyr", "lubridate", "ggplot2"))
```

## Description du code

L'application est construite avec Shiny. Le fichier `Budget.R` contient toute l'application.

### Les 3 fonctions principales

#### 1. generer_donnees_temporelles()

Génère automatiquement des flux mensuels (revenus ou charges) entre deux dates.

```r
generer_donnees_temporelles(montant, jour, nom, debut, fin, type)
```

Paramètres :
- montant : montant du flux
- jour : jour du mois (1-31)
- nom : nom du flux ("Salaire", "Loyer", etc.)
- debut : date de début
- fin : date de fin
- type : "revenu" ou "depense"

La fonction crée une séquence de mois et applique un signe positif pour les revenus ou négatif pour les dépenses. Elle gère automatiquement les mois avec moins de 31 jours.

#### 2. simuler_evolution_budget()

Calcule l'évolution quotidienne du solde bancaire.

```r
simuler_evolution_budget(solde_init, debut, fin, flux_auto, flux_imprevus)
```

Paramètres :
- solde_init : solde initial
- debut : date de début
- fin : date de fin
- flux_auto : flux fixes (salaire, loyer)
- flux_imprevus : dépenses ponctuelles

La fonction crée un calendrier jour par jour, fusionne tous les flux et calcule le solde cumulé avec `cumsum()`.

#### 3. analyser_risques_financiers()

Détecte les risques de découvert.

```r
analyser_risques_financiers(df_evolution)
```

La fonction identifie le point le plus bas du solde et déclenche une alerte "DANGER" si le solde devient négatif. Elle retourne :
- mini : solde minimum atteint
- alerte : "DANGER" ou "OK"
- couleur : "red" ou "green"

### Interface Shiny

#### Sidebar
- Paramètres généraux : solde initial et période d'analyse
- Flux fixes : configuration du salaire et loyer
- Gestion des imprévus : ajout de dépenses/revenus ponctuels
- Bouton Reset

#### Dashboard
- 3 Value Boxes : solde final, point le plus bas, alerte de risque
- Graphique d'évolution : courbe de trésorerie
- Graphique camembert : répartition des dépenses
- Tableau : liste des flux

## Utilisation

### Lancer l'application

```r
# Ouvrir le fichier Budget.R dans RStudio et exécuter
shinyApp(ui, server)
```

### Configuration

1. Définir le solde initial
2. Choisir la période d'analyse  
3. Configurer les flux fixes (salaire et loyer)
4. Ajouter des imprévus si besoin

### Interprétation

- Zone verte : pas de risque
- Zone rouge : découvert détecté
- Point le plus bas : moment critique
- Solde final : projection de fin de période

## Structure du projet

```
Simulateur-budget-etudiant/
├── Budget.R      # Application complète
└── README.md     # Documentation
```

## Fonctionnalités

- Simulation jour par jour du solde bancaire
- Gestion automatique des flux récurrents
- Détection automatique des risques de découvert
- Visualisation graphique interactive
- Interface Shiny intuitive
- Adaptation aux mois de 28, 29, 30 ou 31 jours

## Exemple d'utilisation

Scénario étudiant :
- Solde initial : 1200 €
- Salaire : 1800 € le 1er du mois
- Loyer : 700 € le 5 du mois
- Dépense imprévue : 150 €

Le dashboard affiche l'évolution quotidienne et alerte en cas de risque.

## Améliorations possibles

- Export des données en CSV
- Catégories de dépenses personnalisables
- Statistiques mensuelles
- Synchronisation bancaire
- Notifications par email

## Problèmes courants

**L'application ne se lance pas**
Vérifier que tous les packages sont installés.

**Erreur de date**
Utiliser le format YYYY-MM-DD.

**Le graphique ne s'affiche pas**
Vérifier que vous avez entré des données.

## Contribution

Les contributions sont bienvenues.

1. Fork le projet
2. Créer une branche
3. Commit les changements
4. Push
5. Ouvrir une Pull Request

## Licence

Projet sous licence MIT.

## Auteur

Développé par manoucaboul-arch

Merci aux étudiants qui ont testé l'application.

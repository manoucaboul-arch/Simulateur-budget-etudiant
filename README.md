# Simulateur-budget-etudiant
Notre projet est un outil interactif qui permet aux étudiant d'estimer automatiquement leur budget mensuel à partir de donnée financière. Le programme simule l'évolution du solde jour par jour, identifie les risques de découvert et visualise les résultats dans un dashboard

1. Anticiper son solde bancaire futur en fonction de ses revvenus et charges
2. Visualiser graphiquement les périodes de vulnérabilité
3. Alerte une alerte automatique en cas de risque de découvert (montant et date)

# Le site est directement disponible par cette adresse 

https://manoucaboul-arch.shinyapps.io/monbudget/


### On télécharge les bibliothèques

dplyr : manipulation des données (filtrer, trier, calculer)

tidyr : mise en forme des données (réorganiser, nettoyer)

lubridate : gestion des dates (jours, mois, séquences)

ggplot2 : graphiques (courbe du solde, dépenses)

shiny : créer l’application interactive

shinydashboard : mise en page du dashboard

## II - Description du code

1. Les fonctions motrices de l'application.

''' {r
generer_flux_temporel <- function(liste, date_debut, date_fin, type_flux) {
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




#### Pour les revenus
rev <- generer_revenus_recurrents(liste_revenus, date_debut, date_fin)

#### Pour les charges
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








---

## III - Installation

### Prérequis
- R version 4.0 ou supérieure
- RStudio (recommandé)

### Installation des packages
```r
# Installation des packages nécessaires
install.packages(c(
  "dplyr",
  "tidyr",
  "lubridate",
  "ggplot2",
  "shiny",
  "shinydashboard"
))
```

### Lancement de l'application en local
```r
# Cloner le dépôt
git clone https://github.com/manoucaboul-arch/Simulateur-budget-etudiant.git

# Ouvrir le projet dans RStudio et exécuter
shiny::runApp()
```

---

## IV - Guide d'utilisation

### 1. Saisie des données
- **Solde initial** : Entrez votre solde bancaire de départ
- **Revenus récurrents** : Bourse, salaire, aide parentale (montant et jour du mois)
- **Charges fixes** : Loyer, abonnements, transport (montant et jour du mois)
- **Dépenses variables** : Dépenses ponctuelles avec leurs dates

### 2. Période de simulation
Sélectionnez la date de début et de fin pour votre prévision budgétaire (ex: du 1er janvier au 31 mars)

### 3. Lecture des résultats
- **Graphique** : Visualisez l'évolution de votre solde jour par jour
- **Ligne rouge** : Indique le seuil de découvert (0€)
- **Alerte** : Si votre solde passe en négatif, le système vous indique la date et le montant du découvert

### Exemple d'utilisation
```r
# Exemple de données pour un étudiant type
solde_initial <- 200

liste_revenus <- data.frame(
  description = c("Bourse", "Job étudiant"),
  montant = c(550, 400),
  jour_mois = c(5, 25)
)

liste_charges <- data.frame(
  description = c("Loyer", "Transport", "Forfait mobile"),
  montant = c(450, 75, 20),
  jour_mois = c(1, 1, 10)
)

# Lancer la simulation
params <- charger_parametres(solde_initial, liste_revenus, liste_charges)
flux <- generer_flux_journaliers(params, "2026-01-01", "2026-03-31")
df_solde <- simuler_solde(flux, params$solde_initial, "2026-01-01", "2026-03-31")
```

---

## V - Structure du projet

```
Simulateur-budget-etudiant/
├── app.R                 # Application Shiny principale
├── README.md            # Documentation
├── functions/           
│   ├── generer_flux.R   # Fonctions de génération des flux
│   ├── simuler_solde.R  # Fonction de simulation
│   └── detecter_risque.R # Fonction de détection des risques
└── www/                 # Ressources web (images, CSS)
```

---

## VI - Fonctionnalités

✅ Simulation jour par jour du solde bancaire  
✅ Gestion automatique des flux récurrents mensuels  
✅ Détection automatique des risques de découvert  
✅ Visualisation graphique interactive  
✅ Interface utilisateur intuitive avec Shiny  
✅ Calcul précis avec prise en compte de tous les flux financiers  

---

## VII - Améliorations futures

- 📊 Export des données en CSV/Excel
- 📧 Notifications par email en cas de découvert prévu
- 💰 Calcul automatique des frais bancaires
- 📱 Version mobile responsive améliorée
- 🎯 Conseils d'épargne personnalisés
- 📈 Statistiques mensuelles et annuelles
- 🔄 Synchronisation avec comptes bancaires (API)
- 🌍 Support multi-devises

---

## VIII - Résolution de problèmes (FAQ)

**Q: L'application ne se lance pas**  
R: Vérifiez que tous les packages sont installés avec `installed.packages()`. Installez les packages manquants.

**Q: Erreur de date lors de la simulation**  
R: Assurez-vous que les dates sont au format correct (YYYY-MM-DD) ou utilisez `as.Date()`.

**Q: Le graphique ne s'affiche pas**  
R: Vérifiez que vous avez bien entré des données de revenus ou charges et que la période est valide.

**Q: Comment modifier mes données après simulation ?**  
R: Retournez dans les onglets de saisie et modifiez vos informations, puis relancez la simulation.

**Q: Puis-je sauvegarder mes simulations ?**  
R: Actuellement, l'application fonctionne en mode session. Les données sont réinitialisées à chaque nouvelle session.

---

## IX - Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. **Fork** le projet
2. Créez une **branche** pour votre fonctionnalité (`git checkout -b feature/nouvelle-fonctionnalite`)
3. **Committez** vos changements (`git commit -m 'Ajout: nouvelle fonctionnalité'`)
4. **Push** vers la branche (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrez une **Pull Request**

### Directives de contribution
- Respectez le style de code existant
- Ajoutez des commentaires clairs
- Testez votre code avant de soumettre
- Documentez les nouvelles fonctionnalités

---

## X - Licence

Ce projet est sous **licence MIT**. Vous êtes libre de l'utiliser, le modifier et le distribuer.

```
MIT License

Copyright (c) 2026 manoucaboul-arch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## XI - Auteurs et Remerciements

### Auteur principal
- **manoucaboul-arch** - *Développeur principal* - [GitHub](https://github.com/manoucaboul-arch)

### Remerciements
Merci à tous les étudiants qui ont testé l'application et fourni des retours précieux pour l'améliorer. Un remerciement spécial à la communauté R et Shiny pour leurs excellents outils et documentation.

---

## XII - Contact et Support

- **Issues GitHub** : Pour signaler des bugs ou proposer des améliorations, utilisez [GitHub Issues](https://github.com/manoucaboul-arch/Simulateur-budget-etudiant/issues)
- **Discussions** : Pour poser des questions ou échanger, visitez [GitHub Discussions](https://github.com/manoucaboul-arch/Simulateur-budget-etudiant/discussions)

---

## XIII - Changelog

### Version actuelle
- ✅ Simulation de budget mensuel
- ✅ Détection de découvert
- ✅ Visualisation graphique
- ✅ Interface Shiny Dashboard

### Versions à venir
- 🔜 Export des résultats
- 🔜 Gestion multi-utilisateurs
- 🔜 API REST

---

**💡 Développé avec ❤️ pour aider les étudiants à mieux gérer leur budget**

**📚 Projet pédagogique - Gestion budgétaire pour étudiants**

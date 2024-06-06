# Adware Installer

## Description
Ce script PowerShell est conçu pour automatiser l'installation et la configuration de divers logiciels et paramètres sur un système Windows. Il détecte la version et l'architecture du système d'exploitation, désactive l'UAC et les applications en arrière-plan, installe des applications via Winget, active Windows et Office (et eventuellement plus!).

## Avertissements
- **Exécution en tant qu'administrateur** : Assurez-vous d'exécuter le script en tant qu'administrateur pour éviter les problèmes de permissions.
- **Modifications du registre** : Le script modifie le registre pour désactiver l'UAC et les applications en arrière-plan.
- **Utilisation de scripts tiers** : Le script télécharge et exécute des scripts tiers pour l'activation de Windows et Office.
- **Pour qu'Office s'installe depuis le script, vous devez mettre le dossier /Office provenant d'un ISO d'installation d'Office au même endroit que le script. (Téléchargement d'Office prévu pour une future mise a jour)**
- **Pour une raison que j'ignore le script ne se lanceras pas si le chemin d'accès menant au script contient des espaces.**

## Fonctionnalités
- **Installation completement automatique ne demandant aucune attention** : Le script est conçu pour être utilisé en ligne de commande sans aucune intervention de l'utilisateur.
- **Détection de la version et de l'architecture de Windows** : Le script détecte automatiquement la version et l'architecture de Windows pour exécuter les scripts appropriés.
- **Activation de Windows et Office** : Le script active Windows et Office grace au scripts MAS.

- **Installation de Winget** : Le script installe Winget si ce n'est pas déjà fait.
- **Installation d'applications via Winget** : Le script installe une liste d'applications prédéfinies via Winget ainsi que la suite Office.
- **Menu interactif** : Un menu interactif permet à l'utilisateur de choisir les actions à exécuter.
- **Désactivation de l'UAC et des applications en arrière-plan** : Le script désactive l'UAC et les applications en arrière-plan pour améliorer les performances.

## Utilisation
(Nouvelle Méthode!!)
1. **Ouvrez Powershell et lancez la commande: `irm adw.info.gf | iex`**

Manuellement.
1. **Téléchargez le script** : Téléchargez le script `adwareinstaller.ps1` et `launcher.bat` et assurez vous qu'ils soient dans le même dossier.
2. **Exécutez le launcher en tant qu'administrateur**
3. **Acceder au menu interactif (Optionnel)** : Pendant le compte à rebours de 5 secondes après la détéction de l'OS, appuyez sur n'importe quelle touche pour accéder au menu interactif.

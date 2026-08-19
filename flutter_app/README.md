# Mon Comptable — CAM-TAXE (Flutter)

Application mobile **Android et iOS** de déclarations et de conseils fiscaux au
Cameroun, construite d'après les maquettes fournies.

> « Faites vos déclarations chez nous — 100 % sûr et rapide »

## Démarrer

```bash
flutter pub get
flutter run                      # sur un appareil ou un émulateur connecté

flutter build apk --release      # Android
flutter build ipa --release      # iOS (nécessite macOS et Xcode)
```

Vérifications :

```bash
flutter analyze                  # aucun problème attendu
flutter test                     # 5 tests
```

## Les 7 services

| Service | Écran | Ce qui est demandé |
| --- | --- | --- |
| Besoin de conseil fiscale | `pages/conseil_fiscal.dart` | 7 questions dépliables → sous-questions → « Autre préoccupation » (saisie libre) |
| Déclarer et payer vos impôts | `pages/declarer.dart` | NIU, type d'impôts, montant, nature de l'activité, facture d'achats, liste des déclarations |
| DARP/IRPP | `pages/darp.dart` | NIU, bulletin annuel, liste de tous les biens meubles ou non |
| DSF | `pages/dsf.dart` | NIU, DSF pour impôt **ou** pour la banque, type d'entreprise et nature des activités, puis états financiers / états fiscaux / documents administratifs / support de transmission |
| Contentieux fiscal | `pages/contentieux.dart` | Nature du préjudice subi (texte libre) + pièces justificatives |
| Acquérir son NIU / ACF | `pages/niu_acf.dart` | NIU, ACF ou les deux sur une même page ; NIU personne physique / personne morale ; l'ACF est regroupé avec l'attestation d'immatriculation |
| Faire un audit | `pages/audit.dart` | Nom de la structure, type d'audit, NIU, paiement de caution, puis les 5 sections de documents |

Chaque écran de service se termine par **« Discuter avec un agent »**, qui ouvre
la messagerie en pré-remplissant le sujet.

## Comptes

Un compte est obligatoire pour accéder aux services (`RequiertCompte` dans
`main.dart`). L'inscription distingue deux profils :

- **Utilisateur** — nom, prénom, email, téléphone, NIU, mot de passe, photo de
  la CNI et justificatif de NIU.
- **Personne employée** — CNI, téléphone, plan de localisation, numéro de
  contribuable, adresse email et CNI d'un garant qui se porte caution.

## Structure

```
lib/
  data/          contenus éditoriaux (services, conseil fiscal, audit, DSF)
  models.dart    compte, demande, pièce, message
  state/         état de l'application (ChangeNotifier + InheritedNotifier)
  widgets/       briques d'interface partagées et illustrations
  pages/         un fichier par écran
  theme.dart     charte graphique
```

## État des données

Le compte, les demandes et la messagerie sont conservés sur l'appareil via
`shared_preferences`. Les téléversements (`file_picker`) enregistrent le nom du
fichier choisi ; l'envoi réel des documents, l'API, le paiement de caution et le
chat temps réel restent à brancher.

## Charte

| | |
| --- | --- |
| Orange principal | `#F5893F` |
| Orange clair | `#FBA05C` |
| Bleu messagerie | `#5DA9F5` / `#1E88F0` |
| Fond | `#EDEDED` |

## Cible web (optionnelle)

Le projet compile aussi pour le web, ce qui sert à prévisualiser rapidement les
écrans sans appareil :

```bash
flutter build web --web-renderer html --release
```

Le moteur `html` évite d'avoir à télécharger CanvasKit depuis un CDN.

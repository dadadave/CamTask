# Mon Comptable — CAM-TAXE

Application de déclarations et de conseils fiscaux au Cameroun, construite
d'après les maquettes fournies.

> « Faites vos déclarations chez nous — 100 % sûr et rapide »

## Deux implémentations

Le même produit existe ici sous deux formes, avec les mêmes 7 services et le
même contenu éditorial :

| | Emplacement | Ce que c'est |
| --- | --- | --- |
| **Flutter** | [`flutter_app/`](flutter_app/) | Vraie application **Android et iOS**, installable. Voir son [README](flutter_app/README.md). |
| **React** | racine du dépôt | Application **web** mobile-first, ouvrable dans un navigateur. |

Le reste de ce document décrit la version React.

## Démarrer (React)

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # build de production dans dist/
```

L'interface est calée sur les dimensions des maquettes (430 × 932). Sur grand
écran elle s'affiche dans un cadre téléphone centré ; sur mobile elle occupe
tout l'écran.

## Les 7 services

| Service | Écran | Ce qui est demandé |
| --- | --- | --- |
| Besoin de conseil fiscale | `/service/conseil-fiscal` | 7 questions → sous-questions → « Autre préoccupation » (saisie libre) |
| Déclarer et payer vos impôts | `/service/declarer` | NIU, type d'impôts, montant, nature de l'activité, facture d'achats, liste des déclarations |
| DARP/IRPP | `/service/darp` | NIU, bulletin annuel, liste de tous les biens meubles ou non |
| DSF | `/service/dsf` | NIU, DSF pour impôt **ou** pour la banque, type d'entreprise et nature des activités, puis états financiers / états fiscaux / documents administratifs / support de transmission |
| Contentieux fiscal | `/service/contentieux` | Nature du préjudice subi (texte libre) + pièces justificatives |
| Acquérir son NIU / ACF | `/service/niu-acf` | NIU, ACF, ou les deux sur une même page ; NIU personne physique / personne morale ; l'ACF est regroupé avec l'attestation d'immatriculation |
| Faire un audit | `/service/audit` | Nom de la structure, type d'audit, NIU, paiement de caution, puis les 5 sections de documents |

Chaque écran de service se termine par le bouton **« Discuter avec un agent »**
qui ouvre la messagerie.

## Comptes

Un compte est obligatoire pour accéder aux services (`RequiertCompte`).
L'inscription distingue deux profils :

- **Utilisateur** — nom, prénom, email, téléphone, NIU, mot de passe, photo de
  la CNI et justificatif de NIU.
- **Personne employée** — CNI, téléphone, plan de localisation, numéro de
  contribuable, adresse email et CNI d'un garant qui se porte caution.

## Structure

```
src/
  data/          contenus éditoriaux (services, conseil fiscal, audit, DSF)
  store/         état de l'application (compte, demandes, messages)
  components/    briques d'interface partagées (champs, upload, nav, icônes)
  pages/         un fichier par écran
  styles/        charte graphique
```

## État des données

Les demandes, le compte et la messagerie sont conservés dans le
`localStorage` du navigateur — aucun serveur n'est requis pour faire tourner
l'application. Les téléversements enregistrent le nom du fichier choisi ;
l'envoi réel des documents et le chat temps réel seront branchés sur l'API
lorsqu'elle sera disponible.

## Charte

| | |
| --- | --- |
| Orange principal | `#F5893F` |
| Orange clair | `#FBA05C` |
| Bleu messagerie | `#5DA9F5` / `#1E88F0` |
| Fond | `#EDEDED` |

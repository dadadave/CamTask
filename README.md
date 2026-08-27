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
cp .env.example .env   # puis renseigner les clés Supabase (voir plus bas)
npm run dev            # http://localhost:5173
npm run build          # build de production dans dist/
```

Sans les deux variables du `.env`, l'application affiche un écran
« Application non configurée » qui rappelle quoi renseigner : elle n'a plus de
mode hors-ligne.

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

Le mot de passe est désormais demandé aux deux profils : l'authentification
Supabase en exige un pour chaque compte. Cocher « Personne employée » ne
donne aucun droit particulier — voir *Habilitation des agents* plus bas.

## Structure

```
src/
  api/           accès aux données : l'interface `Backend` et son implémentation
  data/          contenus éditoriaux (services, conseil fiscal, audit, DSF)
  store/         état de l'application (compte, demandes, messages)
  components/    briques d'interface partagées (champs, upload, nav, icônes)
  pages/         un fichier par écran
  styles/        charte graphique
```

## Le back-end

Les comptes, les demandes, les pièces jointes et la messagerie vivent
désormais dans **Supabase** (Postgres + Auth + Storage + Realtime).

### Mettre en place le projet

1. Créer un projet sur [supabase.com](https://supabase.com).
2. Ouvrir *SQL Editor* et exécuter [`supabase/schema.sql`](supabase/schema.sql)
   en entier. Le script est idempotent : on peut le relancer.
3. *Authentication → Providers → Email* : **désactiver « Confirm email »**.
   L'inscription dépose les pièces justificatives dans la foulée, ce qui exige
   une session immédiate. Avec la confirmation activée, l'utilisateur doit
   valider son email puis se reconnecter avant de pouvoir les transmettre.
4. *Settings → API* : copier l'URL du projet et la clé `anon` dans le `.env`.

La clé `anon` est publique par construction : ce sont les policies RLS du
script SQL qui protègent les données, pas le secret de la clé.

### Déploiement

Les deux variables doivent aussi être déclarées chez l'hébergeur (sur Vercel :
*Settings → Environment Variables*), et le projet redéployé. Elles sont lues à
la compilation : un build qui n'en dispose pas réussit quand même, mais le site
livré n'affichera que l'écran « Application non configurée ».

### Ce que contient la base

| Table | Rôle |
| --- | --- |
| `profiles` | nom, prénom, téléphone, NIU, profil déclaré ; créée automatiquement à l'inscription |
| `demandes` | une ligne par demande de service, avec son `statut` |
| `pieces` | les documents ; `demande_id` nul = pièce fournie à l'inscription |
| `messages` | la conversation client ↔ agent, diffusée en temps réel |

Les fichiers eux-mêmes sont dans le bucket privé `pieces`, rangés sous
`<user_id>/…`. Aucune URL publique n'est générée.

### Habilitation des agents

`profiles.role` est déclaré par l'utilisateur à l'inscription (« Utilisateur »
ou « Personne employée ») et **ne donne aucun privilège** : n'importe qui peut
cocher la case. Le droit de consulter les dossiers de tout le monde vient de
`profiles.est_agent`, que l'application ne peut pas modifier (le `REVOKE` du
script SQL l'interdit). On l'active à la main depuis le tableau de bord
Supabase, pour les seuls conseillers de l'agence.

En attendant un vrai back-office, un agent répond aux clients en insérant une
ligne dans `messages` (`auteur = 'agent'`, `user_id` = le client) depuis
l'éditeur de tables : le message arrive instantanément dans l'application.

### Passer à notre propre API

L'application ne connaît pas Supabase. Elle ne parle qu'à l'interface
`Backend` définie dans [`src/api/types.ts`](src/api/types.ts) — sessions,
demandes, pièces, messages, temps réel. `src/api/supabase.ts` en est une
implémentation parmi d'autres.

Le jour où notre back-end prend le relais :

1. écrire `src/api/rest.ts` qui implémente `Backend` ;
2. changer la seule ligne d'export de `src/api/index.ts`.

Aucune page, aucun composant, aucun état à retoucher.

### Reste à faire

- **Mode hors-ligne** : l'ancien `localStorage` a disparu, l'application exige
  maintenant une connexion. Un cache local par-dessus le `Backend` le
  rétablirait — utile vu la qualité du réseau.
- **Application Flutter** : `flutter_app/` est branchée sur le même projet
  Supabase (`supabase_flutter`, voir son [README](flutter_app/README.md)) pour
  les comptes, les demandes et les pièces jointes. Seule sa messagerie reste
  locale, avec une réponse d'agent simulée ; le schéma ci-dessus la sert déjà
  telle quelle.
- **Paiements** : les montants de `Déclarer` et la caution d'`Audit` ne sont
  pas encaissés. Un encaissement mobile money demande un secret côté serveur,
  donc une Edge Function.

## Charte

| | |
| --- | --- |
| Orange principal | `#F5893F` |
| Orange clair | `#FBA05C` |
| Bleu messagerie | `#5DA9F5` / `#1E88F0` |
| Fond | `#EDEDED` |

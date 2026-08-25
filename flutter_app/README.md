# Mon Comptable — CAM-TAXE (Flutter)

Application mobile **Android et iOS** de déclarations et de conseils fiscaux au
Cameroun, construite d'après les maquettes fournies.

> « Faites vos déclarations chez nous — 100 % sûr et rapide »

## Démarrer

L'application s'authentifie auprès de **Supabase** : il lui faut les
coordonnées du projet, injectées au build depuis un fichier non versionné.

```bash
cp env.example.json env.json     # puis renseigner les deux valeurs
flutter pub get
flutter run --dart-define-from-file=env.json

flutter build apk --release --dart-define-from-file=env.json   # Android
flutter build ipa --release --dart-define-from-file=env.json   # iOS (macOS + Xcode)
```

Les deux valeurs se trouvent dans le tableau de bord Supabase,
*Settings → API* : l'URL du projet et la clé `anon`. Sans le
`--dart-define-from-file`, l'application démarre sur un écran
« Application non configurée » qui rappelle quoi faire, plutôt que
d'échouer à la première action.

La clé `anon` est publique par construction — ce sont les policies RLS de
[`../supabase/schema.sql`](../supabase/schema.sql) qui protègent les données,
pas le secret de la clé. Elle n'a pour autant rien à faire dans l'historique
Git : `env.json` est ignoré.

### Mettre en place le projet Supabase

1. Créer un projet sur [supabase.com](https://supabase.com).
2. *SQL Editor* : exécuter [`../supabase/schema.sql`](../supabase/schema.sql)
   en entier. Le script est idempotent, on peut le relancer.
3. *Authentication → Providers → Email* : **désactiver « Confirm email »**.
   Sinon `signUp` ne rend aucune session et l'utilisateur doit valider son
   email avant de pouvoir se connecter.
4. *Settings → API* : copier l'URL et la clé `anon` dans `env.json`.

Vérifications :

```bash
flutter analyze                  # aucun problème attendu
flutter test                     # 8 tests, sans réseau
```

Les tests n'appellent pas Supabase : `AppState` accepte un `BackendAuth`
factice et un indicateur `configure`, ce que `test/widget_test.dart` utilise.

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

Le mot de passe est demandé aux deux profils : l'authentification Supabase en
exige un pour chaque compte. Cocher « Personne employée » ne donne aucun
privilège — le droit de consulter les dossiers des clients vient de
`profiles.est_agent`, qui se règle depuis le tableau de bord.

## Structure

```
lib/
  api/
    backend.dart          l'interface BackendAuth + ErreurBackend
    supabase_auth.dart    son implémentation Supabase
    api.dart              le point de bascule (une seule ligne à changer)
  data/                   contenus éditoriaux (services, conseil fiscal, audit, DSF)
  models.dart             compte, demande, pièce, message
  state/                  état de l'application (ChangeNotifier + InheritedNotifier)
  supabase_config.dart    coordonnées du projet, lues au build
  widgets/                briques d'interface partagées et illustrations
  pages/                  un fichier par écran
  theme.dart              charte graphique
```

Les écrans ne connaissent pas Supabase : ils ne parlent qu'à `BackendAuth`.
Le jour où notre propre API prend le relais, il suffit d'en écrire une autre
implémentation et de changer la ligne d'export de `lib/api/api.dart`.

## État des données

| | Où |
| --- | --- |
| Compte, session, profil | **Supabase** (`auth` + table `profiles`) |
| Demandes | appareil, via `shared_preferences` |
| Messagerie | appareil, avec une réponse d'agent simulée |
| Pièces téléversées | nom du fichier seulement, sur l'appareil |

La session est rétablie au lancement et survit au redémarrage : c'est
`supabase_flutter` qui conserve le jeton.

Restent à brancher : l'envoi réel des documents vers le bucket privé
`pieces`, les demandes et la messagerie temps réel (le schéma les sert déjà
tels quels), et le paiement de caution — qui demande un secret côté serveur,
donc une Edge Function.

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

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
   puis [`../supabase/schema_agents.sql`](../supabase/schema_agents.sql), en
   entier. Les deux scripts sont idempotents, on peut les relancer.
3. *Authentication → Providers → Email* : **désactiver « Confirm email »**.
   Sinon `signUp` ne rend aucune session et l'utilisateur doit valider son
   email avant de pouvoir se connecter.
4. *Settings → API* : copier l'URL et la clé `anon` dans `env.json`.

Vérifications :

```bash
flutter analyze                  # aucun problème attendu
flutter test                     # 14 tests, sans réseau
```

Les tests n'appellent pas Supabase : `AppState` accepte un `Backend`
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
privilège — c'est un **type de client**, pas un compte d'équipe.

## Espace conseiller

Le droit de voir les dossiers de tout le monde vient de `profiles.est_agent`,
qui ne se règle que depuis le tableau de bord :

```sql
update public.profiles set est_agent = true
 where id = (select id from auth.users where email = 'vous@cam-taxe.cm');
```

À la connexion, chacun va chez soi : un client sur `/accueil`, un conseiller
sur `/agent/dossiers`. La barre de navigation change en conséquence — pas
d'« Accueil » ni de « Services » pour un conseiller, ces écrans servant à
déposer une demande en tant que client.

| Écran | Ce qu'on y fait |
| --- | --- |
| `pages/agent_dossiers.dart` | Tous les dossiers, filtrables par statut |
| `pages/agent_dossier.dart` | Le détail : pièces du client, avancement, envoi d'un document |
| `pages/agent_conversations.dart` | Les conversations, celles en attente d'abord |
| `pages/agent_chat.dart` | Répondre au nom de l'agence, joindre un document |

Un conseiller fait avancer un dossier (*Envoyée* → *En cours* → *Traitée*) et
peut y déposer des documents en retour — attestation, rapport, reçu. Ceux-ci
sont rangés **sous l'identifiant du client**, faute de quoi la policy de
lecture l'empêcherait de les rouvrir.

`ReserveAgent` (dans `main.dart`) évite de montrer ces écrans à un client,
mais ce n'est qu'un garde-fou d'affichage : le droit réel est tenu par la
RLS. Un client qui forcerait la route ne verrait de toute façon que ses
propres données. L'application décide de ce qu'elle montre, jamais de ce qui
est permis.

## Structure

```
lib/
  api/
    backend.dart          l'interface Backend + ErreurBackend
    supabase_backend.dart son implémentation Supabase
    api.dart              le point de bascule (une seule ligne à changer)
  data/                   contenus éditoriaux (services, conseil fiscal, audit, DSF)
  models.dart             compte, demande, pièce, message
  state/                  état de l'application (ChangeNotifier + InheritedNotifier)
  supabase_config.dart    coordonnées du projet, lues au build
  widgets/                briques d'interface partagées et illustrations
    envoi_demande.dart    le mixin d'envoi commun aux 7 services
    conversation.dart     bulle et barre de saisie, client comme conseiller
    document.dart         ouvrir une pièce du bucket privé, choisir un fichier
  pages/                  un fichier par écran
  theme.dart              charte graphique
```

Les écrans ne connaissent pas Supabase : ils ne parlent qu'à `Backend`.
Le jour où notre propre API prend le relais, il suffit d'en écrire une autre
implémentation et de changer la ligne d'export de `lib/api/api.dart`.

## État des données

| | Où |
| --- | --- |
| Compte, session, profil | **Supabase** (`auth` + table `profiles`) |
| Demandes des 7 services | **Supabase** (table `demandes`) |
| Pièces jointes | **Supabase Storage**, bucket privé `pieces` |
| Messagerie | **Supabase** (table `messages`, temps réel) |

La session est rétablie au lancement et survit au redémarrage : c'est
`supabase_flutter` qui conserve le jeton. Les demandes sont relues à
l'ouverture du profil, ce qui fait apparaître les changements de statut
décidés par un conseiller.

Les documents partent réellement dans le bucket, rangés sous
`<user_id>/<demande_id>/…` — c'est ce chemin que vérifie la policy de
stockage. Les pièces de l'inscription vont sous `<user_id>/compte/…`.

Si un téléversement échoue, la demande est déjà enregistrée : le conseiller
la voit avec ses pièces manquantes plutôt qu'elle ne se perde en silence. En
cas d'erreur, l'écran de service reste affiché — la saisie et les fichiers
déjà choisis ne sont pas perdus.

Reste à brancher : le paiement de la caution d'audit, qui demande un secret
côté serveur — donc une Edge Function.

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

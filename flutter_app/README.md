# Mon Comptable — CAM-TAXE (Flutter)

Application mobile **Android et iOS** de déclarations et de conseils fiscaux au
Cameroun, construite d'après les maquettes fournies.

> « Faites vos déclarations chez nous — 100 % sûr et rapide »

## Démarrer

L'application a besoin des clés du projet Supabase, fournies à la
compilation. Sans elles, elle affiche un écran « Application non configurée »
qui rappelle quoi renseigner.

```bash
flutter pub get

flutter run \
  --dart-define=SUPABASE_URL=https://votre-projet.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=votre-cle-anon

flutter build apk --release --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…
flutter build ipa --release --dart-define=SUPABASE_URL=… --dart-define=SUPABASE_ANON_KEY=…
```

Les valeurs se trouvent dans *Settings → API* du projet Supabase. La clé
`anon` est publique par nature : ce sont les policies RLS de
`../supabase/schema.sql` qui protègent les données, pas le secret de la clé.
Ne mettez **jamais** la clé `service_role` dans l'application : elle contourne
toutes les policies.

Vérifications — aucune clé n'est nécessaire, les tests utilisent une source de
données en mémoire :

```bash
flutter analyze
flutter test
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

Le mot de passe est désormais demandé aux deux profils : l'authentification en
exige un pour chaque compte. Cocher « Personne employée » ne donne aucun droit
particulier sur les dossiers des clients — cette habilitation se règle depuis
le tableau de bord Supabase.

## Structure

```
lib/
  api/           accès aux données : l'interface `Backend` et son implémentation
  data/          contenus éditoriaux (services, conseil fiscal, audit, DSF)
  models.dart    compte, demande, pièce, message
  state/         état de l'application (ChangeNotifier + InheritedNotifier)
  widgets/       briques d'interface partagées et illustrations
  pages/         un fichier par écran
  theme.dart     charte graphique
```

## Le back-end

Le compte, les demandes, les pièces jointes et la messagerie vivent dans
**Supabase**, comme pour l'application React : les deux clients partagent le
même schéma, décrit dans [`../supabase/schema.sql`](../supabase/schema.sql) et
documenté dans le [README de la racine](../README.md).

Seul le mode d'affichage (clair / sombre) reste sur l'appareil, via
`shared_preferences`.

### Passer à notre propre API

L'application ne connaît pas Supabase. Elle ne parle qu'à l'interface
`Backend` de [`lib/api/backend.dart`](lib/api/backend.dart) — sessions,
demandes, pièces, messages, temps réel — dont `lib/api/supabase_backend.dart`
est une implémentation parmi d'autres. C'est le pendant exact de
`src/api/types.ts` côté React.

Le jour où notre back-end prend le relais :

1. écrire `lib/api/backend_rest.dart` qui implémente `Backend` ;
2. changer la seule ligne d'affectation de `lib/api/api.dart`.

Aucun écran ni `AppState` à retoucher.

### Tests

C'est aussi ce qui rend l'application testable : `test/faux_backend.dart`
fournit une source de données en mémoire, installée par `utiliserBackend()`.
Les tests tournent donc sans réseau, sans projet Supabase et sans clés — et ne
bougeront pas d'une ligne le jour du changement de back-end.

### Reste à faire

- **Mode hors-ligne** : l'ancien stockage local a disparu, l'application exige
  maintenant une connexion. Un cache par-dessus l'interface `Backend` le
  rétablirait — utile vu la qualité du réseau.
- **Paiements** : la caution de l'audit n'est pas encaissée. Un encaissement
  mobile money demande un secret côté serveur, donc une Edge Function.

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

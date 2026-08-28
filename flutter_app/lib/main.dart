import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/accueil.dart';
import 'pages/admin_equipe.dart';
import 'pages/agent_chat.dart';
import 'pages/agent_conversations.dart';
import 'pages/agent_dossier.dart';
import 'pages/agent_dossiers.dart';
import 'pages/audit.dart';
import 'pages/auth.dart';
import 'pages/chat.dart';
import 'pages/conseil_fiscal.dart';
import 'pages/contentieux.dart';
import 'pages/darp.dart';
import 'pages/declarer.dart';
import 'pages/dsf.dart';
import 'pages/niu_acf.dart';
import 'pages/profil.dart';
import 'pages/services.dart';
import 'state/app_state.dart';
import 'supabase_config.dart';
import 'theme.dart';
import 'widgets/communs.dart';
import 'widgets/coquille.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sans coordonnées, on démarre quand même : l'application affiche un écran
  // qui explique quoi renseigner, plutôt qu'un écran noir.
  if (supabaseConfigure) {
    // `publishableKey` est le nouveau nom du paramètre : la clé « anon »
    // du tableau de bord se passe telle quelle.
    await Supabase.initialize(
      url: urlSupabase,
      publishableKey: cleAnonSupabase,
    );
  }

  final etat = AppState();
  await etat.charger();
  runApp(MonComptable(etat: etat));
}

class MonComptable extends StatelessWidget {
  const MonComptable({super.key, required this.etat});

  final AppState etat;

  @override
  Widget build(BuildContext context) {
    // Un déploiement mal configuré doit dire ce qui lui manque : sans cet
    // écran, l'application se lancerait pour échouer à la première action.
    if (!etat.configure) {
      return MaterialApp(
        title: 'Mon Comptable — CAM-TAXE',
        debugShowCheckedModeBanner: false,
        theme: construireTheme(),
        darkTheme: construireThemeSombre(),
        home: const EcranNonConfigure(),
      );
    }

    // ListenableBuilder : le MaterialApp doit se reconstruire quand le mode
    // d'affichage change, sinon le basculement clair/sombre resterait sans
    // effet (PorteeApp ne rebâtit que ses descendants).
    return PorteeApp(
      etat: etat,
      child: ListenableBuilder(
        listenable: etat,
        builder: (context, _) => MaterialApp(
        title: 'Mon Comptable — CAM-TAXE',
        debugShowCheckedModeBanner: false,
        theme: construireTheme(),
        darkTheme: construireThemeSombre(),
        themeMode: etat.themeMode,
        // Un conseiller n'a que faire de l'accueil client : il ouvre
        // directement ses dossiers.
        initialRoute: etat.routeAccueil,
        routes: {
          '/accueil': (_) => const PageAccueil(),
          '/auth': (_) => const PageAuth(),
          '/services': (_) => const PageServices(),
          '/chat': (_) => const PageChat(),
          '/profil': (_) => const PageProfil(),

          // Espace conseiller. L'accès n'est pas gardé ici : la RLS ne
          // servirait rien de plus à un client qui forcerait la route.
          '/agent/dossiers': (_) => const ReserveAgent(
                child: PageAgentDossiers(),
              ),
          '/agent/dossier': (_) => const ReserveAgent(
                child: PageAgentDossier(),
              ),
          '/agent/conversations': (_) => const ReserveAgent(
                child: PageAgentConversations(),
              ),
          '/agent/chat': (_) => const ReserveAgent(child: PageAgentChat()),

          // Administration des habilitations.
          '/admin/equipe': (_) => const ReserveAdmin(child: PageAdminEquipe()),

          // Les services exigent un compte.
          '/service/conseil-fiscal': (_) =>
              const RequiertCompte(child: PageConseilFiscal()),
          '/service/declarer': (_) =>
              const RequiertCompte(child: PageDeclarer()),
          '/service/darp': (_) => const RequiertCompte(child: PageDarp()),
          '/service/dsf': (_) => const RequiertCompte(child: PageDsf()),
          '/service/contentieux': (_) =>
              const RequiertCompte(child: PageContentieux()),
          '/service/niu-acf': (_) => const RequiertCompte(child: PageNiuAcf()),
          '/service/audit': (_) => const RequiertCompte(child: PageAudit()),
        },
        ),
      ),
    );
  }
}

/// Un compte est requis pour accéder aux services : sans compte, on
/// propose l'inscription plutôt que d'afficher le formulaire.
class RequiertCompte extends StatelessWidget {
  const RequiertCompte({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    if (etat.connecte) return child;

    return Scaffold(
      appBar: const BarreDegrade(titre: 'Créer un compte'),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(Espaces.xl),
          padding: const EdgeInsets.all(Espaces.xxl),
          decoration: BoxDecoration(
            color: context.cl.carte,
            borderRadius: Rayons.brXl,
            boxShadow: context.cl.ombreCarte,
            border: Border.all(color: context.cl.ligne),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: context.cl.orangeFantome,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_outline_rounded,
                    size: 31, color: Palette.orange),
              ),
              const SizedBox(height: Espaces.xl),
              const Text(
                "Vous n'êtes pas connecté",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: Espaces.sm),
              Text(
                'Il faut au préalable créer un compte pour bénéficier de nos '
                'services.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: context.cl.encreDouce,
                ),
              ),
              const SizedBox(height: Espaces.xl),
              BoutonEnvoyer(
                bloc: true,
                libelle: 'Créer un compte',
                icone: Icons.arrow_forward_rounded,
                onTap: () =>
                    Navigator.of(context).pushReplacementNamed('/auth'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Affiché quand `env.json` n'a pas été fourni au build.
///
/// Pendant du garde-fou de la version React : mieux vaut une consigne
/// lisible qu'une application qui se lance pour échouer plus loin.
class EcranNonConfigure extends StatelessWidget {
  const EcranNonConfigure({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Espaces.xl),
          child: Container(
            padding: const EdgeInsets.all(Espaces.xxl),
            decoration: BoxDecoration(
              color: context.cl.carte,
              borderRadius: Rayons.brXl,
              boxShadow: context.cl.ombreCarte,
              border: Border.all(color: context.cl.ligne),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: context.cl.orangeFantome,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_outlined,
                      size: 31, color: Palette.orange),
                ),
                const SizedBox(height: Espaces.xl),
                const Text(
                  'Application non configurée',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: Espaces.sm),
                Text(
                  'Les coordonnées du projet Supabase sont absentes. Copiez '
                  'env.example.json vers env.json, renseignez les deux '
                  'valeurs, puis relancez :',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.55,
                    color: context.cl.encreDouce,
                  ),
                ),
                const SizedBox(height: Espaces.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Espaces.md),
                  decoration: BoxDecoration(
                    color: context.cl.fondDoux,
                    borderRadius: Rayons.brMd,
                  ),
                  child: const SelectableText(
                    'flutter run --dart-define-from-file=env.json',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Écran réservé aux conseillers.
///
/// C'est un garde-fou d'affichage, pas une sécurité : le droit réel est tenu
/// par la RLS, et un client qui atteindrait ces routes n'y verrait de toute
/// façon que ses propres données. On évite simplement de lui montrer une
/// interface qui ne le concerne pas.
class ReserveAgent extends StatelessWidget {
  const ReserveAgent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    if (etat.estAgent) return child;

    return Scaffold(
      appBar: const BarreDegrade(titre: 'Espace conseiller'),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(Espaces.xl),
          padding: const EdgeInsets.all(Espaces.xxl),
          decoration: BoxDecoration(
            color: context.cl.carte,
            borderRadius: Rayons.brXl,
            boxShadow: context.cl.ombreCarte,
            border: Border.all(color: context.cl.ligne),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: context.cl.orangeFantome,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.badge_outlined,
                    size: 31, color: Palette.orange),
              ),
              const SizedBox(height: Espaces.xl),
              const Text(
                'Réservé aux conseillers',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: Espaces.sm),
              Text(
                "Cet espace est celui de l'équipe CAM-TAXE. Si vous êtes "
                'conseiller, demandez votre habilitation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: context.cl.encreDouce,
                ),
              ),
              const SizedBox(height: Espaces.xl),
              BoutonEnvoyer(
                bloc: true,
                libelle: "Retour à l'accueil",
                icone: Icons.arrow_forward_rounded,
                onTap: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/accueil', (r) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran réservé aux administrateurs.
///
/// Garde-fou d'affichage, comme [ReserveAgent] : le droit réel est tenu par
/// la base, qui refuse de servir la liste des comptes et rejette toute
/// nomination ne venant pas d'un admin.
class ReserveAdmin extends StatelessWidget {
  const ReserveAdmin({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    if (etat.estAdmin) return child;

    return Scaffold(
      appBar: const BarreDegrade(titre: 'Équipe'),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(Espaces.xl),
          padding: const EdgeInsets.all(Espaces.xxl),
          decoration: BoxDecoration(
            color: context.cl.carte,
            borderRadius: Rayons.brXl,
            boxShadow: context.cl.ombreCarte,
            border: Border.all(color: context.cl.ligne),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: context.cl.orangeFantome,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_outlined,
                    size: 31, color: Palette.orange),
              ),
              const SizedBox(height: Espaces.xl),
              const Text(
                'Réservé aux administrateurs',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: Espaces.sm),
              Text(
                "Seul un administrateur nomme les conseillers. Ce statut se "
                'règle depuis le tableau de bord.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.55,
                  color: context.cl.encreDouce,
                ),
              ),
              const SizedBox(height: Espaces.xl),
              BoutonEnvoyer(
                bloc: true,
                libelle: 'Retour',
                icone: Icons.arrow_forward_rounded,
                onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(
                    PorteeApp.of(context).routeAccueil, (r) => false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

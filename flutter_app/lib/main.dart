import 'package:flutter/material.dart';

import 'pages/accueil.dart';
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
import 'theme.dart';
import 'widgets/communs.dart';
import 'widgets/coquille.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final etat = AppState();
  await etat.charger();
  runApp(MonComptable(etat: etat));
}

class MonComptable extends StatelessWidget {
  const MonComptable({super.key, required this.etat});

  final AppState etat;

  @override
  Widget build(BuildContext context) {
    return PorteeApp(
      etat: etat,
      child: MaterialApp(
        title: 'Mon Comptable — CAM-TAXE',
        debugShowCheckedModeBanner: false,
        theme: construireTheme(),
        initialRoute: '/accueil',
        routes: {
          '/accueil': (_) => const PageAccueil(),
          '/auth': (_) => const PageAuth(),
          '/services': (_) => const PageServices(),
          '/chat': (_) => const PageChat(),
          '/profil': (_) => const PageProfil(),

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
              const Text(
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

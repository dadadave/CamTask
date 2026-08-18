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
      appBar: AppBar(title: const Text('Créer un compte')),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            color: Palette.carte,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ombreCarte,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Vous n'êtes pas connecté",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'Il faut au préalable créer un compte pour bénéficier de nos '
                'services.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  color: Palette.encreDouce,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Palette.orangeClair,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushReplacementNamed('/auth'),
                  child: const Text('Créer un compte / se connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

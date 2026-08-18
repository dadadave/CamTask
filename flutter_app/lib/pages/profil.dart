import 'package:flutter/material.dart';

import '../models.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/coquille.dart';

class PageProfil extends StatelessWidget {
  const PageProfil({super.key});

  @override
  Widget build(BuildContext context) {
    final etat = PorteeApp.of(context);
    final compte = etat.compte;

    if (compte == null) {
      return Coquille(
        titre: 'Profil',
        routeCourante: '/profil',
        retour: false,
        enfants: [
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
            decoration: BoxDecoration(
              color: Palette.carte,
              borderRadius: BorderRadius.circular(16),
              boxShadow: ombreCarte,
            ),
            child: Column(
              children: [
                const Text(
                  "Vous n'êtes pas connecté",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Il faut au préalable créer un compte pour bénéficier de nos '
                  'services et suivre vos demandes.',
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
                        Navigator.of(context).pushNamed('/auth'),
                    child: const Text('Créer un compte / se connecter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Coquille(
      titre: 'Profil',
      routeCourante: '/profil',
      retour: false,
      enfants: [
        Container(
          margin: const EdgeInsets.fromLTRB(14, 18, 14, 18),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Palette.carte,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ombreCarte,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Palette.orangeClair,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  compte.initiales,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${compte.prenom} ${compte.nom}'.trim(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${compte.role == Role.employe ? 'Personne employée' : 'Utilisateur'}'
                      ' · membre depuis le ${compte.creeLe}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Palette.encreDouce,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          decoration: BoxDecoration(
            color: Palette.carte,
            borderRadius: BorderRadius.circular(16),
            boxShadow: ombreDouce,
          ),
          child: Column(
            children: [
              _Ligne(libelle: 'Email', valeur: compte.email),
              _Ligne(libelle: 'Téléphone', valeur: compte.telephone),
              _Ligne(
                libelle: compte.role == Role.employe
                    ? 'N° contribuable'
                    : 'NIU',
                valeur: compte.niu,
              ),
              _Ligne(
                libelle: 'Pièces fournies',
                valeur: '${compte.pieces.length}',
                derniere: true,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
          child: Text(
            'MES DEMANDES (${etat.demandes.length})',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Palette.encreDouce,
              letterSpacing: 0.4,
            ),
          ),
        ),
        if (etat.demandes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            child: Text(
              "Aucune demande pour l'instant.\n"
              'Rendez-vous dans « service » pour en créer une.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: Palette.encreDouce,
              ),
            ),
          )
        else
          for (final d in etat.demandes) _CarteDemande(demande: d),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 30),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Palette.orange,
              side: const BorderSide(color: Palette.orange),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            onPressed: () {
              etat.seDeconnecter();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/auth',
                (r) => false,
              );
            },
            child: const Text('Se déconnecter'),
          ),
        ),
      ],
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne({
    required this.libelle,
    required this.valeur,
    this.derniere = false,
  });

  final String libelle;
  final String valeur;
  final bool derniere;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: derniere
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: Palette.fond)),
            ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              libelle,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Palette.encreDouce,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valeur.isEmpty ? '—' : valeur,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  const _CarteDemande({required this.demande});

  final Demande demande;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Palette.carte,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ombreDouce,
        border: const Border(
          left: BorderSide(color: Palette.orange, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  demande.serviceLibelle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                demande.date,
                style: const TextStyle(fontSize: 10.5, color: Palette.grise),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            demande.resume,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: Palette.encreDouce,
            ),
          ),
          if (demande.pieces.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '📎 ${demande.pieces.length} document(s) : '
              '${demande.pieces.map((p) => p.fichier).join(', ')}',
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: Palette.encreDouce,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Palette.orangeFantome,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              demande.statut.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Palette.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

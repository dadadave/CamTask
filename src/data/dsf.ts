/**
 * Contenu de la page DSF (Déclaration Statistique et Fiscale).
 * Les pièces sont regroupées en : états financiers, états fiscaux,
 * documents administratifs et support de transmission.
 */

import type { SectionDocuments } from './audit'

export const SECTIONS_DSF: SectionDocuments[] = [
  {
    id: 'etats-financiers',
    titre: 'États financiers',
    documents: [
      'Bilan (actif et passif)',
      'Compte de résultat',
      'Tableau des flux de trésorerie',
      'Tableau de variation des capitaux propres',
      'Notes annexes',
    ],
  },
  {
    id: 'etats-fiscaux',
    titre: 'États fiscaux',
    documents: [
      'État de détermination du résultat fiscal',
      'État des immobilisations et amortissements',
      'État des provisions',
      'État des stocks',
      'État des produits et charges par nature',
      'État des frais généraux',
      'État des loyers payés',
      'État des rémunérations versées au personnel',
      "État des crédits d'impôt (TVA, IS, etc.)",
      'État des impôts et taxes payés',
      'État des créances et dettes',
      'État des emprunts et dettes assimilées',
      'État des avances et acomptes reçus ou versés',
      'Déclaration des résultats (formulaire officiel)',
    ],
  },
  {
    id: 'documents-administratifs',
    titre: 'Documents administratifs',
    documents: [
      'Copie du Registre de Commerce (RCCM)',
      "Numéro d'Identifiant Unique (NIU)",
      "Lettre d'envoi ou bordereau de transmission",
      "Procès-verbal d'assemblée générale (approuvant les états financiers, si exigé)",
      "Rapport du commissaire aux comptes (si l'entreprise y est soumise)",
    ],
  },
  {
    id: 'support-transmission',
    titre: 'Support de transmission',
    documents: [
      'Support électronique (clé USB, CD, ou via la plateforme e-tax.cm si télé-déclaré)',
      'Version papier signée (en 2 exemplaires, dont un pour la DGI et un pour l’entreprise, avec cachets et signatures)',
      "Factures d'achats",
    ],
  },
]

/** Destination de la DSF — question posée en tête de formulaire. */
export const DESTINATIONS_DSF = ['DSF pour impôt', 'DSF pour la banque'] as const

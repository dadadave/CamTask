/** Contenu de la page « Faire un audit » : titres reformulés entre guillemets. */

export type SectionDocuments = {
  id: string
  titre: string
  documents: string[]
}

export const TYPES_AUDIT = [
  'Audit financier',
  'Audit fiscal',
  'Audit interne',
  'Audit de conformité',
]

export const AUDIT_PRESENTATION = [
  "Il existe 4 types d'audit : l'audit financier, l'audit fiscal, l'audit interne et l'audit de conformité. Les pièces à fournir dépendent du *type d'audit* et du *secteur d'activité*.",
  "Voici une liste de documents à préparer pour un audit quel que soit votre secteur d'activité.",
]

export const AUDIT_CONSIGNE =
  'Télécharger les documents en un seul PDF dans chacune des sections.'

export const SECTIONS_AUDIT: SectionDocuments[] = [
  {
    id: 'imperatifs',
    titre: "Documents impératifs devant être préparés pour tout type d'audit",
    documents: [
      "Statuts juridiques : Statuts de l'entreprise, registre de commerce (RCCM), agréments, etc.",
      "Organigramme : Structure de l'entreprise, rôles des responsables.",
      "Procès-verbaux : PV des assemblées générales, décisions du conseil d'administration.",
      'Politiques et procédures internes : Manuel de gestion, chartes éthiques, procédures comptables.',
    ],
  },
  {
    id: 'financier',
    titre: '« Audit financier (vérification des comptes) »',
    documents: [
      'Comptes annuels : Bilan, compte de résultat, annexes légales.',
      'Grand livre général et journaux comptables : Détail des écritures comptables.',
      'Relevés bancaires : Conciliation bancaire (comptes courants, emprunts).',
      'Factures clients et fournisseurs : Justificatifs des ventes, achats et dépenses.',
      'Contrats clés : Contrats clients, partenariats, prêts bancaires.',
      "Inventaires physiques : Rapports de stocks ou d'actifs (immobilisations).",
    ],
  },
  {
    id: 'fiscal',
    titre: '« Audit fiscal (contrôle des impôts) »',
    documents: [
      'Déclarations fiscales : Déclarations de TVA, impôt sur les sociétés (IS), IRPP.',
      'Relevés de paie et charges sociales : Bulletin de salaire, CNPS/CAC (Cameroun).',
      "Justificatifs de crédits d'impôt : Factures éligibles (ex. : travaux, dons).",
      "NIU (Numéro d'Identifiant Unique) : Attestation de numéro fiscal.",
      "Documents douaniers : Déclarations d'import/export (si applicable).",
    ],
  },
  {
    id: 'interne',
    titre: '« Audit interne (gestion des risques) »',
    documents: [
      "Rapports d'audits précédents : Suivi des recommandations.",
      'Évaluation des risques : Cartographie des risques opérationnels, financiers, etc.',
      'Preuves de contrôles internes : Ex. : signatures des validations, rapports de vérification.',
      'Politiques de sécurité : Cybersécurité, protection des données.',
    ],
  },
  {
    id: 'conformite',
    titre: '« Audit de conformité (réglementation) »',
    documents: [
      'Certifications légales : Attestations de conformité (ex. : normes ISO, RGPD).',
      "Registres obligatoires : Registre des traitements de données, registre des accidents du travail.",
      'Contrats de travail : Respect du Code du travail (congés, salaires, heures supplémentaires).',
      "Documents environnementaux : Autorisations, rapports d'impact (si applicable).",
    ],
  },
]

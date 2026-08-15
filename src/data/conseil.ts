/**
 * Contenu de la page « Besoin de conseil fiscale ».
 * L'utilisateur choisit une question, puis une ou plusieurs sous-questions,
 * puis saisit sa préoccupation.
 */

export type SousQuestion = {
  id: string
  /** Titre en gras / orange. */
  titre: string
  /** Explication qui suit les deux points. */
  detail: string
}

export type QuestionConseil = {
  id: string
  titre: string
  sousQuestions: SousQuestion[]
}

export const CONSEIL_INTRO =
  "Plusieurs éléments peuvent inciter une personne à solliciter un conseil fiscal, que ce soit pour optimiser sa situation, éviter des erreurs coûteuses ou s'adapter à des changements personnels ou législatifs. En voici une synthèse organisée :"

export const CONSEIL_ACCROCHE =
  "Vérifier que vos impôts ont bien été payés afin d'éviter toutes déconvenues avec l'administration fiscale."

export const CONSEIL_CLOTURE = [
  "Un conseil fiscal permet de personnaliser les stratégies, garantir la conformité et exploiter les opportunités légales pour réduire l'impôt.",
  'Pour toutes ces préoccupations nous vous proposons des solutions adaptées à vos moyens en fonction de vos réalités.',
]

export const QUESTIONS_CONSEIL: QuestionConseil[] = [
  {
    id: 'q1',
    titre: 'Question 1 : Situations personnelles complexes',
    sousQuestions: [
      {
        id: 'q1s1',
        titre: 'Revenus multiples',
        detail: 'Cumul de salaires, revenus locatifs, freelance, investissements, etc.',
      },
      {
        id: 'q1s2',
        titre: 'Événements familiaux',
        detail:
          'Mariage, divorce, naissance, décès. ex. : impacts sur les parts fiscales ou les droits de succession',
      },
      {
        id: 'q1s3',
        titre: 'Achat/vente immobilière',
        detail: 'Calcul des plus-values, exonérations, ou résidence principale/secondaire.',
      },
      {
        id: 'q1s4',
        titre: 'Héritage ou donation',
        detail: 'Optimisation des abattements, choix entre donation ou testament.',
      },
      {
        id: 'q1s5',
        titre: 'Expatriation/retour au Cameroun',
        detail: 'Gestion de la résidence fiscale, imposition des revenus étrangers.',
      },
    ],
  },
  {
    id: 'q2',
    titre: 'Question 2. Activité professionnelle ou entrepreneuriale',
    sousQuestions: [
      {
        id: 'q2s1',
        titre: "Création d'entreprise",
        detail: 'Choix du statut (auto-entrepreneur, SARL, SNC...) pour minimiser les impôts.',
      },
      {
        id: 'q2s2',
        titre: "Gestion d'une société",
        detail: 'Optimisation de la rémunération (dividendes vs salaire), TVA, IS.',
      },
      {
        id: 'q2s3',
        titre: 'International',
        detail: "Opérations à l'étranger, prix de transfert, taxes douanières.",
      },
      {
        id: 'q2s4',
        titre: "Transmission ou cession d'entreprise",
        detail: 'Fiscalité de la vente, etc.',
      },
    ],
  },
  {
    id: 'q3',
    titre: 'Question 3. Investissements financiers ou patrimoniaux',
    sousQuestions: [
      {
        id: 'q3s1',
        titre: 'Produits complexes',
        detail: 'Assurance-vie, cryptomonnaies, private equity.',
      },
      {
        id: 'q3s2',
        titre: 'Plus-values',
        detail:
          "Optimisation de l'abattement après détention (ex. : immobiliers à 22/30 ans).",
      },
      {
        id: 'q3s3',
        titre: "Richesse à l'étranger",
        detail: 'Déclaration de comptes bancaires étrangers.',
      },
    ],
  },
  {
    id: 'q4',
    titre: 'Question 4. Changements législatifs ou contrôles fiscaux',
    sousQuestions: [
      {
        id: 'q4s1',
        titre: 'Nouveautés fiscales',
        detail: 'Réformes (ex. : flat tax, prélèvement à la source).',
      },
      {
        id: 'q4s2',
        titre: 'Contrôle fiscal',
        detail: 'Assistance en cas de vérification, redressement, ou recours.',
      },
      {
        id: 'q4s3',
        titre: 'Obligations internationales',
        detail: 'Double imposition, déclaration des actifs offshore.',
      },
    ],
  },
  {
    id: 'q5',
    titre: 'Question 5. Optimisation et planification',
    sousQuestions: [
      {
        id: 'q5s1',
        titre: "Réductions d'impôts",
        detail: 'Utilisation de niches fiscales (ex. : Pinel, dons, emploi à domicile).',
      },
      {
        id: 'q5s2',
        titre: 'Transmission du patrimoine',
        detail: 'Donations en cascade, assurance-vie, trusts.',
      },
      {
        id: 'q5s3',
        titre: 'Retraite',
        detail: 'Choix entre PER, retraite par capitalisation, etc.',
      },
    ],
  },
  {
    id: 'q6',
    titre: 'Question 6. Événements imprévus',
    sousQuestions: [
      {
        id: 'q6s1',
        titre: 'Gain exceptionnel',
        detail: "Loterie, héritage inattendu, vente d'un actif.",
      },
      {
        id: 'q6s2',
        titre: 'Erreurs de déclaration',
        detail: 'Régularisation spontanée pour éviter des sanctions.',
      },
    ],
  },
  {
    id: 'q7',
    titre: 'Question 7. Besoin de sécurisation',
    sousQuestions: [
      {
        id: 'q7s1',
        titre: 'Vérification',
        detail: "S'assurer de la conformité de sa déclaration.",
      },
      {
        id: 'q7s2',
        titre: 'Anticipation',
        detail: 'Préparer une succession ou une transmission en minimisant les coûts.',
      },
    ],
  },
]

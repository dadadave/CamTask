// Contenu de la page « Besoin de conseil fiscale ».
// L'utilisateur choisit une question, puis une ou plusieurs sous-questions,
// puis saisit sa préoccupation.

class SousQuestion {
  const SousQuestion({
    required this.id,
    required this.titre,
    required this.detail,
  });

  final String id;

  /// Titre mis en avant en orange.
  final String titre;

  /// Explication qui suit les deux points.
  final String detail;
}

class QuestionConseil {
  const QuestionConseil({
    required this.id,
    required this.titre,
    required this.sousQuestions,
  });

  final String id;
  final String titre;
  final List<SousQuestion> sousQuestions;
}

const conseilAccroche =
    "Vérifier que vos impôts ont bien été payés afin d'éviter toutes "
    "déconvenues avec l'administration fiscale.";

const conseilIntro =
    "Plusieurs éléments peuvent inciter une personne à solliciter un conseil "
    "fiscal, que ce soit pour optimiser sa situation, éviter des erreurs "
    "coûteuses ou s'adapter à des changements personnels ou législatifs. "
    "En voici une synthèse organisée :";

const conseilCloture = <String>[
  "Un conseil fiscal permet de personnaliser les stratégies, garantir la "
      "conformité et exploiter les opportunités légales pour réduire l'impôt.",
  "Pour toutes ces préoccupations nous vous proposons des solutions adaptées "
      "à vos moyens en fonction de vos réalités.",
];

const questionsConseil = <QuestionConseil>[
  QuestionConseil(
    id: 'q1',
    titre: 'Question 1 : Situations personnelles complexes',
    sousQuestions: [
      SousQuestion(
        id: 'q1s1',
        titre: 'Revenus multiples',
        detail:
            'Cumul de salaires, revenus locatifs, freelance, investissements, etc.',
      ),
      SousQuestion(
        id: 'q1s2',
        titre: 'Événements familiaux',
        detail:
            'Mariage, divorce, naissance, décès. ex. : impacts sur les parts '
            'fiscales ou les droits de succession',
      ),
      SousQuestion(
        id: 'q1s3',
        titre: 'Achat/vente immobilière',
        detail:
            'Calcul des plus-values, exonérations, ou résidence principale/secondaire.',
      ),
      SousQuestion(
        id: 'q1s4',
        titre: 'Héritage ou donation',
        detail:
            'Optimisation des abattements, choix entre donation ou testament.',
      ),
      SousQuestion(
        id: 'q1s5',
        titre: 'Expatriation/retour au Cameroun',
        detail:
            'Gestion de la résidence fiscale, imposition des revenus étrangers.',
      ),
    ],
  ),
  QuestionConseil(
    id: 'q2',
    titre: 'Question 2. Activité professionnelle ou entrepreneuriale',
    sousQuestions: [
      SousQuestion(
        id: 'q2s1',
        titre: "Création d'entreprise",
        detail:
            'Choix du statut (auto-entrepreneur, SARL, SNC...) pour minimiser '
            'les impôts.',
      ),
      SousQuestion(
        id: 'q2s2',
        titre: "Gestion d'une société",
        detail: 'Optimisation de la rémunération (dividendes vs salaire), TVA, IS.',
      ),
      SousQuestion(
        id: 'q2s3',
        titre: 'International',
        detail: "Opérations à l'étranger, prix de transfert, taxes douanières.",
      ),
      SousQuestion(
        id: 'q2s4',
        titre: "Transmission ou cession d'entreprise",
        detail: 'Fiscalité de la vente, etc.',
      ),
    ],
  ),
  QuestionConseil(
    id: 'q3',
    titre: 'Question 3. Investissements financiers ou patrimoniaux',
    sousQuestions: [
      SousQuestion(
        id: 'q3s1',
        titre: 'Produits complexes',
        detail: 'Assurance-vie, cryptomonnaies, private equity.',
      ),
      SousQuestion(
        id: 'q3s2',
        titre: 'Plus-values',
        detail:
            "Optimisation de l'abattement après détention (ex. : immobiliers "
            'à 22/30 ans).',
      ),
      SousQuestion(
        id: 'q3s3',
        titre: "Richesse à l'étranger",
        detail: 'Déclaration de comptes bancaires étrangers.',
      ),
    ],
  ),
  QuestionConseil(
    id: 'q4',
    titre: 'Question 4. Changements législatifs ou contrôles fiscaux',
    sousQuestions: [
      SousQuestion(
        id: 'q4s1',
        titre: 'Nouveautés fiscales',
        detail: 'Réformes (ex. : flat tax, prélèvement à la source).',
      ),
      SousQuestion(
        id: 'q4s2',
        titre: 'Contrôle fiscal',
        detail: 'Assistance en cas de vérification, redressement, ou recours.',
      ),
      SousQuestion(
        id: 'q4s3',
        titre: 'Obligations internationales',
        detail: 'Double imposition, déclaration des actifs offshore.',
      ),
    ],
  ),
  QuestionConseil(
    id: 'q5',
    titre: 'Question 5. Optimisation et planification',
    sousQuestions: [
      SousQuestion(
        id: 'q5s1',
        titre: "Réductions d'impôts",
        detail:
            'Utilisation de niches fiscales (ex. : Pinel, dons, emploi à domicile).',
      ),
      SousQuestion(
        id: 'q5s2',
        titre: 'Transmission du patrimoine',
        detail: 'Donations en cascade, assurance-vie, trusts.',
      ),
      SousQuestion(
        id: 'q5s3',
        titre: 'Retraite',
        detail: 'Choix entre PER, retraite par capitalisation, etc.',
      ),
    ],
  ),
  QuestionConseil(
    id: 'q6',
    titre: 'Question 6. Événements imprévus',
    sousQuestions: [
      SousQuestion(
        id: 'q6s1',
        titre: 'Gain exceptionnel',
        detail: "Loterie, héritage inattendu, vente d'un actif.",
      ),
      SousQuestion(
        id: 'q6s2',
        titre: 'Erreurs de déclaration',
        detail: 'Régularisation spontanée pour éviter des sanctions.',
      ),
    ],
  ),
  QuestionConseil(
    id: 'q7',
    titre: 'Question 7. Besoin de sécurisation',
    sousQuestions: [
      SousQuestion(
        id: 'q7s1',
        titre: 'Vérification',
        detail: "S'assurer de la conformité de sa déclaration.",
      ),
      SousQuestion(
        id: 'q7s2',
        titre: 'Anticipation',
        detail:
            'Préparer une succession ou une transmission en minimisant les coûts.',
      ),
    ],
  ),
];

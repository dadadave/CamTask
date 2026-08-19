/// Les 7 services de l'application, dans l'ordre des maquettes.
class Service {
  const Service({
    required this.id,
    required this.libelle,
    required this.route,
    this.sousTitre,
  });

  final String id;
  final String libelle;
  final String route;
  final String? sousTitre;
}

const services = <Service>[
  Service(
    id: 'conseil',
    libelle: 'Besoin de conseil fiscale',
    route: '/service/conseil-fiscal',
  ),
  Service(
    id: 'declarer',
    libelle: 'Declarer et payer vos impots',
    route: '/service/declarer',
  ),
  Service(
    id: 'darp',
    libelle: 'DARP/IRPP',
    sousTitre: 'Déclaration annuelle des revenus des particuliers',
    route: '/service/darp',
  ),
  Service(
    id: 'dsf',
    libelle: 'DSF',
    sousTitre: 'Déclaration statistique et fiscale',
    route: '/service/dsf',
  ),
  Service(
    id: 'contentieux',
    libelle: 'Contentieux fiscal',
    route: '/service/contentieux',
  ),
  Service(
    id: 'niu-acf',
    libelle: 'Acquérir son NIU / ACF',
    route: '/service/niu-acf',
  ),
  Service(
    id: 'audit',
    libelle: 'Faire un audit',
    route: '/service/audit',
  ),
];

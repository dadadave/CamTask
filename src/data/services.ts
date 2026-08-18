export type Service = {
  id: string
  /** Libellé affiché sur la liste des services et en en-tête de page. */
  label: string
  /** Complément affiché en plus petit à côté du libellé. */
  sub?: string
  path: string
}

/** Les 7 services de l'application, dans l'ordre des maquettes. */
export const SERVICES: Service[] = [
  {
    id: 'conseil',
    label: 'Besoin de conseil fiscale',
    path: '/service/conseil-fiscal',
  },
  {
    id: 'declarer',
    label: 'Declarer et payer vos impots',
    path: '/service/declarer',
  },
  {
    id: 'darp',
    label: 'DARP/IRPP',
    sub: 'Déclaration annuelle des revenus des particuliers',
    path: '/service/darp',
  },
  {
    id: 'dsf',
    label: 'DSF',
    sub: 'Déclaration statistique et fiscale',
    path: '/service/dsf',
  },
  {
    id: 'contentieux',
    label: 'Contentieux fiscal',
    path: '/service/contentieux',
  },
  {
    id: 'niu-acf',
    label: 'Acquérir son NIU / ACF',
    path: '/service/niu-acf',
  },
  {
    id: 'audit',
    label: 'Faire un audit',
    path: '/service/audit',
  },
]

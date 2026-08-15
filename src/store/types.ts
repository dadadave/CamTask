/** Rôle choisi à l'inscription : client ou personne employée. */
export type Role = 'utilisateur' | 'employe'

/** Un document téléversé (on ne garde que le nom du fichier côté maquette). */
export type Piece = {
  label: string
  fileName: string
}

export type Compte = {
  role: Role
  nom: string
  prenom: string
  email: string
  telephone: string
  /** NIU / numéro de contribuable. */
  niu: string
  pieces: Piece[]
  creeLe: string
}

/** Une demande envoyée depuis l'un des 7 services. */
export type Demande = {
  id: string
  serviceId: string
  serviceLabel: string
  resume: string
  pieces: Piece[]
  statut: 'Envoyée' | 'En cours' | 'Traitée'
  date: string
}

export type Message = {
  id: string
  auteur: 'moi' | 'agent'
  texte: string
  fichier?: string
  heure: string
}

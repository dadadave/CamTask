import type { Compte, Demande, Message, Role } from '../store/types'

/**
 * Contrat que doit remplir une source de données, quelle qu'elle soit.
 *
 * L'application ne connaît que cette interface : ni les pages ni le store
 * n'importent Supabase. Remplacer Supabase par notre propre API se limite
 * donc à écrire une seconde implémentation et à changer la ligne d'export
 * de `src/api/index.ts`.
 */

/** Un document choisi par l'utilisateur, avec son contenu réel. */
export type PieceEnvoi = {
  label: string
  fichier: File
}

export type InscriptionInput = {
  role: Role
  nom: string
  prenom: string
  email: string
  telephone: string
  niu: string
  motDePasse: string
  pieces: PieceEnvoi[]
}

export type DemandeInput = {
  serviceId: string
  serviceLabel: string
  resume: string
  /** Absent pour les services qui ne demandent aucun document (conseil fiscal). */
  pieces?: PieceEnvoi[]
}

export type MessageInput = {
  texte: string
  fichier?: File
}

export interface Backend {
  /** Compte déjà connecté sur cet appareil, ou `null`. */
  sessionActuelle(): Promise<Compte | null>
  inscription(input: InscriptionInput): Promise<Compte>
  connexion(email: string, motDePasse: string): Promise<Compte>
  deconnexion(): Promise<void>

  listerDemandes(): Promise<Demande[]>
  creerDemande(input: DemandeInput): Promise<Demande>

  listerMessages(): Promise<Message[]>
  envoyerMessage(input: MessageInput): Promise<Message>
  /**
   * Écoute les messages entrants (réponses des agents).
   * Renvoie la fonction à appeler pour se désabonner.
   */
  souscrireMessages(onMessage: (m: Message) => void): () => void
}

/**
 * Erreur destinée à être affichée telle quelle à l'utilisateur.
 * Les implémentations traduisent leurs erreurs techniques en messages clairs.
 */
export class ErreurBackend extends Error {
  constructor(message: string, readonly cause?: unknown) {
    super(message)
    this.name = 'ErreurBackend'
  }
}

/** Message affichable pour n'importe quelle erreur remontée par le backend. */
export function messageErreur(e: unknown): string {
  if (e instanceof ErreurBackend) return e.message
  if (e instanceof Error && e.message) return e.message
  return 'Une erreur est survenue. Réessayez.'
}

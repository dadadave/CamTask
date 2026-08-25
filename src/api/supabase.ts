import { createClient, type SupabaseClient } from '@supabase/supabase-js'
import type { Compte, Demande, Message, Piece, Role } from '../store/types'
import {
  ErreurBackend,
  type Backend,
  type DemandeInput,
  type InscriptionInput,
  type MessageInput,
  type PieceEnvoi,
} from './types'

/* -------------------------------------------------------------------------- */
/*  Client                                                                    */
/* -------------------------------------------------------------------------- */

const URL = import.meta.env.VITE_SUPABASE_URL
const CLE = import.meta.env.VITE_SUPABASE_ANON_KEY

/**
 * Le `.env` est-il renseigné ?
 *
 * On se garde bien de lever une erreur au chargement du module : le build
 * réussit — Vite n'exécute pas ce code — mais le déploiement n'afficherait
 * qu'une page blanche, sans la moindre explication. L'application préfère
 * afficher un écran qui dit quoi faire.
 */
export const supabaseConfigure = Boolean(URL && CLE)

const MESSAGE_CONFIG =
  'Configuration Supabase absente : renseignez VITE_SUPABASE_URL et ' +
  'VITE_SUPABASE_ANON_KEY (voir .env.example).'

let client: SupabaseClient | null = null

/** Client créé à la première utilisation, jamais au chargement du module. */
function sb(): SupabaseClient {
  if (!client) {
    if (!supabaseConfigure) throw new ErreurBackend(MESSAGE_CONFIG)
    client = createClient(URL, CLE, {
      auth: { persistSession: true, autoRefreshToken: true },
    })
  }
  return client
}

const BUCKET = 'pieces'

/* -------------------------------------------------------------------------- */
/*  Utilitaires                                                               */
/* -------------------------------------------------------------------------- */

/** Rend un nom de fichier utilisable comme clé de stockage. */
function assainir(nom: string) {
  return nom
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/[^a-zA-Z0-9._-]/g, '-')
    .slice(-80)
}

function dateFr(iso: string) {
  return new Date(iso).toLocaleDateString('fr-FR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  })
}

function heureFr(iso: string) {
  return new Date(iso).toLocaleTimeString('fr-FR', {
    hour: '2-digit',
    minute: '2-digit',
  })
}

/** Traduit les erreurs techniques de Supabase en messages affichables. */
function traduire(message: string): string {
  const m = message.toLowerCase()
  if (m.includes('invalid login credentials')) return 'Email ou mot de passe incorrect.'
  if (m.includes('email not confirmed'))
    return "Votre email n'est pas encore confirmé. Vérifiez votre boîte de réception."
  if (m.includes('user already registered') || m.includes('already been registered'))
    return 'Un compte existe déjà avec cet email. Connectez-vous.'
  if (m.includes('password should be'))
    return 'Le mot de passe doit contenir au moins 6 caractères.'
  if (m.includes('failed to fetch') || m.includes('network'))
    return 'Connexion au serveur impossible. Vérifiez votre accès à Internet.'
  if (m.includes('row-level security') || m.includes('violates row-level'))
    return "Vous n'avez pas l'autorisation d'effectuer cette action."
  return message
}

function echouer(message: string, cause?: unknown): never {
  throw new ErreurBackend(traduire(message), cause)
}

async function idUtilisateur(): Promise<string> {
  const { data } = await sb().auth.getUser()
  if (!data.user) echouer('Votre session a expiré. Reconnectez-vous.')
  return data.user.id
}

/* -------------------------------------------------------------------------- */
/*  Pièces jointes                                                            */
/* -------------------------------------------------------------------------- */

type LigneProfil = {
  role: Role
  nom: string
  prenom: string
  telephone: string
  niu: string
  cree_le: string
}

/**
 * Dépose les fichiers dans le bucket privé puis les référence en base.
 * `demandeId` est nul pour les pièces fournies à l'inscription.
 */
async function televerser(
  uid: string,
  pieces: PieceEnvoi[],
  demandeId: string | null,
): Promise<Piece[]> {
  const deposees: Piece[] = []

  for (const { label, fichier } of pieces) {
    const dossier = demandeId ?? 'compte'
    const chemin = `${uid}/${dossier}/${crypto.randomUUID()}-${assainir(fichier.name)}`

    const { error: erreurDepot } = await sb().storage
      .from(BUCKET)
      .upload(chemin, fichier, { contentType: fichier.type || undefined })
    if (erreurDepot) echouer(`Envoi de « ${label} » impossible : ${erreurDepot.message}`)

    const { error: erreurLigne } = await sb().from('pieces').insert({
      user_id: uid,
      demande_id: demandeId,
      label,
      chemin,
      nom_fichier: fichier.name,
    })
    if (erreurLigne) echouer(erreurLigne.message)

    deposees.push({ label, fileName: fichier.name })
  }

  return deposees
}

async function piecesDuCompte(uid: string): Promise<Piece[]> {
  const { data, error } = await sb()
    .from('pieces')
    .select('label, nom_fichier')
    .eq('user_id', uid)
    .is('demande_id', null)
  if (error) echouer(error.message)
  return (data ?? []).map((p) => ({ label: p.label, fileName: p.nom_fichier }))
}

async function compteDepuisProfil(uid: string, email: string): Promise<Compte> {
  const { data, error } = await sb()
    .from('profiles')
    .select('role, nom, prenom, telephone, niu, cree_le')
    .eq('id', uid)
    .single<LigneProfil>()
  if (error) echouer(error.message)

  return {
    role: data.role,
    nom: data.nom,
    prenom: data.prenom,
    email,
    telephone: data.telephone,
    niu: data.niu,
    pieces: await piecesDuCompte(uid),
    creeLe: dateFr(data.cree_le),
  }
}

/* -------------------------------------------------------------------------- */
/*  Implémentation                                                            */
/* -------------------------------------------------------------------------- */

export const backendSupabase: Backend = {
  async sessionActuelle() {
    const { data } = await sb().auth.getSession()
    const user = data.session?.user
    if (!user) return null
    return compteDepuisProfil(user.id, user.email ?? '')
  },

  async inscription(input: InscriptionInput) {
    const { role, nom, prenom, email, telephone, niu, motDePasse, pieces } = input

    // Le profil est créé côté base par le déclencheur `on_auth_user_created`
    // à partir de ces métadonnées.
    const { data, error } = await sb().auth.signUp({
      email,
      password: motDePasse,
      options: { data: { role, nom, prenom, telephone, niu } },
    })
    if (error) echouer(error.message, error)

    // Sans session, la RLS refusera le dépôt des pièces : c'est le cas quand
    // la confirmation par email est activée sur le projet Supabase.
    if (!data.session) {
      echouer(
        'Compte créé. Confirmez votre email puis connectez-vous pour ' +
          'transmettre vos pièces justificatives.',
      )
    }

    const uid = data.session.user.id
    await televerser(uid, pieces, null)
    return compteDepuisProfil(uid, email)
  },

  async connexion(email: string, motDePasse: string) {
    const { data, error } = await sb().auth.signInWithPassword({
      email,
      password: motDePasse,
    })
    if (error) echouer(error.message, error)
    return compteDepuisProfil(data.user.id, data.user.email ?? email)
  },

  async deconnexion() {
    const { error } = await sb().auth.signOut()
    if (error) echouer(error.message, error)
  },

  async listerDemandes() {
    const { data, error } = await sb()
      .from('demandes')
      .select('id, service_id, service_label, resume, statut, cree_le, pieces(label, nom_fichier)')
      .order('cree_le', { ascending: false })
    if (error) echouer(error.message)

    return (data ?? []).map(
      (d): Demande => ({
        id: d.id,
        serviceId: d.service_id,
        serviceLabel: d.service_label,
        resume: d.resume,
        statut: d.statut,
        date: dateFr(d.cree_le),
        pieces: (d.pieces ?? []).map((p: { label: string; nom_fichier: string }) => ({
          label: p.label,
          fileName: p.nom_fichier,
        })),
      }),
    )
  },

  async creerDemande({ serviceId, serviceLabel, resume, pieces = [] }: DemandeInput) {
    const uid = await idUtilisateur()

    const { data, error } = await sb()
      .from('demandes')
      .insert({
        user_id: uid,
        service_id: serviceId,
        service_label: serviceLabel,
        resume,
      })
      .select('id, statut, cree_le')
      .single()
    if (error) echouer(error.message)

    // Si un téléversement échoue, la demande existe déjà : l'agent la voit
    // avec ses pièces manquantes plutôt que de la perdre en silence.
    const deposees = await televerser(uid, pieces, data.id)

    return {
      id: data.id,
      serviceId,
      serviceLabel,
      resume,
      pieces: deposees,
      statut: data.statut,
      date: dateFr(data.cree_le),
    }
  },

  async listerMessages() {
    const { data, error } = await sb()
      .from('messages')
      .select('id, auteur, texte, nom_fichier, cree_le')
      .order('cree_le', { ascending: true })
    if (error) echouer(error.message)

    return (data ?? []).map(
      (m): Message => ({
        id: m.id,
        auteur: m.auteur === 'agent' ? 'agent' : 'moi',
        texte: m.texte,
        fichier: m.nom_fichier ?? undefined,
        heure: heureFr(m.cree_le),
      }),
    )
  },

  async envoyerMessage({ texte, fichier }: MessageInput) {
    const uid = await idUtilisateur()

    let chemin: string | null = null
    if (fichier) {
      chemin = `${uid}/chat/${crypto.randomUUID()}-${assainir(fichier.name)}`
      const { error } = await sb().storage
        .from(BUCKET)
        .upload(chemin, fichier, { contentType: fichier.type || undefined })
      if (error) echouer(`Envoi du document impossible : ${error.message}`)
    }

    const { data, error } = await sb()
      .from('messages')
      .insert({
        user_id: uid,
        auteur: 'client',
        texte,
        piece_chemin: chemin,
        nom_fichier: fichier?.name ?? null,
      })
      .select('id, cree_le')
      .single()
    if (error) echouer(error.message)

    return {
      id: data.id,
      auteur: 'moi',
      texte,
      fichier: fichier?.name,
      heure: heureFr(data.cree_le),
    }
  },

  souscrireMessages(onMessage) {
    // La souscription a besoin de l'identifiant : on l'installe dès qu'il est
    // connu, et `annule` couvre le cas d'un démontage avant cet instant.
    let canal: ReturnType<SupabaseClient['channel']> | null = null
    let annule = false

    void (async () => {
      const { data } = await sb().auth.getUser()
      if (!data.user || annule) return

      canal = sb()
        .channel(`messages:${data.user.id}`)
        .on(
          'postgres_changes',
          {
            event: 'INSERT',
            schema: 'public',
            table: 'messages',
            filter: `user_id=eq.${data.user.id}`,
          },
          (charge) => {
            const m = charge.new as {
              id: string
              auteur: string
              texte: string
              nom_fichier: string | null
              cree_le: string
            }
            // Nos propres messages sont déjà affichés par `envoyerMessage`.
            if (m.auteur !== 'agent') return
            onMessage({
              id: m.id,
              auteur: 'agent',
              texte: m.texte,
              fichier: m.nom_fichier ?? undefined,
              heure: heureFr(m.cree_le),
            })
          },
        )
        .subscribe()
    })()

    return () => {
      annule = true
      if (canal) void sb().removeChannel(canal)
    }
  },
}

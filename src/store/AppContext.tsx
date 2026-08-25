import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import { backend, type DemandeInput, type InscriptionInput } from '../api'
import type { Compte, Demande, Message } from './types'

type Etat = {
  compte: Compte | null
  demandes: Demande[]
  messages: Message[]
}

const ETAT_VIDE: Etat = { compte: null, demandes: [], messages: [] }

/**
 * Accueil de la messagerie. Affiché tant que la conversation est vide : ce
 * n'est pas un message stocké, seulement le premier mot du conseiller.
 */
const MESSAGE_ACCUEIL: Message = {
  id: 'bienvenue',
  auteur: 'agent',
  texte:
    "Bonjour 👋 Je suis Judicaël, votre conseiller CAM-TAXE. Dites-moi en quoi je peux vous aider : déclaration, NIU/ACF, DSF, audit ou contentieux fiscal.",
  heure: '09:00',
}

type AppContextValue = Etat & {
  connecte: boolean
  /** Faux tant que la session enregistrée n'a pas été relue au démarrage. */
  pret: boolean
  inscription: (input: InscriptionInput) => Promise<void>
  connexion: (email: string, motDePasse: string) => Promise<void>
  seDeconnecter: () => Promise<void>
  envoyerDemande: (input: DemandeInput) => Promise<Demande>
  envoyerMessage: (texte: string, fichier?: File) => Promise<void>
  toast: string | null
  afficherToast: (texte: string) => void
}

const AppContext = createContext<AppContextValue | null>(null)

export function AppProvider({ children }: { children: ReactNode }) {
  const [etat, setEtat] = useState<Etat>(ETAT_VIDE)
  const [pret, setPret] = useState(false)
  const [toast, setToast] = useState<string | null>(null)

  const afficherToast = useCallback((texte: string) => setToast(texte), [])

  useEffect(() => {
    if (!toast) return
    const t = setTimeout(() => setToast(null), 3600)
    return () => clearTimeout(t)
  }, [toast])

  /** Charge le dossier de l'utilisateur : ses demandes et sa conversation. */
  const charger = useCallback(async (compte: Compte) => {
    const [demandes, messages] = await Promise.all([
      backend.listerDemandes(),
      backend.listerMessages(),
    ])
    setEtat({ compte, demandes, messages })
  }, [])

  // Session déjà ouverte sur cet appareil ?
  useEffect(() => {
    let vivant = true
    void (async () => {
      try {
        const compte = await backend.sessionActuelle()
        if (!vivant) return
        if (compte) await charger(compte)
      } catch {
        // Session illisible ou serveur injoignable : on démarre déconnecté.
      } finally {
        if (vivant) setPret(true)
      }
    })()
    return () => {
      vivant = false
    }
  }, [charger])

  // Réponses des agents, en temps réel.
  useEffect(() => {
    if (!etat.compte) return
    const annuler = backend.souscrireMessages((m) => {
      setEtat((e) =>
        e.messages.some((x) => x.id === m.id) ? e : { ...e, messages: [...e.messages, m] },
      )
    })
    return annuler
  }, [etat.compte])

  const inscription = useCallback(
    async (input: InscriptionInput) => {
      const compte = await backend.inscription(input)
      await charger(compte)
    },
    [charger],
  )

  const connexion = useCallback(
    async (email: string, motDePasse: string) => {
      const compte = await backend.connexion(email, motDePasse)
      await charger(compte)
    },
    [charger],
  )

  const seDeconnecter = useCallback(async () => {
    await backend.deconnexion()
    setEtat(ETAT_VIDE)
  }, [])

  const envoyerDemande = useCallback(async (input: DemandeInput) => {
    const demande = await backend.creerDemande(input)
    setEtat((e) => ({ ...e, demandes: [demande, ...e.demandes] }))
    return demande
  }, [])

  const envoyerMessage = useCallback(async (texte: string, fichier?: File) => {
    const mien = await backend.envoyerMessage({ texte, fichier })
    setEtat((e) => ({ ...e, messages: [...e.messages, mien] }))
  }, [])

  const valeur = useMemo<AppContextValue>(
    () => ({
      ...etat,
      messages: etat.messages.length ? etat.messages : [MESSAGE_ACCUEIL],
      connecte: etat.compte !== null,
      pret,
      inscription,
      connexion,
      seDeconnecter,
      envoyerDemande,
      envoyerMessage,
      toast,
      afficherToast,
    }),
    [
      etat,
      pret,
      inscription,
      connexion,
      seDeconnecter,
      envoyerDemande,
      envoyerMessage,
      toast,
      afficherToast,
    ],
  )

  return <AppContext.Provider value={valeur}>{children}</AppContext.Provider>
}

export function useApp() {
  const ctx = useContext(AppContext)
  if (!ctx) throw new Error('useApp doit être utilisé dans <AppProvider>')
  return ctx
}

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from 'react'
import type { Compte, Demande, Message, Piece } from './types'

const CLE = 'mon-comptable:v1'

type Etat = {
  compte: Compte | null
  demandes: Demande[]
  messages: Message[]
}

const ETAT_VIDE: Etat = { compte: null, demandes: [], messages: [] }

function lire(): Etat {
  try {
    const brut = localStorage.getItem(CLE)
    if (!brut) return ETAT_VIDE
    return { ...ETAT_VIDE, ...(JSON.parse(brut) as Partial<Etat>) }
  } catch {
    return ETAT_VIDE
  }
}

type AppContextValue = Etat & {
  connecte: boolean
  seConnecter: (compte: Compte) => void
  seDeconnecter: () => void
  envoyerDemande: (input: {
    serviceId: string
    serviceLabel: string
    resume: string
    pieces?: Piece[]
  }) => Demande
  envoyerMessage: (texte: string, fichier?: string) => void
  toast: string | null
  afficherToast: (texte: string) => void
}

const AppContext = createContext<AppContextValue | null>(null)

const MESSAGE_ACCUEIL: Message = {
  id: 'bienvenue',
  auteur: 'agent',
  texte:
    "Bonjour 👋 Je suis Judicaël, votre conseiller CAM-TAXE. Dites-moi en quoi je peux vous aider : déclaration, NIU/ACF, DSF, audit ou contentieux fiscal.",
  heure: '09:00',
}

function maintenantHeure() {
  return new Date().toLocaleTimeString('fr-FR', {
    hour: '2-digit',
    minute: '2-digit',
  })
}

function identifiant() {
  return `${Date.now()}-${Math.random().toString(16).slice(2, 8)}`
}

export function AppProvider({ children }: { children: ReactNode }) {
  const [etat, setEtat] = useState<Etat>(() => {
    const initial = lire()
    if (initial.messages.length === 0) initial.messages = [MESSAGE_ACCUEIL]
    return initial
  })
  const [toast, setToast] = useState<string | null>(null)

  useEffect(() => {
    localStorage.setItem(CLE, JSON.stringify(etat))
  }, [etat])

  useEffect(() => {
    if (!toast) return
    const t = setTimeout(() => setToast(null), 3600)
    return () => clearTimeout(t)
  }, [toast])

  const afficherToast = useCallback((texte: string) => setToast(texte), [])

  const seConnecter = useCallback((compte: Compte) => {
    setEtat((e) => ({ ...e, compte }))
  }, [])

  const seDeconnecter = useCallback(() => {
    setEtat((e) => ({ ...e, compte: null }))
  }, [])

  const envoyerDemande: AppContextValue['envoyerDemande'] = useCallback(
    ({ serviceId, serviceLabel, resume, pieces = [] }) => {
      const demande: Demande = {
        id: identifiant(),
        serviceId,
        serviceLabel,
        resume,
        pieces,
        statut: 'Envoyée',
        date: new Date().toLocaleDateString('fr-FR', {
          day: '2-digit',
          month: '2-digit',
          year: 'numeric',
        }),
      }
      setEtat((e) => ({ ...e, demandes: [demande, ...e.demandes] }))
      return demande
    },
    [],
  )

  const envoyerMessage = useCallback((texte: string, fichier?: string) => {
    const mien: Message = {
      id: identifiant(),
      auteur: 'moi',
      texte,
      fichier,
      heure: maintenantHeure(),
    }
    setEtat((e) => ({ ...e, messages: [...e.messages, mien] }))

    // Réponse simulée de l'agent — le back-office sera branché plus tard.
    setTimeout(() => {
      const reponse: Message = {
        id: identifiant(),
        auteur: 'agent',
        texte:
          'Bien reçu, je consulte votre dossier et je reviens vers vous dans quelques instants.',
        heure: maintenantHeure(),
      }
      setEtat((e) => ({ ...e, messages: [...e.messages, reponse] }))
    }, 1100)
  }, [])

  const valeur = useMemo<AppContextValue>(
    () => ({
      ...etat,
      connecte: etat.compte !== null,
      seConnecter,
      seDeconnecter,
      envoyerDemande,
      envoyerMessage,
      toast,
      afficherToast,
    }),
    [etat, seConnecter, seDeconnecter, envoyerDemande, envoyerMessage, toast, afficherToast],
  )

  return <AppContext.Provider value={valeur}>{children}</AppContext.Provider>
}

export function useApp() {
  const ctx = useContext(AppContext)
  if (!ctx) throw new Error('useApp doit être utilisé dans <AppProvider>')
  return ctx
}

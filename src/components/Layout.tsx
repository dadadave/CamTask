import type { ReactNode } from 'react'
import { Navigate, useLocation } from 'react-router-dom'
import { BottomNav } from './BottomNav'
import { useApp } from '../store/AppContext'

/**
 * Coquille commune : cadre téléphone, zone défilante et navigation basse.
 */
export function Ecran({
  children,
  nav = true,
  flush = false,
}: {
  children: ReactNode
  nav?: boolean
  flush?: boolean
}) {
  return (
    <>
      <div className={flush ? 'screen screen--flush' : 'screen'}>{children}</div>
      {nav && <BottomNav />}
    </>
  )
}

/**
 * Un compte est requis pour accéder aux services : on redirige vers
 * l'inscription en gardant la page demandée en mémoire.
 */
export function RequiertCompte({ children }: { children: ReactNode }) {
  const { connecte, pret } = useApp()
  const location = useLocation()

  // Tant que la session enregistrée n'a pas été relue, on ne sait pas encore
  // si l'utilisateur est connecté : le renvoyer vers /auth le déconnecterait
  // visuellement à chaque rechargement de page.
  if (!pret) {
    return (
      <Ecran nav={false}>
        <p className="empty">Chargement…</p>
      </Ecran>
    )
  }

  if (!connecte) {
    return <Navigate to="/auth" replace state={{ from: location.pathname }} />
  }
  return <>{children}</>
}

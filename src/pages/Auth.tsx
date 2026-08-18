import { useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { ArtTax } from '../components/icons'
import { Field, Upload, useUploads } from '../components/ui'
import { useApp } from '../store/AppContext'
import type { Role } from '../store/types'

type Onglet = 'in' | 'up'

/** Pièces exigées à l'inscription, selon le profil. */
const PIECES_UTILISATEUR = [
  'Photo de la CNI',
  "Numéro d'identifiant unique (NIU) — justificatif",
]

const PIECES_EMPLOYE = [
  'CNI',
  'Plan de localisation',
  "Carte / attestation de numéro de contribuable",
  "CNI d'un garant qui se porte caution",
]

export function Auth() {
  const navigate = useNavigate()
  const location = useLocation()
  const { seConnecter, afficherToast } = useApp()
  const retour = (location.state as { from?: string } | null)?.from ?? '/accueil'

  const [onglet, setOnglet] = useState<Onglet>('in')
  const [role, setRole] = useState<Role>('utilisateur')
  const [erreur, setErreur] = useState('')

  const [nom, setNom] = useState('')
  const [prenom, setPrenom] = useState('')
  const [email, setEmail] = useState('')
  const [telephone, setTelephone] = useState('')
  const [niu, setNiu] = useState('')
  const [motDePasse, setMotDePasse] = useState('')

  const { fichiers, definir, pieces } = useUploads()
  const piecesRequises = role === 'utilisateur' ? PIECES_UTILISATEUR : PIECES_EMPLOYE

  function connexion() {
    if (!email.trim() || !motDePasse.trim()) {
      setErreur('Renseignez votre email et votre mot de passe.')
      return
    }
    seConnecter({
      role: 'utilisateur',
      nom: nom || email.split('@')[0],
      prenom,
      email,
      telephone,
      niu,
      pieces: [],
      creeLe: new Date().toLocaleDateString('fr-FR'),
    })
    afficherToast('Bienvenue sur CAM-TAXE.')
    navigate(retour, { replace: true })
  }

  function inscription() {
    const manquants: string[] = []
    if (role === 'utilisateur') {
      if (!nom.trim()) manquants.push('Nom')
      if (!prenom.trim()) manquants.push('Prénom')
    }
    if (!email.trim()) manquants.push('Email')
    if (!telephone.trim()) manquants.push('Numéro de téléphone')
    if (!niu.trim())
      manquants.push(
        role === 'utilisateur' ? "Numéro d'identifiant unique" : 'Numéro de contribuable',
      )
    if (!motDePasse.trim() && role === 'utilisateur') manquants.push('Mot de passe')

    const docsManquants = piecesRequises.filter((p) => !fichiers[p])
    if (manquants.length || docsManquants.length) {
      setErreur(
        `À compléter : ${[...manquants, ...docsManquants].join(', ')}.`,
      )
      return
    }

    seConnecter({
      role,
      nom,
      prenom,
      email,
      telephone,
      niu,
      pieces,
      creeLe: new Date().toLocaleDateString('fr-FR'),
    })
    afficherToast('Compte créé. Vous pouvez maintenant utiliser nos services.')
    navigate(retour, { replace: true })
  }

  return (
    <div className="auth">
      <div className="auth__art">
        <ArtTax />
      </div>

      <div className="auth__card">
        <div className="auth__tabs">
          <button
            className={onglet === 'in' ? 'auth__tab auth__tab--on' : 'auth__tab'}
            onClick={() => {
              setOnglet('in')
              setErreur('')
            }}
          >
            sign in
          </button>
          <button
            className={onglet === 'up' ? 'auth__tab auth__tab--on' : 'auth__tab'}
            onClick={() => {
              setOnglet('up')
              setErreur('')
            }}
          >
            sign up
          </button>
        </div>

        {onglet === 'in' ? (
          <>
            <div className="auth__fields">
              <Field label="Email" type="email" value={email} onChange={setEmail} />
              <Field
                label="mot de passe"
                type="password"
                value={motDePasse}
                onChange={setMotDePasse}
              />
            </div>
            {erreur && <p className="field__error">{erreur}</p>}
            <button className="auth__submit" onClick={connexion}>
              sign in
            </button>
          </>
        ) : (
          <>
            <div className="auth__roles">
              <button
                className={
                  role === 'utilisateur' ? 'auth__role auth__role--on' : 'auth__role'
                }
                onClick={() => setRole('utilisateur')}
              >
                Utilisateur
              </button>
              <button
                className={role === 'employe' ? 'auth__role auth__role--on' : 'auth__role'}
                onClick={() => setRole('employe')}
              >
                Personne employée
              </button>
            </div>

            <div className="auth__fields">
              {role === 'utilisateur' && (
                <>
                  <Field label="Nom" value={nom} onChange={setNom} />
                  <Field label="Prénom" value={prenom} onChange={setPrenom} />
                </>
              )}
              {role === 'employe' && <Field label="Nom et prénom" value={nom} onChange={setNom} />}
              <Field label="Email" type="email" value={email} onChange={setEmail} />
              <Field
                label="Numéro de téléphone"
                type="tel"
                value={telephone}
                onChange={setTelephone}
              />
              <Field
                label={
                  role === 'utilisateur'
                    ? "Numéro d'identifiant unique (NIU)"
                    : 'Numéro de contribuable'
                }
                value={niu}
                onChange={setNiu}
              />
              {role === 'utilisateur' && (
                <Field
                  label="mot de passe"
                  type="password"
                  value={motDePasse}
                  onChange={setMotDePasse}
                />
              )}
            </div>

            <div className="auth__docs">
              <span className="auth__docstitle">Pièces à fournir</span>
              {piecesRequises.map((p) => (
                <Upload
                  key={p}
                  label={p}
                  fileName={fichiers[p]}
                  onPick={(n) => definir(p, n)}
                />
              ))}
            </div>

            {erreur && <p className="field__error">{erreur}</p>}
            <button className="auth__submit" onClick={inscription}>
              sign up
            </button>
          </>
        )}

        <p className="auth__switch">
          Il faut au préalable créer un compte pour bénéficier de nos services.
        </p>
      </div>
    </div>
  )
}

import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Ecran } from '../components/Layout'
import {
  BoutonEnvoyer,
  DiscuterAgent,
  Field,
  ServiceHead,
  TextArea,
  TopBar,
  Upload,
  useUploads,
} from '../components/ui'
import { useApp } from '../store/AppContext'

/** Pièces justificatives que l'utilisateur peut joindre à son contentieux. */
const PIECES = [
  'Pièce justificative 1',
  'Pièce justificative 2',
  'Pièce justificative 3',
]

export function Contentieux() {
  const navigate = useNavigate()
  const { envoyerDemande, afficherToast } = useApp()
  const { fichiers, definir, pieces } = useUploads()

  const [niu, setNiu] = useState('')
  const [prejudice, setPrejudice] = useState('')
  const [erreur, setErreur] = useState('')

  function envoyer() {
    if (!prejudice.trim()) {
      setErreur('Décrivez la nature du préjudice subi.')
      return
    }
    envoyerDemande({
      serviceId: 'contentieux',
      serviceLabel: 'Contentieux fiscal',
      resume: `${niu ? `NIU ${niu} — ` : ''}Préjudice : ${prejudice.trim()}`,
      pieces,
    })
    afficherToast('Votre contentieux a été transmis à un conseiller.')
    navigate('/profil')
  }

  return (
    <>
      <TopBar titre="Contentieux fiscal" />
      <Ecran>
        <ServiceHead label="Contentieux fiscal" />

        <div className="notice">
          Présentez les pièces justificatives qui, selon vous, méritent que vous vous
          retrouviez au-devant des procédures contentieuses fiscales.
        </div>

        <div className="form">
          <Field label="NIU (facultatif)" value={niu} onChange={setNiu} />

          <div className="field">
            <span className="label" style={{ color: 'var(--blue-strong)' }}>
              Quelle est la nature du préjudice subi ?
            </span>
            <div style={{ height: 10 }} />
            <TextArea
              label="Décrivez votre préjudice…"
              value={prejudice}
              onChange={(v) => {
                setPrejudice(v)
                setErreur('')
              }}
              rows={6}
            />
          </div>

          <div className="field">
            <span className="label">Joindre vos documents</span>
            <div style={{ height: 10 }} />
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {PIECES.map((p) => (
                <Upload key={p} label={p} fileName={fichiers[p]} onPick={(n) => definir(p, n)} />
              ))}
            </div>
          </div>

          {erreur && <p className="field__error">{erreur}</p>}
          <BoutonEnvoyer onClick={envoyer} />
        </div>

        <DiscuterAgent sujet="Contentieux fiscal" />
      </Ecran>
    </>
  )
}

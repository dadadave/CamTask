import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Ecran } from '../components/Layout'
import {
  BoutonEnvoyer,
  Chips,
  DiscuterAgent,
  Field,
  ServiceHead,
  TextArea,
  TopBar,
  Upload,
  useUploads,
} from '../components/ui'
import { DESTINATIONS_DSF, SECTIONS_DSF } from '../data/dsf'
import { useApp } from '../store/AppContext'

export function Dsf() {
  const navigate = useNavigate()
  const { envoyerDemande, afficherToast } = useApp()
  const { fichiers, definir, pieces } = useUploads()

  const [niu, setNiu] = useState('')
  const [destination, setDestination] = useState('')
  const [entreprise, setEntreprise] = useState('')
  const [erreur, setErreur] = useState('')

  function envoyer() {
    const manquants = [
      !niu.trim() && 'NIU',
      !destination && 'DSF pour impôt ou pour la banque',
      !entreprise.trim() && "Type d'entreprise et nature de vos activités",
    ].filter(Boolean) as string[]

    if (manquants.length) {
      setErreur(`À compléter : ${manquants.join(', ')}.`)
      return
    }

    envoyerDemande({
      serviceId: 'dsf',
      serviceLabel: 'DSF — Déclaration statistique et fiscale',
      resume: `NIU ${niu} — ${destination} — ${entreprise}`,
      pieces,
    })
    afficherToast(`DSF transmise (${pieces.length} pièce(s) jointe(s)).`)
    navigate('/profil')
  }

  return (
    <>
      <TopBar titre="DSF" />
      <Ecran>
        <ServiceHead label="DSF" sub="Déclaration statistique et fiscale" />

        <div className="form">
          <Field label="NIU" value={niu} onChange={setNiu} />

          <div className="field">
            <span className="label">DSF pour impôt ou DSF pour la banque ?</span>
            <div style={{ height: 8 }} />
            <Chips
              options={DESTINATIONS_DSF}
              valeurs={destination ? [destination] : []}
              onToggle={(v) => {
                setDestination((d) => (d === v ? '' : v))
                setErreur('')
              }}
              wide
            />
          </div>

          <TextArea
            label="Type d'entreprise et nature de vos activités"
            value={entreprise}
            onChange={setEntreprise}
            rows={3}
          />
        </div>

        <p className="audit__hint" style={{ marginTop: 22 }}>
          Télécharger les documents en un seul PDF dans chacune des sections.
        </p>

        {SECTIONS_DSF.map((section) => (
          <div key={section.id} className="audit__section">
            <h3 className="panel__title">{section.titre}</h3>
            {section.documents.map((doc) => (
              <Upload
                key={doc}
                label={doc}
                fileName={fichiers[doc]}
                onPick={(n) => definir(doc, n)}
              />
            ))}
          </div>
        ))}

        <div className="form">
          {erreur && <p className="field__error">{erreur}</p>}
          <BoutonEnvoyer onClick={envoyer} />
        </div>

        <DiscuterAgent sujet="DSF" />
      </Ecran>
    </>
  )
}

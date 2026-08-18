import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Ecran } from '../components/Layout'
import {
  BoutonEnvoyer,
  Chips,
  DiscuterAgent,
  Field,
  Select,
  ServiceHead,
  TopBar,
  Upload,
  useUploads,
} from '../components/ui'
import {
  AUDIT_CONSIGNE,
  AUDIT_PRESENTATION,
  SECTIONS_AUDIT,
  TYPES_AUDIT,
} from '../data/audit'
import { useApp } from '../store/AppContext'

const OPERATEURS = ['MTN Mobile Money', 'Orange Money', 'Virement bancaire'] as const

export function Audit() {
  const navigate = useNavigate()
  const { envoyerDemande, afficherToast } = useApp()
  const { fichiers, definir, pieces } = useUploads()

  const [structure, setStructure] = useState('')
  const [type, setType] = useState('')
  const [niu, setNiu] = useState('')
  const [erreur, setErreur] = useState('')

  // Paiement de la caution
  const [paiementOuvert, setPaiementOuvert] = useState(false)
  const [operateur, setOperateur] = useState('')
  const [telephone, setTelephone] = useState('')
  const [cautionPayee, setCautionPayee] = useState(false)

  function payerCaution() {
    if (!operateur || !telephone.trim()) {
      setErreur('Choisissez un moyen de paiement et saisissez le numéro à débiter.')
      return
    }
    setCautionPayee(true)
    setPaiementOuvert(false)
    setErreur('')
    afficherToast(`Caution enregistrée via ${operateur}.`)
  }

  function envoyer() {
    const manquants = [
      !structure.trim() && 'Nom de la structure',
      !type && "Type d'audit",
      !niu.trim() && 'NIU',
      !cautionPayee && 'Paiement de caution',
    ].filter(Boolean) as string[]

    if (manquants.length) {
      setErreur(`À compléter : ${manquants.join(', ')}.`)
      return
    }

    envoyerDemande({
      serviceId: 'audit',
      serviceLabel: 'Faire un audit',
      resume: `${type} — ${structure} — NIU ${niu} — caution réglée (${operateur})`,
      pieces,
    })
    afficherToast(`Demande d'audit envoyée (${pieces.length} document(s)).`)
    navigate('/profil')
  }

  return (
    <>
      <TopBar titre="Faire un audit" />
      <Ecran>
        <ServiceHead label="Faire un audit" />

        <div className="form">
          <Field label="Nom de la structure" value={structure} onChange={setStructure} />
          <Select
            label="Type d'audit"
            value={type}
            onChange={setType}
            options={TYPES_AUDIT}
            boxed
          />
          <Field label="NIU" value={niu} onChange={setNiu} boxed />

          <button
            className={cautionPayee ? 'btn btn--caution upload--done' : 'btn btn--caution'}
            onClick={() => setPaiementOuvert((o) => !o)}
          >
            {cautionPayee ? '✓ Caution payée' : 'Paiement de caution'}
          </button>

          {paiementOuvert && !cautionPayee && (
            <div className="audit__section" style={{ margin: 0 }}>
              <span className="label">Moyen de paiement</span>
              <Chips
                options={OPERATEURS}
                valeurs={operateur ? [operateur] : []}
                onToggle={(v) => setOperateur((o) => (o === v ? '' : v))}
                wide
              />
              <Field
                label="Numéro à débiter"
                type="tel"
                value={telephone}
                onChange={setTelephone}
              />
              <BoutonEnvoyer onClick={payerCaution} libelle="Valider le paiement" bloc />
            </div>
          )}
        </div>

        {/* Présentation des types d'audit et des pièces à fournir */}
        <div className="notice" style={{ marginTop: 22 }}>
          {AUDIT_PRESENTATION.map((t) => (
            <p key={t} className="panel__text" style={{ marginBottom: 8 }}>
              {t}
            </p>
          ))}
        </div>

        <p className="audit__hint">{AUDIT_CONSIGNE}</p>

        {SECTIONS_AUDIT.map((section) => (
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

        <DiscuterAgent sujet="Faire un audit" />
      </Ecran>
    </>
  )
}

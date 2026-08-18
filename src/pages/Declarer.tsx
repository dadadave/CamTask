import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Ecran } from '../components/Layout'
import {
  BoutonEnvoyer,
  DiscuterAgent,
  Field,
  Select,
  ServiceHead,
  TopBar,
  Upload,
  useUploads,
} from '../components/ui'
import { useApp } from '../store/AppContext'

const TYPES_IMPOTS = [
  'IRPP — Impôt sur le revenu des personnes physiques',
  'IS — Impôt sur les sociétés',
  'TVA — Taxe sur la valeur ajoutée',
  'Patente',
  'Licence',
  'Précompte sur achats',
  "Droit d'accises",
  'Taxe foncière',
  'Acompte mensuel IR',
  'TSR — Taxe spéciale sur le revenu',
  'Autre impôt ou taxe',
]

const PIECES = [
  "Facture d'achats",
  'Liste des déclarations déjà effectuées',
]

export function Declarer() {
  const navigate = useNavigate()
  const { envoyerDemande, afficherToast } = useApp()
  const { fichiers, definir, pieces } = useUploads()

  const [niu, setNiu] = useState('')
  const [type, setType] = useState('')
  const [montant, setMontant] = useState('')
  const [nature, setNature] = useState('')
  const [erreur, setErreur] = useState('')

  function envoyer() {
    const manquants = [
      !niu.trim() && 'NIU',
      !type && "Type d'impôts",
      !montant.trim() && 'Montant',
      !nature.trim() && "Nature de l'activité",
    ].filter(Boolean) as string[]

    if (manquants.length) {
      setErreur(`À compléter : ${manquants.join(', ')}.`)
      return
    }

    envoyerDemande({
      serviceId: 'declarer',
      serviceLabel: 'Declarer et payer vos impots',
      resume: `NIU ${niu} — ${type} — ${montant} FCFA — Activité : ${nature}`,
      pieces,
    })
    afficherToast('Déclaration transmise. Un agent valide le montant à payer.')
    navigate('/profil')
  }

  return (
    <>
      <TopBar titre="Déclarer et payer" />
      <Ecran>
        <ServiceHead label="Declarer et payer vos impots" />

        <div className="form">
          <Field label="NIU" value={niu} onChange={setNiu} />
          <Select
            label="Type d'impôts"
            value={type}
            onChange={setType}
            options={TYPES_IMPOTS}
          />
          <Field
            label="Montants"
            type="number"
            value={montant}
            onChange={setMontant}
            hint="Montant en FCFA"
          />
          <Field label="Nature de l'activité" value={nature} onChange={setNature} />

          {PIECES.map((p) => (
            <Upload key={p} label={p} fileName={fichiers[p]} onPick={(n) => definir(p, n)} />
          ))}

          {erreur && <p className="field__error">{erreur}</p>}
          <BoutonEnvoyer onClick={envoyer} />
        </div>

        <DiscuterAgent sujet="Declarer et payer vos impots" />
      </Ecran>
    </>
  )
}

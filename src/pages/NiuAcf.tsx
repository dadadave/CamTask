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
import { useApp } from '../store/AppContext'

/** L'utilisateur choisit le NIU, l'ACF, ou les deux. */
const DEMARCHES = ['NIU', 'ACF'] as const

const TYPES_NIU = [
  'NIU pour personne physique',
  'NIU pour personne morale',
] as const

const ACTIVITES = [
  'Salarié',
  'Commerçant',
  'Profession libérale',
  'Artisan',
  'Agriculteur / éleveur',
  'Transporteur',
  'Prestataire de services',
  'Société / entreprise',
  'Étudiant / sans emploi',
  'Autre activité',
]

/** L'ACF va de pair avec l'attestation d'immatriculation. */
const ATTESTATIONS = [
  'ACF — Attestation de conformité fiscale',
  "Attestation d'immatriculation",
] as const

export function NiuAcf() {
  const navigate = useNavigate()
  const { envoyerDemande, afficherToast } = useApp()
  const { fichiers, definir, pieces } = useUploads()

  const [demarches, setDemarches] = useState<string[]>([])
  const [erreur, setErreur] = useState('')

  // Bloc NIU
  const [telephone, setTelephone] = useState('')
  const [activite, setActivite] = useState('')
  const [typeNiu, setTypeNiu] = useState('')

  // Bloc ACF / attestation d'immatriculation
  const [niu, setNiu] = useState('')
  const [attestations, setAttestations] = useState<string[]>([])

  const veutNiu = demarches.includes('NIU')
  const veutAcf = demarches.includes('ACF')

  function basculer(v: string) {
    setDemarches((d) => (d.includes(v) ? d.filter((x) => x !== v) : [...d, v]))
    setErreur('')
  }

  function envoyer() {
    if (demarches.length === 0) {
      setErreur('Choisissez le NIU, l’ACF, ou les deux.')
      return
    }

    const manquants: string[] = []
    if (veutNiu) {
      if (!telephone.trim()) manquants.push('Numéro de téléphone')
      if (!activite) manquants.push("Type d'activité professionnelle")
      if (!typeNiu) manquants.push('Type de NIU')
      if (!fichiers['Importer votre CNI']) manquants.push('CNI')
    }
    if (veutAcf) {
      if (!niu.trim()) manquants.push('NIU (pour l’ACF)')
      if (attestations.length === 0) manquants.push('Document souhaité')
    }

    if (manquants.length) {
      setErreur(`À compléter : ${manquants.join(', ')}.`)
      return
    }

    const resume = [
      veutNiu ? `NIU : ${typeNiu}, activité ${activite}, tél. ${telephone}` : '',
      veutAcf ? `${attestations.join(' + ')} — NIU ${niu}` : '',
    ]
      .filter(Boolean)
      .join('\n')

    envoyerDemande({
      serviceId: 'niu-acf',
      serviceLabel: `Acquérir son ${demarches.join(' / ')}`,
      resume,
      pieces,
    })
    afficherToast('Demande envoyée. Un agent traite votre dossier.')
    navigate('/profil')
  }

  return (
    <>
      <TopBar titre="NIU / ACF" />
      <Ecran>
        <ServiceHead label="Acquérir son NIU / ACF" />

        <div className="form">
          <div className="field">
            <span className="label">Que souhaitez-vous faire ? (NIU, ACF ou les deux)</span>
            <div style={{ height: 10 }} />
            <Chips options={DEMARCHES} valeurs={demarches} onToggle={basculer} wide />
          </div>
        </div>

        {veutNiu && (
          <div className="audit__section" style={{ marginTop: 20 }}>
            <h3 className="panel__title">Acquérir son NIU</h3>

            <Field
              label="Numéro de téléphone"
              type="tel"
              value={telephone}
              onChange={setTelephone}
            />
            <Select
              label="Type d'activité professionnelle"
              value={activite}
              onChange={setActivite}
              options={ACTIVITES}
            />
            <Select
              label="Type de NIU"
              value={typeNiu}
              onChange={setTypeNiu}
              options={TYPES_NIU}
              boxed
            />
            <Upload
              label="Importer votre CNI"
              fileName={fichiers['Importer votre CNI']}
              onPick={(n) => definir('Importer votre CNI', n)}
            />
          </div>
        )}

        {veutAcf && (
          <div className="audit__section" style={{ marginTop: veutNiu ? 0 : 20 }}>
            <h3 className="panel__title">ACF / Attestation d'immatriculation</h3>

            <Field label="NIU" value={niu} onChange={setNiu} />

            <span className="label">Document souhaité</span>
            <Chips
              options={ATTESTATIONS}
              valeurs={attestations}
              onToggle={(v) =>
                setAttestations((a) =>
                  a.includes(v) ? a.filter((x) => x !== v) : [...a, v],
                )
              }
              wide
            />
          </div>
        )}

        <div className="form" style={{ marginTop: 16 }}>
          {erreur && <p className="field__error">{erreur}</p>}
          <BoutonEnvoyer onClick={envoyer} />
        </div>

        <DiscuterAgent sujet="Acquérir son NIU / ACF" />
      </Ecran>
    </>
  )
}

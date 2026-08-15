import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Ecran } from '../components/Layout'
import {
  BoutonEnvoyer,
  DiscuterAgent,
  Field,
  ServiceHead,
  TopBar,
  Upload,
  useUploads,
} from '../components/ui'
import { useApp } from '../store/AppContext'

const PIECES = [
  'Bulletin annuel',
  'Liste de tous les biens meubles ou non',
]

export function Darp() {
  const navigate = useNavigate()
  const { envoyerDemande, afficherToast } = useApp()
  const { fichiers, definir, pieces } = useUploads()

  const [niu, setNiu] = useState('')
  const [erreur, setErreur] = useState('')

  function envoyer() {
    const manquants = [
      !niu.trim() && 'NIU ou numéro de contribuable',
      ...PIECES.filter((p) => !fichiers[p]),
    ].filter(Boolean) as string[]

    if (manquants.length) {
      setErreur(`À compléter : ${manquants.join(', ')}.`)
      return
    }

    envoyerDemande({
      serviceId: 'darp',
      serviceLabel: 'DARP/IRPP',
      resume: `Déclaration annuelle des revenus des particuliers — NIU ${niu}`,
      pieces,
    })
    afficherToast('DARP/IRPP transmise à nos services.')
    navigate('/profil')
  }

  return (
    <>
      <TopBar titre="DARP/IRPP" />
      <Ecran>
        <ServiceHead
          label="DARP/IRPP"
          sub="Déclaration annuelle des revenus des particuliers"
        />

        <div className="form">
          <Field
            label="NIU ou numéro de contribuable"
            value={niu}
            onChange={setNiu}
          />

          {PIECES.map((p) => (
            <Upload key={p} label={p} fileName={fichiers[p]} onPick={(n) => definir(p, n)} />
          ))}

          {erreur && <p className="field__error">{erreur}</p>}
          <BoutonEnvoyer onClick={envoyer} />
        </div>

        <DiscuterAgent sujet="DARP/IRPP" />
      </Ecran>
    </>
  )
}

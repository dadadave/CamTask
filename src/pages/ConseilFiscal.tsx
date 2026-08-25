import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Ecran } from '../components/Layout'
import { BoutonEnvoyer, DiscuterAgent, ServiceHead, TextArea, TopBar } from '../components/ui'
import { IconChevron } from '../components/icons'
import {
  CONSEIL_ACCROCHE,
  CONSEIL_CLOTURE,
  CONSEIL_INTRO,
  QUESTIONS_CONSEIL,
} from '../data/conseil'
import { messageErreur } from '../api'
import { useApp } from '../store/AppContext'

export function ConseilFiscal() {
  const navigate = useNavigate()
  const { envoyerDemande, afficherToast } = useApp()

  const [ouverte, setOuverte] = useState<string | null>(null)
  const [choix, setChoix] = useState<string[]>([])
  const [autreOuvert, setAutreOuvert] = useState(false)
  const [message, setMessage] = useState('')
  const [erreur, setErreur] = useState('')

  function basculerSous(id: string) {
    setChoix((c) => (c.includes(id) ? c.filter((x) => x !== id) : [...c, id]))
    setErreur('')
  }

  function libellesChoisis() {
    return QUESTIONS_CONSEIL.flatMap((q) =>
      q.sousQuestions.filter((s) => choix.includes(s.id)).map((s) => s.titre),
    )
  }

  const [envoi, setEnvoi] = useState(false)

  async function envoyer() {
    const titres = libellesChoisis()
    if (titres.length === 0 && !message.trim()) {
      setErreur('Choisissez au moins une préoccupation ou décrivez la vôtre.')
      return
    }
    setErreur('')
    setEnvoi(true)
    try {
      await envoyerDemande({
        serviceId: 'conseil',
        serviceLabel: 'Besoin de conseil fiscale',
        resume: [
          titres.length ? `Préoccupations : ${titres.join(' • ')}` : '',
          message.trim() ? `Autre préoccupation : ${message.trim()}` : '',
        ]
          .filter(Boolean)
          .join('\n'),
      })
      afficherToast('Votre demande de conseil a été envoyée. Un conseiller vous répond sous peu.')
      navigate('/profil')
    } catch (e) {
      setErreur(messageErreur(e))
    } finally {
      setEnvoi(false)
    }
  }

  return (
    <>
      <TopBar titre="Conseil fiscal" />
      <Ecran>
        <ServiceHead label="Besoin de conseil fiscale" />

        <div className="notice">{CONSEIL_ACCROCHE}</div>

        <div className="panel">
          <p className="panel__text">{CONSEIL_INTRO}</p>
        </div>

        {QUESTIONS_CONSEIL.map((q) => {
          const ouvert = ouverte === q.id
          const nb = q.sousQuestions.filter((s) => choix.includes(s.id)).length
          return (
            <div key={q.id} style={{ margin: '0 14px' }}>
              <button
                className="conseil__q"
                onClick={() => setOuverte(ouvert ? null : q.id)}
                aria-expanded={ouvert}
              >
                <span className="conseil__qlabel">{q.titre}</span>
                {nb > 0 && <span className="conseil__count">{nb}</span>}
                <IconChevron
                  className={
                    ouvert ? 'conseil__chevron conseil__chevron--open' : 'conseil__chevron'
                  }
                />
              </button>

              {ouvert && (
                <div className="conseil__subs">
                  {q.sousQuestions.map((s) => (
                    <button
                      key={s.id}
                      className={
                        choix.includes(s.id) ? 'conseil__sub conseil__sub--on' : 'conseil__sub'
                      }
                      onClick={() => basculerSous(s.id)}
                    >
                      <span className="conseil__bullet" aria-hidden="true" />
                      <span className="conseil__subtext">
                        <b>{s.titre}</b> : {s.detail}
                      </span>
                    </button>
                  ))}
                </div>
              )}
            </div>
          )
        })}

        {/* Autre préoccupation */}
        <div className="panel" style={{ marginTop: 6 }}>
          <h3 className="panel__title">Autre préoccupation</h3>
          {autreOuvert ? (
            <div className="form" style={{ padding: 0, gap: 14 }}>
              <TextArea
                label="message"
                value={message}
                onChange={(v) => {
                  setMessage(v)
                  setErreur('')
                }}
              />
            </div>
          ) : (
            <button className="btn btn--ghost btn--block" onClick={() => setAutreOuvert(true)}>
              Saisir ma préoccupation
            </button>
          )}
        </div>

        {erreur && (
          <p className="field__error" style={{ margin: '0 16px 10px' }}>
            {erreur}
          </p>
        )}

        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 18 }}>
          <BoutonEnvoyer
            onClick={envoyer}
            libelle={envoi ? 'Envoi…' : 'Envoyer'}
            disabled={envoi}
          />
        </div>

        <div className="notice">
          {CONSEIL_CLOTURE.map((t) => (
            <p key={t} className="panel__text" style={{ marginBottom: 8 }}>
              {t}
            </p>
          ))}
        </div>

        <DiscuterAgent sujet="Besoin de conseil fiscale" />
      </Ecran>
    </>
  )
}

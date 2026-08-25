import { useEffect, useRef, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { BottomNav } from '../components/BottomNav'
import {
  IconBack,
  IconCamera,
  IconClip,
  IconDots,
  IconMic,
  IconSmile,
} from '../components/icons'
import { messageErreur } from '../api'
import { useApp } from '../store/AppContext'

export function Chat() {
  const navigate = useNavigate()
  const location = useLocation()
  const sujet = (location.state as { sujet?: string } | null)?.sujet
  const { messages, envoyerMessage, afficherToast } = useApp()

  const [texte, setTexte] = useState(sujet ? `Bonjour, au sujet de « ${sujet} » : ` : '')
  const fin = useRef<HTMLDivElement>(null)
  const fichierRef = useRef<HTMLInputElement>(null)

  useEffect(() => {
    fin.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages.length])

  async function envoyer(t: string, fichier?: File) {
    if (!t && !fichier) return
    setTexte('')
    try {
      await envoyerMessage(t, fichier)
    } catch (e) {
      afficherToast(messageErreur(e))
      // Le message n'est pas parti : on le rend à l'utilisateur.
      if (t) setTexte(t)
    }
  }

  return (
    <>
      <div className="chat">
        <header className="chat__head">
          <button className="topbar__btn" onClick={() => navigate(-1)} aria-label="Retour">
            <IconBack size={22} />
          </button>
          <span className="chat__avatar">J</span>
          <span className="chat__name">judicael</span>
          <button className="topbar__btn" aria-label="Options">
            <IconDots />
          </button>
        </header>

        <div className="chat__body">
          {messages.map((m) => (
            <div
              key={m.id}
              className={
                m.auteur === 'moi' ? 'chat__msg chat__msg--me' : 'chat__msg chat__msg--agent'
              }
            >
              {m.texte}
              {m.fichier && (
                <span className="chat__attachment">
                  <IconClip size={14} /> {m.fichier}
                </span>
              )}
              <span className="chat__time">{m.heure}</span>
            </div>
          ))}
          <div ref={fin} />
        </div>

        <div className="chat__bar">
          <div className="chat__input">
            <span className="chat__icon">
              <IconSmile />
            </span>
            <input
              placeholder="Votre message…"
              value={texte}
              onChange={(e) => setTexte(e.target.value)}
              onKeyDown={(e) => e.key === 'Enter' && void envoyer(texte.trim())}
            />
            <button
              className="chat__icon"
              aria-label="Photo"
              onClick={() => fichierRef.current?.click()}
            >
              <IconCamera />
            </button>
            <button
              className="chat__icon"
              aria-label="Joindre un document"
              onClick={() => fichierRef.current?.click()}
            >
              <IconClip />
            </button>
          </div>
          <button
            className="chat__mic"
            onClick={() => void envoyer(texte.trim())}
            aria-label="Envoyer"
          >
            {texte.trim() ? <IconClip size={20} /> : <IconMic />}
          </button>
        </div>

        <input
          ref={fichierRef}
          className="hidden-input"
          type="file"
          accept="application/pdf,image/*"
          onChange={(e) => {
            const f = e.target.files?.[0]
            if (f) void envoyer(texte.trim() || 'Document joint', f)
            e.target.value = ''
          }}
        />
      </div>
      <BottomNav />
    </>
  )
}

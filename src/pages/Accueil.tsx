import { useMemo, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { Ecran } from '../components/Layout'
import { IconBell, IconSearch, IconUser } from '../components/icons'
import { SERVICES } from '../data/services'
import { useApp } from '../store/AppContext'

export function Accueil() {
  const navigate = useNavigate()
  const { compte } = useApp()
  const [q, setQ] = useState('')

  const resultats = useMemo(() => {
    const terme = q.trim().toLowerCase()
    if (!terme) return SERVICES
    return SERVICES.filter((s) =>
      `${s.label} ${s.sub ?? ''}`.toLowerCase().includes(terme),
    )
  }, [q])

  return (
    <Ecran>
      <div className="home__top">
        <button
          className="home__avatar"
          onClick={() => navigate('/profil')}
          aria-label="Profil"
        >
          <IconUser size={26} />
        </button>
        <button className="home__avatar" aria-label="Notifications">
          <IconBell />
        </button>
      </div>

      <div className="home__search">
        <IconSearch />
        <input
          placeholder="Rechercher un service…"
          value={q}
          onChange={(e) => setQ(e.target.value)}
        />
      </div>

      <div className="home__banner">
        <h2>faites vos declaration chez nous</h2>
        <p>100% sur et rapide</p>
      </div>

      <p className="home__section">
        {compte ? `Bonjour ${compte.prenom || compte.nom}` : 'Nos services'}
      </p>

      <div className="home__grid">
        {resultats.map((s) => (
          <Link key={s.id} to={s.path} className="home__tile">
            <span className="home__tiledot" aria-hidden="true" />
            <span>{s.label}</span>
          </Link>
        ))}
      </div>

      {resultats.length === 0 && (
        <p className="empty">Aucun service ne correspond à « {q} ».</p>
      )}
    </Ecran>
  )
}

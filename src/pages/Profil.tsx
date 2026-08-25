import { useNavigate } from 'react-router-dom'
import { Ecran } from '../components/Layout'
import { TopBar } from '../components/ui'
import { useApp } from '../store/AppContext'

export function Profil() {
  const navigate = useNavigate()
  const { compte, demandes, seDeconnecter } = useApp()

  if (!compte) {
    return (
      <>
        <TopBar titre="Profil" />
        <Ecran>
          <div className="gate">
            <h3>Vous n'êtes pas connecté</h3>
            <p>
              Il faut au préalable créer un compte pour bénéficier de nos services et suivre
              vos demandes.
            </p>
            <button className="btn btn--block" onClick={() => navigate('/auth')}>
              Créer un compte / se connecter
            </button>
          </div>
        </Ecran>
      </>
    )
  }

  const initiales = `${compte.prenom?.[0] ?? ''}${compte.nom?.[0] ?? ''}`.toUpperCase() || 'U'

  return (
    <>
      <TopBar titre="Profil" />
      <Ecran>
        <div className="profil__head">
          <span className="profil__avatar">{initiales}</span>
          <div>
            <div className="profil__name">
              {compte.prenom} {compte.nom}
            </div>
            <div className="profil__meta">
              {compte.role === 'employe' ? 'Personne employée' : 'Utilisateur'} · membre depuis
              le {compte.creeLe}
            </div>
          </div>
        </div>

        <div className="profil__rows">
          <div className="profil__row">
            <span>Email</span>
            <span>{compte.email || '—'}</span>
          </div>
          <div className="profil__row">
            <span>Téléphone</span>
            <span>{compte.telephone || '—'}</span>
          </div>
          <div className="profil__row">
            <span>{compte.role === 'employe' ? 'N° contribuable' : 'NIU'}</span>
            <span>{compte.niu || '—'}</span>
          </div>
          <div className="profil__row">
            <span>Pièces fournies</span>
            <span>{compte.pieces.length}</span>
          </div>
        </div>

        <p className="section-title">Mes demandes ({demandes.length})</p>

        {demandes.length === 0 ? (
          <p className="empty">
            Aucune demande pour l'instant.
            <br />
            Rendez-vous dans « service » pour en créer une.
          </p>
        ) : (
          demandes.map((d) => (
            <div key={d.id} className="demande">
              <div className="demande__top">
                <span className="demande__title">{d.serviceLabel}</span>
                <span className="demande__date">{d.date}</span>
              </div>
              <p className="demande__body">{d.resume}</p>
              {d.pieces.length > 0 && (
                <p className="demande__body">
                  📎 {d.pieces.length} document(s) : {d.pieces.map((p) => p.fileName).join(', ')}
                </p>
              )}
              <span className="badge">{d.statut}</span>
            </div>
          ))
        )}

        <div style={{ padding: '18px 14px 30px' }}>
          <button
            className="btn btn--ghost btn--block"
            onClick={() => {
              void seDeconnecter().then(() => navigate('/auth'))
            }}
          >
            Se déconnecter
          </button>
        </div>
      </Ecran>
    </>
  )
}

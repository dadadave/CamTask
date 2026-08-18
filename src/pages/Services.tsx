import { Link } from 'react-router-dom'
import { Ecran } from '../components/Layout'
import { TopBar } from '../components/ui'
import { IconMenu, IconUser } from '../components/icons'
import { SERVICES } from '../data/services'

export function Services() {
  return (
    <>
      <TopBar
        titre="CAM-TAXE"
        gauche={
          <span className="topbar__btn">
            <IconMenu />
          </span>
        }
        droite={
          <Link to="/profil" className="topbar__btn" aria-label="Profil">
            <IconUser size={22} />
          </Link>
        }
      />
      <Ecran>
        <div className="services">
          {SERVICES.map((s) => (
            <Link key={s.id} to={s.path} className="services__item">
              <span className="services__dot" aria-hidden="true" />
              <span className="services__label">
                {s.label}
                {s.sub && <span className="service-head__sub">{s.sub}</span>}
              </span>
            </Link>
          ))}
        </div>
      </Ecran>
    </>
  )
}

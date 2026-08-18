import { NavLink } from 'react-router-dom'
import { IconChat, IconGrid, IconHome, IconUser } from './icons'

const ITEMS = [
  { to: '/accueil', label: 'Accueil', Icon: IconHome },
  { to: '/services', label: 'service', Icon: IconGrid },
  { to: '/chat', label: 'chat', Icon: IconChat },
  { to: '/profil', label: 'Profil', Icon: IconUser },
]

export function BottomNav() {
  return (
    <nav className="bottomnav">
      {ITEMS.map(({ to, label, Icon }) => (
        <NavLink
          key={to}
          to={to}
          className={({ isActive }) =>
            isActive ? 'bottomnav__item bottomnav__item--on' : 'bottomnav__item'
          }
        >
          <Icon />
          {label}
        </NavLink>
      ))}
    </nav>
  )
}

import { Navigate, Route, Routes } from 'react-router-dom'
import { RequiertCompte } from './components/Layout'
import { useApp } from './store/AppContext'
import { Accueil } from './pages/Accueil'
import { Audit } from './pages/Audit'
import { Auth } from './pages/Auth'
import { Chat } from './pages/Chat'
import { ConseilFiscal } from './pages/ConseilFiscal'
import { Contentieux } from './pages/Contentieux'
import { Darp } from './pages/Darp'
import { Declarer } from './pages/Declarer'
import { Dsf } from './pages/Dsf'
import { NiuAcf } from './pages/NiuAcf'
import { Profil } from './pages/Profil'
import { Services } from './pages/Services'

/** Un service n'est accessible qu'avec un compte. */
function protege(element: JSX.Element) {
  return <RequiertCompte>{element}</RequiertCompte>
}

export default function App() {
  const { toast } = useApp()

  return (
    <div className="phone">
      <Routes>
        <Route path="/" element={<Navigate to="/accueil" replace />} />
        <Route path="/auth" element={<Auth />} />
        <Route path="/accueil" element={<Accueil />} />
        <Route path="/services" element={<Services />} />
        <Route path="/chat" element={<Chat />} />
        <Route path="/profil" element={<Profil />} />

        <Route path="/service/conseil-fiscal" element={protege(<ConseilFiscal />)} />
        <Route path="/service/declarer" element={protege(<Declarer />)} />
        <Route path="/service/darp" element={protege(<Darp />)} />
        <Route path="/service/dsf" element={protege(<Dsf />)} />
        <Route path="/service/contentieux" element={protege(<Contentieux />)} />
        <Route path="/service/niu-acf" element={protege(<NiuAcf />)} />
        <Route path="/service/audit" element={protege(<Audit />)} />

        <Route path="*" element={<Navigate to="/accueil" replace />} />
      </Routes>

      {toast && <div className="toast">{toast}</div>}
    </div>
  )
}

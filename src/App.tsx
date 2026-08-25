import { Navigate, Route, Routes } from 'react-router-dom'
import { backendConfigure } from './api'
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

/**
 * Affiché quand le `.env` n'a pas été renseigné : sans back-end, aucun écran
 * de l'application ne peut fonctionner. Mieux vaut le dire que laisser une
 * page blanche.
 */
function ConfigurationManquante() {
  return (
    <div className="gate">
      <h3>Application non configurée</h3>
      <p>
        Les variables <code>VITE_SUPABASE_URL</code> et{' '}
        <code>VITE_SUPABASE_ANON_KEY</code> sont absentes. Renseignez-les dans le
        fichier <code>.env</code> — ou dans les variables d'environnement de
        l'hébergeur — puis relancez le build.
      </p>
      <p>Le modèle se trouve dans .env.example, à la racine du dépôt.</p>
    </div>
  )
}

export default function App() {
  const { toast } = useApp()

  if (!backendConfigure) {
    return (
      <div className="phone">
        <ConfigurationManquante />
      </div>
    )
  }

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

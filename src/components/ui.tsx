import { useId, useRef, useState, type ReactNode } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArtAgent,
  IconBack,
  IconCheck,
  IconDownload,
} from './icons'

/* -------------------------------------------------------------------------- */
/*  Barre supérieure                                                          */
/* -------------------------------------------------------------------------- */

export function TopBar({
  titre,
  gauche,
  droite,
  plain,
}: {
  titre: string
  gauche?: ReactNode
  droite?: ReactNode
  plain?: boolean
}) {
  const navigate = useNavigate()
  return (
    <header className={plain ? 'topbar topbar--plain' : 'topbar'}>
      {gauche ?? (
        <button className="topbar__btn" onClick={() => navigate(-1)} aria-label="Retour">
          <IconBack />
        </button>
      )}
      <h1 className="topbar__title">{titre}</h1>
      {droite ?? <span className="topbar__btn" aria-hidden="true" />}
    </header>
  )
}

/* -------------------------------------------------------------------------- */
/*  En-tête de service (pastille + libellé, comme sur les maquettes)          */
/* -------------------------------------------------------------------------- */

export function ServiceHead({ label, sub }: { label: string; sub?: string }) {
  return (
    <div className="service-head">
      <span className="service-head__dot" aria-hidden="true" />
      <span className="service-head__label">
        {label}
        {sub && <span className="service-head__sub">{sub}</span>}
      </span>
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/*  Champs                                                                    */
/* -------------------------------------------------------------------------- */

type FieldProps = {
  label: string
  value: string
  onChange: (v: string) => void
  type?: string
  boxed?: boolean
  erreur?: string
  hint?: string
}

export function Field({
  label,
  value,
  onChange,
  type = 'text',
  boxed,
  erreur,
  hint,
}: FieldProps) {
  const id = useId()
  return (
    <div className={boxed ? 'field field--boxed' : 'field'}>
      <label className="hidden-input" htmlFor={id}>
        {label}
      </label>
      <input
        id={id}
        className="field__input"
        type={type}
        placeholder={label}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
      {hint && <span className="field__hint">{hint}</span>}
      {erreur && <span className="field__error">{erreur}</span>}
    </div>
  )
}

export function TextArea({
  label,
  value,
  onChange,
  erreur,
  rows = 5,
}: {
  label: string
  value: string
  onChange: (v: string) => void
  erreur?: string
  rows?: number
}) {
  const id = useId()
  return (
    <div className="field">
      <label className="hidden-input" htmlFor={id}>
        {label}
      </label>
      <textarea
        id={id}
        className="field__textarea"
        placeholder={label}
        rows={rows}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
      {erreur && <span className="field__error">{erreur}</span>}
    </div>
  )
}

export function Select({
  label,
  value,
  onChange,
  options,
  boxed,
  erreur,
}: {
  label: string
  value: string
  onChange: (v: string) => void
  options: readonly string[]
  boxed?: boolean
  erreur?: string
}) {
  const id = useId()
  return (
    <div className={boxed ? 'field field--boxed' : 'field'}>
      <label className="hidden-input" htmlFor={id}>
        {label}
      </label>
      <select
        id={id}
        className="field__select"
        data-empty={value === ''}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      >
        <option value="">{label}</option>
        {options.map((o) => (
          <option key={o} value={o}>
            {o}
          </option>
        ))}
      </select>
      {erreur && <span className="field__error">{erreur}</span>}
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/*  Téléversement                                                             */
/* -------------------------------------------------------------------------- */

export function Upload({
  label,
  fileName,
  onPick,
  accept = 'application/pdf,image/*',
  ghost,
}: {
  label: string
  fileName?: string
  onPick: (name: string) => void
  accept?: string
  ghost?: boolean
}) {
  const ref = useRef<HTMLInputElement>(null)
  const classes = [
    'upload',
    ghost ? 'upload--ghost' : '',
    fileName ? 'upload--done' : '',
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <>
      <button type="button" className={classes} onClick={() => ref.current?.click()}>
        <span className="upload__label">
          {label}
          {fileName && <span className="upload__file">✓ {fileName}</span>}
        </span>
        {fileName ? (
          <IconCheck className="upload__icon" />
        ) : (
          <IconDownload className="upload__icon" />
        )}
      </button>
      <input
        ref={ref}
        className="hidden-input"
        type="file"
        accept={accept}
        onChange={(e) => {
          const f = e.target.files?.[0]
          if (f) onPick(f.name)
          e.target.value = ''
        }}
      />
    </>
  )
}

/** Gère une liste de documents téléversés (label → nom de fichier). */
export function useUploads() {
  const [fichiers, setFichiers] = useState<Record<string, string>>({})
  const definir = (label: string, name: string) =>
    setFichiers((f) => ({ ...f, [label]: name }))
  const pieces = Object.entries(fichiers).map(([label, fileName]) => ({
    label,
    fileName,
  }))
  return { fichiers, definir, pieces }
}

/* -------------------------------------------------------------------------- */
/*  Boutons                                                                   */
/* -------------------------------------------------------------------------- */

export function BoutonEnvoyer({
  onClick,
  libelle = 'Envoyer',
  bloc,
}: {
  onClick: () => void
  libelle?: string
  bloc?: boolean
}) {
  return (
    <button
      type="button"
      className={bloc ? 'btn btn--block' : 'btn btn--send'}
      onClick={onClick}
    >
      {libelle}
    </button>
  )
}

/** Choix simple ou multiple sous forme de pastilles. */
export function Chips({
  options,
  valeurs,
  onToggle,
  wide,
}: {
  options: readonly string[]
  valeurs: string[]
  onToggle: (v: string) => void
  wide?: boolean
}) {
  return (
    <div className="chips">
      {options.map((o) => (
        <button
          key={o}
          type="button"
          className={[
            'chip',
            wide ? 'chip--wide' : '',
            valeurs.includes(o) ? 'chip--on' : '',
          ]
            .filter(Boolean)
            .join(' ')}
          onClick={() => onToggle(o)}
        >
          {o}
        </button>
      ))}
    </div>
  )
}

/* -------------------------------------------------------------------------- */
/*  Bouton flottant « Discuter avec un agent »                                */
/* -------------------------------------------------------------------------- */

export function DiscuterAgent({ sujet }: { sujet?: string }) {
  const navigate = useNavigate()
  return (
    <button
      type="button"
      className="agent"
      onClick={() => navigate('/chat', { state: { sujet } })}
    >
      <span className="agent__avatar">
        <ArtAgent />
      </span>
      <span className="agent__label">Discuter avec un agent</span>
    </button>
  )
}

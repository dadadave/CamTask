type P = { size?: number; className?: string }

const base = (size: number) => ({
  width: size,
  height: size,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 2,
  strokeLinecap: 'round' as const,
  strokeLinejoin: 'round' as const,
})

export const IconDownload = ({ size = 20, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <path d="M12 3v12" />
    <path d="m7 11 5 5 5-5" />
    <path d="M4 20h16" />
  </svg>
)

export const IconUser = ({ size = 24, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <circle cx="12" cy="8" r="4" />
    <path d="M4 21c0-4 3.6-6 8-6s8 2 8 6" />
  </svg>
)

export const IconBell = ({ size = 22, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <path d="M18 8a6 6 0 1 0-12 0c0 6-2 7-2 7h16s-2-1-2-7" />
    <path d="M13.7 20a2 2 0 0 1-3.4 0" />
  </svg>
)

export const IconSearch = ({ size = 18, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <circle cx="11" cy="11" r="7" />
    <path d="m20 20-3.5-3.5" />
  </svg>
)

export const IconMenu = ({ size = 24, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <path d="M4 6h16M4 12h16M4 18h16" />
  </svg>
)

export const IconBack = ({ size = 24, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <path d="m15 5-7 7 7 7" />
  </svg>
)

export const IconChevron = ({ size = 18, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <path d="m9 5 7 7-7 7" />
  </svg>
)

export const IconHome = ({ size = 20, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <path d="m3 10 9-7 9 7v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" />
  </svg>
)

export const IconGrid = ({ size = 20, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <rect x="3" y="3" width="7" height="7" rx="1.5" />
    <rect x="14" y="3" width="7" height="7" rx="1.5" />
    <rect x="3" y="14" width="7" height="7" rx="1.5" />
    <rect x="14" y="14" width="7" height="7" rx="1.5" />
  </svg>
)

export const IconChat = ({ size = 20, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <path d="M21 12a8 8 0 0 1-11.6 7.1L4 20l1-4.5A8 8 0 1 1 21 12z" />
  </svg>
)

export const IconDots = ({ size = 20, className }: P) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor" className={className} aria-hidden="true">
    <circle cx="12" cy="5" r="1.7" />
    <circle cx="12" cy="12" r="1.7" />
    <circle cx="12" cy="19" r="1.7" />
  </svg>
)

export const IconSmile = ({ size = 22, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <circle cx="12" cy="12" r="9" />
    <path d="M8.5 14.5a4.5 4.5 0 0 0 7 0" />
    <path d="M9 9.5h.01M15 9.5h.01" />
  </svg>
)

export const IconCamera = ({ size = 22, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <path d="M3 8.5A1.5 1.5 0 0 1 4.5 7h2L8 5h8l1.5 2h2A1.5 1.5 0 0 1 21 8.5v9A1.5 1.5 0 0 1 19.5 19h-15A1.5 1.5 0 0 1 3 17.5z" />
    <circle cx="12" cy="12.5" r="3.2" />
  </svg>
)

export const IconClip = ({ size = 22, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <path d="M20 11.5 12.5 19a4.6 4.6 0 0 1-6.5-6.5l8-8a3.1 3.1 0 1 1 4.4 4.4l-8 8a1.6 1.6 0 1 1-2.2-2.2l7.2-7.2" />
  </svg>
)

export const IconMic = ({ size = 22, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <rect x="9" y="3" width="6" height="11" rx="3" />
    <path d="M5 11a7 7 0 0 0 14 0" />
    <path d="M12 18v3" />
  </svg>
)

export const IconCheck = ({ size = 18, className }: P) => (
  <svg {...base(size)} className={className} aria-hidden="true">
    <path d="m5 12.5 4.5 4.5L19 7" />
  </svg>
)

/** Illustration « TAX » des écrans de connexion / inscription. */
export const ArtTax = () => (
  <svg viewBox="0 0 300 220" width="100%" height="100%" aria-hidden="true">
    <defs>
      <linearGradient id="mc-paper" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stopColor="#ffffff" />
        <stop offset="100%" stopColor="#e9edf1" />
      </linearGradient>
    </defs>
    <g opacity="0.35" stroke="#b9bfc5" strokeWidth="1">
      {Array.from({ length: 9 }).map((_, i) => (
        <line key={`h${i}`} x1="0" y1={i * 26} x2="300" y2={i * 26} />
      ))}
      {Array.from({ length: 12 }).map((_, i) => (
        <line key={`v${i}`} x1={i * 26} y1="0" x2={i * 26} y2="220" />
      ))}
    </g>

    {/* feuille d'impôt */}
    <g transform="translate(76 18)">
      <rect x="0" y="0" width="118" height="132" rx="4" fill="url(#mc-paper)" stroke="#c7ced4" />
      <text x="46" y="34" fontFamily="Poppins, sans-serif" fontSize="26" fontWeight="700" fill="#2b3a4a">
        TAX
      </text>
      <g stroke="#5b9bd5" strokeWidth="4" strokeLinecap="round">
        <line x1="58" y1="52" x2="104" y2="52" />
        <line x1="58" y1="64" x2="104" y2="64" />
        <line x1="58" y1="76" x2="96" y2="76" />
        <line x1="14" y1="112" x2="104" y2="112" />
        <line x1="14" y1="122" x2="80" y2="122" />
      </g>
      <circle cx="32" cy="70" r="20" fill="#f5f7f9" stroke="#c7ced4" />
      <path d="M32 70 32 50 A20 20 0 0 1 49 79 Z" fill="#5b9bd5" />
      <path d="M32 70 49 79 A20 20 0 0 1 15 82 Z" fill="#f5a623" />
    </g>

    {/* loupe */}
    <g transform="translate(18 20)">
      <circle cx="34" cy="34" r="26" fill="#dff0fb" stroke="#2b3a4a" strokeWidth="6" />
      <circle cx="34" cy="34" r="18" fill="#ffffff" opacity="0.55" />
      <rect x="2" y="52" width="16" height="42" rx="8" transform="rotate(38 10 73)" fill="#2b3a4a" />
    </g>

    {/* réveil */}
    <g transform="translate(24 128)">
      <circle cx="34" cy="34" r="30" fill="#dff0fb" stroke="#3a6ea5" strokeWidth="5" />
      <circle cx="34" cy="34" r="23" fill="#ffffff" />
      <path d="M34 34V19M34 34l11 7" stroke="#2b3a4a" strokeWidth="4" strokeLinecap="round" />
      <path d="M14 6 4 -2M54 6l10-8" stroke="#3a6ea5" strokeWidth="6" strokeLinecap="round" />
    </g>

    {/* billets */}
    <g transform="translate(104 150)">
      <rect x="0" y="14" width="86" height="34" rx="3" fill="#2f9e63" />
      <rect x="0" y="6" width="86" height="34" rx="3" fill="#4cbd7d" />
      <rect x="0" y="-2" width="86" height="34" rx="3" fill="#6fd196" />
      <circle cx="43" cy="15" r="10" fill="#2f9e63" opacity="0.6" />
      <text x="38" y="20" fontFamily="Poppins, sans-serif" fontSize="14" fontWeight="700" fill="#ffffff">
        $
      </text>
    </g>

    {/* pièces */}
    <g transform="translate(206 96)">
      {[0, 10, 20, 30].map((y, i) => (
        <ellipse key={i} cx="34" cy={64 - y} rx="30" ry="11" fill={i % 2 ? '#f0b429' : '#f7c948'} stroke="#d99e0b" />
      ))}
      <circle cx="76" cy="46" r="20" fill="#f7c948" stroke="#d99e0b" strokeWidth="3" />
      <text x="70" y="52" fontFamily="Poppins, sans-serif" fontSize="16" fontWeight="700" fill="#8a6100">
        $
      </text>
    </g>
  </svg>
)

/** Avatar du bouton « Discuter avec un agent ». */
export const ArtAgent = ({ size = 84 }: { size?: number }) => (
  <svg width={size} height={size} viewBox="0 0 100 100" aria-hidden="true">
    <circle cx="50" cy="50" r="50" fill="#f5893f" />
    <circle cx="50" cy="42" r="19" fill="#f7d3b5" />
    <path d="M31 40a19 19 0 0 1 38 0v3h-4V40a15 15 0 0 0-30 0v3h-4z" fill="#5b6bd6" />
    <rect x="26" y="38" width="8" height="14" rx="4" fill="#5b6bd6" />
    <rect x="66" y="38" width="8" height="14" rx="4" fill="#5b6bd6" />
    <path d="M50 22c9 0 16 6 16 14H34c0-8 7-14 16-14z" fill="#3f4a52" />
    <path d="M28 100c2-18 11-28 22-28s20 10 22 28z" fill="#ffffff" />
    <path d="M50 72c4 0 7 3 7 7s-3 21-7 21-7-14-7-21 3-7 7-7z" fill="#e8ecef" />
  </svg>
)

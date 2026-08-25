import { backendSupabase } from './supabase'
import type { Backend } from './types'

/**
 * Point de bascule unique.
 *
 * Supabase nous sert de back-end pour cette première version. Le jour où
 * notre propre API prend le relais, il suffira d'écrire `./rest.ts` qui
 * implémente `Backend`, puis de changer cette seule ligne :
 *
 *     export const backend: Backend = backendRest
 *
 * Aucune page ni le store n'ont à être touchés.
 */
export const backend: Backend = backendSupabase

/**
 * Le backend a-t-il de quoi fonctionner ? Sert à afficher un écran
 * d'explication plutôt qu'une page blanche sur un déploiement mal configuré.
 */
export { supabaseConfigure as backendConfigure } from './supabase'

export * from './types'

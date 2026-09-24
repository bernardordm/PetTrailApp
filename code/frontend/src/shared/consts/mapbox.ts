const DEFAULT_STYLE_LIGHT =
  "mapbox://styles/devmigueldiniz/cmosyokj6001f01s41yiccnxd"
const DEFAULT_STYLE_DARK =
  "mapbox://styles/devmigueldiniz/cmosxavkh001a01s55hujggx9"

/** Token público Mapbox (cliente). */
export const MAPBOX_TOKEN =
  process.env.NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN?.trim() ?? ""

export function mapboxStyleUri(isDark: boolean): string {
  if (isDark) {
    return (
      process.env.NEXT_PUBLIC_MAPBOX_STYLE_URI_DARK?.trim() ||
      DEFAULT_STYLE_DARK
    )
  }
  return (
    process.env.NEXT_PUBLIC_MAPBOX_STYLE_URI_LIGHT?.trim() ||
    DEFAULT_STYLE_LIGHT
  )
}

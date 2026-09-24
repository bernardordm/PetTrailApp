export type LatLng = { lat: number; lng: number }

const MAX_INPUT = 90

function haversineKm(a: LatLng, b: LatLng): number {
  const R = 6371
  const dLat = ((b.lat - a.lat) * Math.PI) / 180
  const dLon = ((b.lng - a.lng) * Math.PI) / 180
  const lat1 = (a.lat * Math.PI) / 180
  const lat2 = (b.lat * Math.PI) / 180
  const x =
    Math.sin(dLat / 2) ** 2 +
    Math.sin(dLon / 2) ** 2 * Math.cos(lat1) * Math.cos(lat2)
  return R * (2 * Math.atan2(Math.sqrt(x), Math.sqrt(1 - x)))
}

function dedupeClose(
  points: LatLng[],
  minSeparationMeters: number,
): LatLng[] {
  if (points.length < 2) return [...points]
  const out: LatLng[] = [points[0]]
  for (let i = 1; i < points.length; i++) {
    const p = points[i]
    const last = out[out.length - 1]
    if (haversineKm(last, p) * 1000 >= minSeparationMeters) out.push(p)
  }
  if (out.length < 2 && points.length >= 2) {
    return [points[0], points[points.length - 1]]
  }
  return out
}

function subsampleToMax(points: LatLng[], maxPoints: number): LatLng[] {
  const cleaned = dedupeClose(points, 4)
  if (cleaned.length <= maxPoints) return cleaned
  const out: LatLng[] = []
  for (let i = 0; i < maxPoints; i++) {
    const t = maxPoints === 1 ? 0 : i / (maxPoints - 1)
    const idx = Math.min(
      cleaned.length - 1,
      Math.max(0, Math.round(t * (cleaned.length - 1))),
    )
    out.push(cleaned[idx])
  }
  return dedupeClose(out, 2)
}

/** Geometria alinhada a calçadas/ruas (Mapbox Map Matching), ou `null` se falhar. */
export async function fetchMapboxWalkingMatchedPath(
  rawPoints: LatLng[],
  mapboxAccessToken: string,
): Promise<LatLng[] | null> {
  if (!mapboxAccessToken || rawPoints.length < 2) return null
  const sampled = subsampleToMax(rawPoints, MAX_INPUT)
  if (sampled.length < 2) return null

  const coordPath = sampled
    .map(
      (p) =>
        `${p.lng.toFixed(6)},${p.lat.toFixed(6)}`,
    )
    .join(";")
  const encodedPath = encodeURIComponent(coordPath)
  const token = encodeURIComponent(mapboxAccessToken)
  const url = `https://api.mapbox.com/matching/v5/mapbox/walking/${encodedPath}?geometries=geojson&overview=full&steps=false&access_token=${token}`

  try {
    const ac = new AbortController()
    const t = setTimeout(() => ac.abort(), 20_000)
    const res = await fetch(url, { signal: ac.signal }).finally(() =>
      clearTimeout(t),
    )
    if (!res.ok) return null
    const body = (await res.json()) as {
      code?: string
      matchings?: Array<{ geometry?: { type?: string; coordinates?: unknown } }>
    }
    if (body.code != null && body.code !== "Ok") return null
    const matchings = body.matchings
    if (!matchings?.length) return null
    const geometry = matchings[0]?.geometry
    if (geometry?.type !== "LineString") return null
    const coords = geometry.coordinates
    if (!Array.isArray(coords) || coords.length < 2) return null

    const out: LatLng[] = []
    for (const c of coords) {
      if (!Array.isArray(c) || c.length < 2) continue
      const lng = Number(c[0])
      const lat = Number(c[1])
      if (Number.isFinite(lat) && Number.isFinite(lng)) out.push({ lat, lng })
    }
    return out.length >= 2 ? out : null
  } catch {
    return null
  }
}

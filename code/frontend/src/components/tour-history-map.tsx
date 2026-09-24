"use client"

import { useTheme } from "next-themes"
import mapboxgl from "mapbox-gl"
import "mapbox-gl/dist/mapbox-gl.css"
import { useEffect, useMemo, useRef, useState } from "react"
import { MAPBOX_TOKEN, mapboxStyleUri } from "@/shared/consts/mapbox"
import {
  fetchMapboxWalkingMatchedPath,
  type LatLng,
} from "@/shared/lib/mapbox-walk-path-snap"

export interface TourHistoryMapProps {
  /** `[lat, lng][]` — mesmo contrato do `WalkMap`. */
  points: [number, number][]
}

function toLatLngs(points: [number, number][]): LatLng[] {
  return points.map(([lat, lng]) => ({ lat, lng }))
}

function markerEl(backgroundColor: string) {
  const wrap = document.createElement("div")
  wrap.style.transform = "translate(-50%, -50%)"
  const dot = document.createElement("div")
  dot.style.width = "14px"
  dot.style.height = "14px"
  dot.style.borderRadius = "9999px"
  dot.style.border = "2px solid #ffffff"
  dot.style.boxShadow = "0 1px 3px rgba(0,0,0,0.25)"
  dot.style.backgroundColor = backgroundColor
  wrap.appendChild(dot)
  return wrap
}

export default function TourHistoryMap({ points }: TourHistoryMapProps) {
  const containerRef = useRef<HTMLDivElement>(null)
  const { resolvedTheme } = useTheme()
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  const pathKey = useMemo(
    () => points.map((p) => `${p[0]},${p[1]}`).join(";"),
    [points],
  )

  useEffect(() => {
    setError(null)
    setLoading(true)

    if (points.length < 2) {
      setLoading(false)
      return
    }

    if (!MAPBOX_TOKEN) {
      setError("Defina NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN no .env do frontend.")
      setLoading(false)
      return
    }

    const container = containerRef.current
    if (!container) return

    mapboxgl.accessToken = MAPBOX_TOKEN
    const isDark = resolvedTheme === "dark"
    const raw = toLatLngs(points)
    const center: [number, number] = [raw[0].lng, raw[0].lat]

    const map = new mapboxgl.Map({
      container,
      style: mapboxStyleUri(isDark),
      center,
      zoom: 14,
      attributionControl: true,
    })

    const markers: mapboxgl.Marker[] = []
    let cancelled = false

    const run = async () => {
      let snapped: LatLng[] | null = null
      try {
        snapped = await fetchMapboxWalkingMatchedPath(raw, MAPBOX_TOKEN)
      } catch {
        snapped = null
      }
      if (cancelled) return

      const line: [number, number][] =
        snapped && snapped.length >= 2
          ? snapped.map((p) => [p.lng, p.lat])
          : raw.map((p) => [p.lng, p.lat])

      const geo = {
        type: "Feature" as const,
        properties: {},
        geometry: {
          type: "LineString" as const,
          coordinates: line,
        },
      }

      try {
        if (!map.getSource("tour-route")) {
          map.addSource("tour-route", { type: "geojson", data: geo })
          map.addLayer({
            id: "tour-route-line",
            type: "line",
            source: "tour-route",
            layout: { "line-join": "round", "line-cap": "round" },
            paint: {
              "line-color": "#22c55e",
              "line-width": 5,
              "line-opacity": 0.95,
            },
          })
        } else {
          const src = map.getSource("tour-route") as mapboxgl.GeoJSONSource
          src.setData(geo)
        }
      } catch (e) {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : "Erro ao desenhar a rota.")
        }
        setLoading(false)
        return
      }

      const start = line[0]
      const end = line[line.length - 1]
      markers.forEach((m) => m.remove())
      markers.length = 0

      markers.push(
        new mapboxgl.Marker({
          element: markerEl("#22c55e"),
          anchor: "center",
        })
          .setLngLat(start)
          .addTo(map),
      )

      if (end[0] !== start[0] || end[1] !== start[1]) {
        markers.push(
          new mapboxgl.Marker({
            element: markerEl("#047857"),
            anchor: "center",
          })
            .setLngLat(end)
            .addTo(map),
        )
      }

      const bounds = line.reduce(
        (b, c) => b.extend(c),
        new mapboxgl.LngLatBounds(line[0], line[0]),
      )
      map.fitBounds(bounds, { padding: 40, maxZoom: 16, duration: 0 })

      if (!cancelled) setLoading(false)
    }

    map.on("load", () => {
      void run()
    })

    return () => {
      cancelled = true
      markers.forEach((m) => m.remove())
      map.remove()
    }
  }, [pathKey, resolvedTheme])

  if (points.length < 2) {
    return (
      <div className="flex h-full min-h-[200px] w-full items-center justify-center bg-muted/40 text-xs text-muted-foreground">
        Trajeto insuficiente para exibir no mapa.
      </div>
    )
  }

  if (!MAPBOX_TOKEN) {
    return (
      <div className="flex h-full min-h-[200px] w-full items-center justify-center bg-muted/40 px-4 text-center text-xs text-muted-foreground">
        {error ?? "Configure NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN."}
      </div>
    )
  }

  return (
    <div className="relative h-full w-full min-h-[200px]">
      {loading && (
        <div className="absolute inset-0 z-10 flex items-center justify-center rounded-[inherit] bg-muted/50 text-sm text-muted-foreground">
          Carregando mapa…
        </div>
      )}
      {error && !loading && (
        <div className="absolute inset-0 z-10 flex items-center justify-center rounded-[inherit] bg-muted/60 px-3 text-center text-xs text-destructive">
          {error}
        </div>
      )}
      <div ref={containerRef} className="h-full w-full rounded-[inherit]" />
    </div>
  )
}

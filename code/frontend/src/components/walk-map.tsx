"use client"

import { GoogleMap, Polyline, OverlayViewF, useJsApiLoader } from '@react-google-maps/api'
import { useEffect, useRef } from 'react'
import { useTheme } from 'next-themes'

interface Props {
  points: [number, number][]
  walkerPosition: [number, number] | null
}

const MAP_STYLE_LIGHT: google.maps.MapTypeStyle[] = [
  { elementType: "geometry", stylers: [{ color: "#F9FAFB" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#6B7280" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#F9FAFB" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: "#FFFFFF" }] },
  { featureType: "road", elementType: "geometry.stroke", stylers: [{ color: "#E5E7EB" }] },
  { featureType: "road", elementType: "labels.text.fill", stylers: [{ color: "#374151" }] },
  { featureType: "road", elementType: "labels.text.stroke", stylers: [{ color: "#FFFFFF" }] },
  { featureType: "road.highway", elementType: "geometry", stylers: [{ color: "#FFE7E4" }] },
  { featureType: "road.highway", elementType: "geometry.stroke", stylers: [{ color: "#FBBCB8" }] },
  { featureType: "road.highway", elementType: "labels.text.fill", stylers: [{ color: "#111827" }] },
  { featureType: "road.arterial", elementType: "geometry", stylers: [{ color: "#FFFFFF" }] },
  { featureType: "road.local", elementType: "geometry", stylers: [{ color: "#FFFFFF" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#DBEAFE" }] },
  { featureType: "water", elementType: "labels.text.fill", stylers: [{ color: "#93C5FD" }] },
  { featureType: "water", elementType: "labels.text.stroke", stylers: [{ color: "#DBEAFE" }] },
  { featureType: "landscape.natural", elementType: "geometry", stylers: [{ color: "#ECFDF5" }] },
  { featureType: "landscape.man_made", elementType: "geometry", stylers: [{ color: "#F3F4F6" }] },
  { featureType: "landscape.natural.terrain", elementType: "geometry", stylers: [{ color: "#D1FAE5" }] },
  { featureType: "poi", elementType: "geometry", stylers: [{ color: "#F0FDF4" }] },
  { featureType: "poi", elementType: "labels.icon", stylers: [{ visibility: "off" }] },
  { featureType: "poi", elementType: "labels.text.fill", stylers: [{ color: "#9CA3AF" }] },
  { featureType: "poi.park", elementType: "geometry", stylers: [{ color: "#DCFCE7" }] },
  { featureType: "poi.park", elementType: "labels.text.fill", stylers: [{ color: "#6B7280" }] },
  { featureType: "poi.park", elementType: "labels.icon", stylers: [{ visibility: "on" }, { color: "#6B7280" }] },
  { featureType: "poi.sports_complex", elementType: "geometry", stylers: [{ color: "#ECFDF5" }] },
  { featureType: "poi.school", elementType: "geometry", stylers: [{ color: "#FEF3C7" }] },
  { featureType: "poi.medical", elementType: "geometry", stylers: [{ color: "#FEE2E2" }] },
  { featureType: "transit", elementType: "geometry", stylers: [{ color: "#F3F4F6" }] },
  { featureType: "transit", elementType: "labels.icon", stylers: [{ visibility: "on" }] },
  { featureType: "transit.station", elementType: "labels.text.fill", stylers: [{ color: "#9CA3AF" }] },
  { featureType: "administrative", elementType: "geometry", stylers: [{ color: "#E5E7EB" }] },
  { featureType: "administrative.locality", elementType: "labels.text.fill", stylers: [{ color: "#111827" }] },
  { featureType: "administrative.locality", elementType: "labels.text.stroke", stylers: [{ color: "#F9FAFB" }] },
  { featureType: "administrative.neighborhood", elementType: "labels.text.fill", stylers: [{ color: "#9CA3AF" }] },
]

const MAP_STYLE_DARK: google.maps.MapTypeStyle[] = [
  { elementType: "geometry", stylers: [{ color: "#1F2937" }] },
  { elementType: "labels.text.fill", stylers: [{ color: "#9CA3AF" }] },
  { elementType: "labels.text.stroke", stylers: [{ color: "#111827" }] },
  { featureType: "road", elementType: "geometry", stylers: [{ color: "#374151" }] },
  { featureType: "road", elementType: "geometry.stroke", stylers: [{ color: "#1F2937" }] },
  { featureType: "road", elementType: "labels.text.fill", stylers: [{ color: "#D1D5DB" }] },
  { featureType: "road", elementType: "labels.text.stroke", stylers: [{ color: "#111827" }] },
  { featureType: "road.highway", elementType: "geometry", stylers: [{ color: "#3D1F1C" }] },
  { featureType: "road.highway", elementType: "geometry.stroke", stylers: [{ color: "#EE5A52" }] },
  { featureType: "road.highway", elementType: "labels.text.fill", stylers: [{ color: "#F9FAFB" }] },
  { featureType: "road.arterial", elementType: "geometry", stylers: [{ color: "#2D3748" }] },
  { featureType: "road.local", elementType: "geometry", stylers: [{ color: "#2D3748" }] },
  { featureType: "water", elementType: "geometry", stylers: [{ color: "#1E3A5F" }] },
  { featureType: "water", elementType: "labels.text.fill", stylers: [{ color: "#4B7AB5" }] },
  { featureType: "water", elementType: "labels.text.stroke", stylers: [{ color: "#1E3A5F" }] },
  { featureType: "landscape.natural", elementType: "geometry", stylers: [{ color: "#1A2E1F" }] },
  { featureType: "landscape.man_made", elementType: "geometry", stylers: [{ color: "#1F2937" }] },
  { featureType: "landscape.natural.terrain", elementType: "geometry", stylers: [{ color: "#1E3B26" }] },
  { featureType: "poi", elementType: "geometry", stylers: [{ color: "#1A2E1F" }] },
  { featureType: "poi", elementType: "labels.icon", stylers: [{ visibility: "off" }] },
  { featureType: "poi", elementType: "labels.text.fill", stylers: [{ color: "#6B7280" }] },
  { featureType: "poi.park", elementType: "geometry", stylers: [{ color: "#1A3020" }] },
  { featureType: "poi.park", elementType: "labels.text.fill", stylers: [{ color: "#4B7280" }] },
  { featureType: "poi.park", elementType: "labels.icon", stylers: [{ visibility: "on" }, { color: "#4B6B55" }] },
  { featureType: "poi.sports_complex", elementType: "geometry", stylers: [{ color: "#1A2E1F" }] },
  { featureType: "poi.school", elementType: "geometry", stylers: [{ color: "#2A2510" }] },
  { featureType: "poi.medical", elementType: "geometry", stylers: [{ color: "#2A1515" }] },
  { featureType: "transit", elementType: "geometry", stylers: [{ color: "#2D3748" }] },
  { featureType: "transit", elementType: "labels.icon", stylers: [{ visibility: "on" }] },
  { featureType: "transit.station", elementType: "labels.text.fill", stylers: [{ color: "#6B7280" }] },
  { featureType: "administrative", elementType: "geometry", stylers: [{ color: "#374151" }] },
  { featureType: "administrative.locality", elementType: "labels.text.fill", stylers: [{ color: "#F9FAFB" }] },
  { featureType: "administrative.locality", elementType: "labels.text.stroke", stylers: [{ color: "#111827" }] },
  { featureType: "administrative.neighborhood", elementType: "labels.text.fill", stylers: [{ color: "#6B7280" }] },
]

export default function WalkMap({ points, walkerPosition }: Props) {
  const { resolvedTheme } = useTheme()
  const { isLoaded } = useJsApiLoader({
    googleMapsApiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY!,
  })

  const mapRef = useRef<google.maps.Map | null>(null)
  const initialCenterRef = useRef<{ lat: number; lng: number } | null>(null)

  // Troca o estilo quando o tema muda
  useEffect(() => {
    if (!mapRef.current) return
    mapRef.current.setOptions({
      styles: resolvedTheme === 'dark' ? MAP_STYLE_DARK : MAP_STYLE_LIGHT,
    })
  }, [resolvedTheme])

  if (!isLoaded) {
    return <div className="w-full h-full bg-muted animate-pulse" />
  }

  const defaultCenter = { lat: -15.7801, lng: -47.9292 }

  // Define o centro inicial apenas uma vez — não recentra quando a posição atualiza
  if (!initialCenterRef.current) {
    if (walkerPosition) {
      initialCenterRef.current = { lat: walkerPosition[0], lng: walkerPosition[1] }
    } else if (points.length > 0) {
      initialCenterRef.current = { lat: points[points.length - 1][0], lng: points[points.length - 1][1] }
    }
  }

  const center = initialCenterRef.current ?? defaultCenter

  const mapOptions: google.maps.MapOptions = {
    disableDefaultUI: true,
    zoomControl: true,
    clickableIcons: false,
    styles: resolvedTheme === 'dark' ? MAP_STYLE_DARK : MAP_STYLE_LIGHT,
  }

  return (
    <GoogleMap
      mapContainerStyle={{ width: '100%', height: '100%' }}
      center={center}
      zoom={16}
      options={mapOptions}
      onLoad={(map) => { mapRef.current = map }}
    >
      {points.length >= 2 && (
        <Polyline
          path={points.map(([lat, lng]) => ({ lat, lng }))}
          options={{ strokeColor: '#4CAF50', strokeWeight: 4, strokeOpacity: 1 }}
        />
      )}

      {points.length > 0 && (
        <OverlayViewF
          position={{ lat: points[0][0], lng: points[0][1] }}
          mapPaneName="overlayMouseTarget"
        >
          <div style={{
            width: 16, height: 16, borderRadius: '50%',
            backgroundColor: '#22c55e', border: '2px solid #ffffff',
            transform: 'translate(-50%, -50%)',
          }} />
        </OverlayViewF>
      )}

      {walkerPosition && (
        <OverlayViewF
          position={{ lat: walkerPosition[0], lng: walkerPosition[1] }}
          mapPaneName="overlayMouseTarget"
        >
          <div style={{
            width: 22, height: 22, borderRadius: '50%',
            backgroundColor: '#3b82f6', border: '2.5px solid #ffffff',
            transform: 'translate(-50%, -50%)',
          }} />
        </OverlayViewF>
      )}
    </GoogleMap>
  )
}

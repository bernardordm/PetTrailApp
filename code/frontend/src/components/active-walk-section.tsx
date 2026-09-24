"use client"

import dynamic from 'next/dynamic'
import { useEffect, useRef, useState } from 'react'
import { ref, query, orderByChild, equalTo, onValue } from 'firebase/database'
import { db } from '@/shared/lib/firebase'
import { getTourById } from '@/shared/services/tours.service'
import { getWalkerPhotoUrl } from '@/shared/services/walkers.service'
import { useAuthImageSrc } from '@/shared/hooks/use-auth-image-src'
import { Tour } from '@/shared/interfaces/tours.interface'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar'
import { Clock, MapPin, PawPrint } from 'lucide-react'
import { API_URL } from '@/shared/consts/api'

const WalkMap = dynamic(() => import('./walk-map'), {
  ssr: false,
  loading: () => <div className="w-full h-full rounded-xl bg-muted animate-pulse" />,
})

function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371000
  const toRad = (x: number) => (x * Math.PI) / 180
  const dLat = toRad(lat2 - lat1)
  const dLon = toRad(lon2 - lon1)
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
}

function formatElapsed(seconds: number): string {
  const m = Math.floor(seconds / 60).toString().padStart(2, '0')
  const s = (seconds % 60).toString().padStart(2, '0')
  return `${m}:${s}`
}

function formatDistance(meters: number): string {
  if (meters < 1000) return `${Math.round(meters)} m`
  return `${(meters / 1000).toFixed(2)} km`
}

interface ActiveTourData {
  tourId: string
  walkerId: string
  walkerName: string
  startedAt: string | null
}

interface WalkPoint {
  lat: number
  lng: number
}

export default function ActiveWalkSection({ tutorId }: { tutorId: string }) {
  const [activeTour, setActiveTour] = useState<ActiveTourData | null>(null)
  const [tour, setTour] = useState<Tour | null>(null)
  const [points, setPoints] = useState<WalkPoint[]>([])
  const [walkerPos, setWalkerPos] = useState<{ lat: number; lng: number } | null>(null)
  const [elapsed, setElapsed] = useState(0)
  const [checking, setChecking] = useState(true)

  const listenersRef = useRef<(() => void)[]>([])
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null)

  const walkerPhotoSrc = useAuthImageSrc(
    tour?.walker ? getWalkerPhotoUrl(tour.walker.identifier) : undefined
  )

  useEffect(() => {
    const q = query(
      ref(db, 'active_tours'),
      orderByChild('tutor_id'),
      equalTo(tutorId)
    )

    const unsub = onValue(q, (snapshot) => {
      setChecking(false)
      const data = snapshot.val() as Record<string, Record<string, unknown>> | null

      if (!data) {
        setActiveTour(null)
        return
      }

      const [tourId, tourData] = Object.entries(data)[0]

      if (tourData.status !== 'IN_PROGRESS') {
        setActiveTour(null)
        return
      }

      setActiveTour({
        tourId,
        walkerId: tourData.walker_id as string,
        walkerName: tourData.walker_name as string,
        startedAt: (tourData.started_at as string) ?? null,
      })
    })

    return () => unsub()
  }, [tutorId])

  // Busca dados do passeio no backend para info do pet
  useEffect(() => {
    if (!activeTour) {
      setTour(null)
      return
    }
    getTourById(activeTour.tourId)
      .then(setTour)
      .catch(() => setTour(null))
  }, [activeTour?.tourId])

  // Escuta walk_paths e walker_locations
  useEffect(() => {
    listenersRef.current.forEach((fn) => fn())
    listenersRef.current = []

    if (!activeTour) {
      setPoints([])
      setWalkerPos(null)
      return
    }

    const pathUnsub = onValue(
      ref(db, `walk_paths/${activeTour.tourId}`),
      (snapshot) => {
        const data = snapshot.val() as Record<string, { lat: number; lng: number }> | null
        if (!data) {
          setPoints([])
          return
        }
        const pts = Object.entries(data)
          .sort(([a], [b]) => Number(a) - Number(b))
          .map(([, v]) => ({ lat: v.lat, lng: v.lng }))
        setPoints(pts)
      }
    )

    const walkerUnsub = onValue(
      ref(db, `walker_locations/${activeTour.walkerId}`),
      (snapshot) => {
        const data = snapshot.val()
        if (data?.latitude != null && data?.longitude != null) {
          setWalkerPos({ lat: data.latitude, lng: data.longitude })
        }
      }
    )

    listenersRef.current = [pathUnsub, walkerUnsub]

    return () => {
      listenersRef.current.forEach((fn) => fn())
    }
  }, [activeTour?.tourId, activeTour?.walkerId])

  // Timer de tempo decorrido baseado em started_at
  useEffect(() => {
    if (timerRef.current) clearInterval(timerRef.current)

    if (!activeTour?.startedAt) {
      setElapsed(0)
      return
    }

    const start = new Date(activeTour.startedAt).getTime()
    setElapsed(Math.floor((Date.now() - start) / 1000))

    timerRef.current = setInterval(() => {
      setElapsed(Math.floor((Date.now() - start) / 1000))
    }, 1000)

    return () => {
      if (timerRef.current) clearInterval(timerRef.current)
    }
  }, [activeTour?.startedAt])

  const distanceMeters = points.reduce((total, pt, i) => {
    if (i === 0) return 0
    return total + haversine(points[i - 1].lat, points[i - 1].lng, pt.lat, pt.lng)
  }, 0)

  if (checking || !activeTour) return null

  const mapPoints = points.map((p) => [p.lat, p.lng] as [number, number])
  const mapWalker = walkerPos ? ([walkerPos.lat, walkerPos.lng] as [number, number]) : null

  return (
    <section>
      <Card className="bg-green-50/40 dark:bg-green-950/10">
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base font-semibold flex items-center gap-2">
              <PawPrint className="w-4 h-4 text-primary" />
              Passeio em Andamento
            </CardTitle>
            <span className="flex items-center gap-1.5 text-xs font-medium text-green-600 dark:text-green-400">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500" />
              </span>
              Ao vivo
            </span>
          </div>
        </CardHeader>

        <CardContent>
          <div className="flex gap-4">
            {/* Painel de informações */}
            <div className="flex flex-col gap-3 w-44 shrink-0">
              <div className="flex items-center gap-2.5">
                <Avatar className="w-9 h-9 border border-primary/20 shrink-0">
                  <AvatarImage
                    src={walkerPhotoSrc}
                    alt={activeTour.walkerName}
                    className="object-cover"
                  />
                  <AvatarFallback className="bg-primary/10 text-xs font-semibold text-primary">
                    {activeTour.walkerName.slice(0, 2).toUpperCase()}
                  </AvatarFallback>
                </Avatar>
                <div className="min-w-0">
                  <p className="text-sm font-medium leading-tight truncate">
                    {activeTour.walkerName}
                  </p>
                  <p className="text-xs text-muted-foreground">Passeador</p>
                </div>
              </div>

              {tour?.pet && (
                <div className="flex items-center gap-2.5">
                  <Avatar className="w-9 h-9 border border-accent/20 shrink-0">
                    <AvatarImage
                      src={tour.pet.photo_url ? `${API_URL}${tour.pet.photo_url}` : undefined}
                      alt={tour.pet.name}
                      className="object-cover"
                    />
                    <AvatarFallback className="bg-accent/10 text-xs font-semibold text-accent">
                      {tour.pet.name.slice(0, 2).toUpperCase()}
                    </AvatarFallback>
                  </Avatar>
                  <div className="min-w-0">
                    <p className="text-sm font-medium leading-tight truncate">{tour.pet.name}</p>
                    <p className="text-xs text-muted-foreground">Pet</p>
                  </div>
                </div>
              )}

              <div className="flex flex-col gap-2.5 mt-1 p-3 bg-muted/50 rounded-xl">
                <div className="flex items-center gap-2">
                  <Clock className="w-3.5 h-3.5 text-primary shrink-0" />
                  <div>
                    <p className="text-sm font-semibold tabular-nums leading-tight">
                      {formatElapsed(elapsed)}
                    </p>
                    <p className="text-xs text-muted-foreground">Tempo</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <MapPin className="w-3.5 h-3.5 text-green-600 shrink-0" />
                  <div>
                    <p className="text-sm font-semibold leading-tight">
                      {points.length > 0 ? formatDistance(distanceMeters) : '—'}
                    </p>
                    <p className="text-xs text-muted-foreground">Distância</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Mapa */}
            <div className="flex-1 rounded-xl overflow-hidden" style={{ minHeight: 400 }}>
              <WalkMap points={mapPoints} walkerPosition={mapWalker} />
            </div>
          </div>
        </CardContent>
      </Card>
    </section>
  )
}

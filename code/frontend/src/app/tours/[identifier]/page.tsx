"use client"

import { useEffect, useState } from "react"
import { useRouter, useParams } from "next/navigation"
import {
  ArrowLeft,
  Loader2,
  PawPrint,
  User,
  CalendarDays,
  DollarSign,
  KeyRound,
  Clock,
  Timer,
  Footprints,
} from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import { Tour, TourStatus } from "@/shared/interfaces/tours.interface"
import { getTourById } from "@/shared/services/tours.service"
import { getWalkerPhotoUrl } from "@/shared/services/walkers.service"
import { useAuthImageSrc } from "@/shared/hooks/use-auth-image-src"
import { API_URL } from "@/shared/consts/api"
import dynamic from "next/dynamic"

const TourHistoryMap = dynamic(() => import("@/components/tour-history-map"), {
  ssr: false,
  loading: () => <div className="w-full h-full rounded-xl bg-muted animate-pulse" />,
})

const STATUS_LABELS: Record<TourStatus, string> = {
  [TourStatus.WAITING_ACCEPTANCE]: "Aguardando aceitação",
  [TourStatus.WALKER_ON_THE_WAY]: "Passeador a caminho",
  [TourStatus.IN_PROGRESS]: "Em andamento",
  [TourStatus.FINISHED]: "Finalizado",
  [TourStatus.REFUSED]: "Recusado",
}

const STATUS_COLORS: Record<TourStatus, string> = {
  [TourStatus.WAITING_ACCEPTANCE]: "text-amber-700 bg-amber-50",
  [TourStatus.WALKER_ON_THE_WAY]: "text-blue-700 bg-blue-50",
  [TourStatus.IN_PROGRESS]: "text-green-700 bg-green-50",
  [TourStatus.FINISHED]: "text-gray-700 bg-gray-50",
  [TourStatus.REFUSED]: "text-red-700 bg-red-50",
}

function formatDateTime(dateStr: string | null) {
  if (!dateStr) return "—"
  return new Date(dateStr).toLocaleString("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  })
}

function formatTime(dateStr: string | null) {
  if (!dateStr) return "—"
  return new Date(dateStr).toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })
}

function formatDuration(seconds: number | null) {
  if (seconds == null) return "—"
  const m = Math.floor(seconds / 60)
  const s = seconds % 60
  if (m === 0) return `${s} seg`
  return s === 0 ? `${m} min` : `${m} min ${s} seg`
}

function formatDistance(meters: number | null) {
  if (meters == null) return "—"
  if (meters < 1000) return `${Math.round(meters)} m`
  return `${(meters / 1000).toFixed(2).replace(".", ",")} km`
}

function pathToPoints(path: Record<string, { lat: number; lng: number }> | null): [number, number][] {
  if (!path) return []
  return Object.keys(path)
    .sort((a, b) => Number(a) - Number(b))
    .map((k) => [path[k].lat, path[k].lng])
}

function photoUrl(path: string | null) {
  if (!path) return undefined
  return `${API_URL}${path}`
}

function getUserFromStorage() {
  try {
    const raw = localStorage.getItem("user")
    if (!raw) return null
    return JSON.parse(raw) as { identifier: string; role: string }
  } catch {
    return null
  }
}

// ─── Page ─────────────────────────────────────────────────────────────────────

export default function TourDetailPage() {
  const router = useRouter()
  const params = useParams()
  const identifier = params.identifier as string

  const [tour, setTour] = useState<Tour | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [userRole, setUserRole] = useState<string | null>(null)
  const [userIdentifier, setUserIdentifier] = useState<string | null>(null)

  const walkerPhotoSrc = useAuthImageSrc(
    tour?.walker ? getWalkerPhotoUrl(tour.walker.identifier) : undefined
  )

  useEffect(() => {
    const user = getUserFromStorage()
    setUserRole(user?.role ?? null)
    setUserIdentifier(user?.identifier ?? null)

    getTourById(identifier)
      .then(setTour)
      .catch((err: Error) => setError(err.message))
      .finally(() => setLoading(false))
  }, [identifier])

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="w-8 h-8 text-red-400 animate-spin" />
      </div>
    )
  }

  if (error || !tour) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" onClick={() => router.push("/tours")} className="gap-2">
          <ArrowLeft className="w-4 h-4" /> Voltar
        </Button>
        <Card className="border-red-200 bg-red-50">
          <CardContent className="pt-6 text-center text-red-600">
            {error ?? "Passeio não encontrado."}
          </CardContent>
        </Card>
      </div>
    )
  }

  const isWalker = userIdentifier === tour.walker_identifier
  const isTutor  = userIdentifier === tour.tutor_identifier

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-3">
        <Button variant="ghost" size="icon" onClick={() => router.push("/tours")}>
          <ArrowLeft className="w-5 h-5" />
        </Button>
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-foreground">Detalhes do Passeio</h1>
          <p className="text-muted-foreground mt-1">Informações completas sobre o passeio</p>
        </div>
      </div>

      {/* Row 1: Participantes + Resumo */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">

        {/* Card: Pet + Passeador/Tutor */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-semibold text-muted-foreground">Participantes</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col gap-4">
            {/* Pet */}
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0">
                <PawPrint className="w-4 h-4 text-red-500" />
              </div>
              <Avatar className="w-10 h-10 shrink-0">
                <AvatarImage src={photoUrl(tour.pet?.photo_url ?? null)} />
                <AvatarFallback className="bg-red-100 text-red-500 text-sm font-semibold">
                  {tour.pet?.name?.[0]?.toUpperCase() ?? "P"}
                </AvatarFallback>
              </Avatar>
              <div className="min-w-0">
                <p className="font-semibold text-sm truncate">{tour.pet?.name ?? "—"}</p>
                <p className="text-xs text-muted-foreground truncate">
                  {tour.pet?.species ?? "—"}
                </p>
              </div>
            </div>

            <div className="border-t border-border" />

            {/* Walker (hidden if current user is the walker) */}
            {!isWalker && (
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0">
                  <User className="w-4 h-4 text-blue-500" />
                </div>
                <Avatar className="w-10 h-10 shrink-0">
                  <AvatarImage src={walkerPhotoSrc} />
                  <AvatarFallback className="bg-blue-100 text-blue-500 text-sm font-semibold">
                    {tour.walker?.user?.name?.[0]?.toUpperCase() ?? "W"}
                  </AvatarFallback>
                </Avatar>
                <div className="min-w-0">
                  <p className="font-semibold text-sm truncate">{tour.walker?.user?.name ?? "—"}</p>
                  <p className="text-xs text-muted-foreground truncate">
                    Passeador
                  </p>
                </div>
              </div>
            )}

            {/* Tutor (hidden if current user is the tutor) */}
            {!isTutor && (
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0">
                  <User className="w-4 h-4 text-green-500" />
                </div>
                <Avatar className="w-10 h-10 shrink-0">
                  <AvatarFallback className="bg-green-100 text-green-500 text-sm font-semibold">
                    {tour.tutor?.user?.name?.[0]?.toUpperCase() ?? "T"}
                  </AvatarFallback>
                </Avatar>
                <div className="min-w-0">
                  <p className="font-semibold text-sm truncate">{tour.tutor?.user?.name ?? "—"}</p>
                  <p className="text-xs text-muted-foreground truncate">
                    Tutor
                  </p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Card: Custo, status e data */}
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-semibold text-muted-foreground">Resumo</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col gap-4">
            {/* Status */}
            <div className={`inline-flex items-center gap-2 self-start px-3 py-1.5 rounded-xl border text-sm font-semibold ${STATUS_COLORS[tour.status]}`}>
              <span className="w-2 h-2 rounded-full bg-current opacity-70" />
              {STATUS_LABELS[tour.status]}
            </div>

            <div className="border-t border-border" />

            {tour.price != null && (
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-green-100 flex items-center justify-center shrink-0">
                  <DollarSign className="w-4 h-4 text-green-600" />
                </div>
                <div>
                  <p className="text-xs text-muted-foreground">Custo do passeio</p>
                  <p className="font-bold text-green-700 text-lg leading-tight">
                    R$ {Number(tour.price).toFixed(2)}
                  </p>
                </div>
              </div>
            )}

            <div className="border-t border-border" />

            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-gray-100 flex items-center justify-center shrink-0">
                <CalendarDays className="w-4 h-4 text-gray-500" />
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Data de solicitação</p>
                <p className="font-medium text-sm">{formatDateTime(tour.created_at)}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Row 2: Métricas do passeio + Mapa */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">

        {/* Métricas */}
        <Card className="md:col-span-1">
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-semibold text-muted-foreground">Métricas do Passeio</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col gap-4">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-blue-100 flex items-center justify-center shrink-0">
                <Clock className="w-4 h-4 text-blue-500" />
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Horário de início</p>
                <p className="font-medium text-sm">{formatTime(tour.started_at)}</p>
              </div>
            </div>

            <div className="border-t border-border" />

            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-red-100 flex items-center justify-center shrink-0">
                <Clock className="w-4 h-4 text-red-400" />
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Horário de término</p>
                <p className="font-medium text-sm">{formatTime(tour.finished_at)}</p>
              </div>
            </div>

            <div className="border-t border-border" />

            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-purple-100 flex items-center justify-center shrink-0">
                <Timer className="w-4 h-4 text-purple-500" />
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Duração total</p>
                <p className="font-semibold text-sm">{formatDuration(tour.total_time_seconds)}</p>
              </div>
            </div>

            <div className="border-t border-border" />

            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-lg bg-orange-100 flex items-center justify-center shrink-0">
                <Footprints className="w-4 h-4 text-orange-500" />
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Distância percorrida</p>
                <p className="font-semibold text-sm">{formatDistance(tour.distance_meters)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Mapa */}
        <Card className="md:col-span-2">
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-semibold text-muted-foreground">Rota do Passeio</CardTitle>
          </CardHeader>
          <CardContent className="p-0 overflow-hidden rounded-b-xl" style={{ height: 320 }}>
            <TourHistoryMap points={pathToPoints(tour.path)} />
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

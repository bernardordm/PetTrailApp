"use client"

import dynamic from "next/dynamic"
import { useEffect, useState } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  PawPrint,
  Route,
  ChevronRight,
  Loader2,
  Plus,
  Star,
} from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import Link from "next/link"
import { Pet } from "@/shared/interfaces/pets.interface"
import { Tour, TourStatus } from "@/shared/interfaces/tours.interface"
import { getPets } from "@/shared/services/pets.service"
import { getMyLastCompletedTour } from "@/shared/services/tours.service"
import { API_URL } from "@/shared/consts/api"
import ActiveWalkSection from "@/components/active-walk-section"

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
  [TourStatus.WAITING_ACCEPTANCE]: "bg-amber-100 text-amber-700",
  [TourStatus.WALKER_ON_THE_WAY]: "bg-blue-100 text-blue-700",
  [TourStatus.IN_PROGRESS]: "bg-green-100 text-green-700",
  [TourStatus.FINISHED]: "bg-gray-100 text-gray-700",
  [TourStatus.REFUSED]: "bg-red-100 text-red-700",
}

function petPhotoUrl(pet: Pet) {
  if (!pet.photo_url) return undefined
  return `${API_URL}${pet.photo_url}`
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

function formatDuration(seconds: number | null): string {
  if (!seconds) return "—"
  const h = Math.floor(seconds / 3600)
  const m = Math.floor((seconds % 3600) / 60)
  const s = seconds % 60
  if (h > 0) return `${h}h ${m.toString().padStart(2, "0")}min`
  if (m > 0) return `${m}min ${s.toString().padStart(2, "0")}s`
  return `${s}s`
}

function formatDistance(meters: number | null): string {
  if (!meters) return "—"
  if (meters < 1000) return `${Math.round(meters)} m`
  return `${(meters / 1000).toFixed(2)} km`
}

function pathToPoints(
  path: Record<string, { lat: number; lng: number }> | null
): [number, number][] {
  if (!path) return []
  return Object.entries(path)
    .sort(([a], [b]) => Number(a) - Number(b))
    .map(([, v]) => [v.lat, v.lng])
}

const recentReviews = [
  {
    tutor: "Ana Silva",
    pet: "Rex",
    rating: 5,
    comment: "Passeador incrível! O Rex adorou e voltou super feliz. Super recomendo!",
    date: "07/04/2026",
    initials: "AS",
  },
  {
    tutor: "Carlos Mendes",
    pet: "Luna",
    rating: 5,
    comment: "Muito pontual e cuidadoso. A Luna ficou bem tranquila com ele.",
    date: "06/04/2026",
    initials: "CM",
  },
  {
    tutor: "Julia Costa",
    pet: "Bob",
    rating: 4,
    comment: "Ótimo passeio, chegou no horário combinado e foi super atencioso.",
    date: "05/04/2026",
    initials: "JC",
  },
  {
    tutor: "Mariana Rocha",
    pet: "Thor",
    rating: 5,
    comment: "Perfeito! Thor é difícil com estranhos e ele soube lidar muito bem.",
    date: "04/04/2026",
    initials: "MR",
  },
]

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex gap-0.5">
      {[1, 2, 3, 4, 5].map((i) => (
        <Star
          key={i}
          className={`w-3.5 h-3.5 ${i <= rating ? "fill-yellow-400 text-yellow-400" : "text-muted-foreground/30"}`}
        />
      ))}
    </div>
  )
}

export default function DashboardPage() {
  const [pets, setPets] = useState<Pet[]>([])
  const [loading, setLoading] = useState(true)
  const [lastTour, setLastTour] = useState<Tour | null>(null)
  const [toursLoading, setToursLoading] = useState(true)
  const [userName, setUserName] = useState("Usuário")
  const [userRole, setUserRole] = useState<string | null>(null)
  const [tutorIdentifier, setTutorIdentifier] = useState<string | null>(null)
  const [isTutor, setIsTutor] = useState(false)

  useEffect(() => {
    const stored = localStorage.getItem("user")
    if (stored) {
      try {
        const user = JSON.parse(stored)
        if (user.name) setUserName(user.name.split(" ")[0])
        setUserRole(user.role ?? null)
        if (user.role === "tutor") {
          setIsTutor(true)
          if (user.identifier) setTutorIdentifier(user.identifier)
        }
      } catch { /* ignore */ }
    }

    getMyLastCompletedTour()
      .then((tour) => setLastTour(tour))
      .catch(() => {})
      .finally(() => setToursLoading(false))
  }, [])

  useEffect(() => {
    if (!tutorIdentifier) {
      setLoading(false)
      return
    }
    getPets(tutorIdentifier)
      .then(setPets)
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [tutorIdentifier])

  const lastTourPoints = pathToPoints(lastTour?.path ?? null)

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-semibold text-foreground">
          Olá, {userName}!
        </h1>
        <p className="text-muted-foreground mt-1">
          Acompanhe seus pets e passeios
        </p>
      </div>

      {/* Passeio em Andamento — somente tutor */}
      {isTutor && tutorIdentifier && (
        <ActiveWalkSection tutorId={tutorIdentifier} />
      )}

      {/* Meus Pets — somente tutor */}
      {isTutor && (
        <section>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-medium text-foreground">Meus Pets</h2>
            <Link
              href="/pets"
              className="text-sm text-primary hover:underline flex items-center gap-1"
            >
              Ver todos
              <ChevronRight className="w-4 h-4" />
            </Link>
          </div>

          {loading ? (
            <div className="flex items-center justify-center py-8">
              <Loader2 className="w-5 h-5 animate-spin text-muted-foreground" />
            </div>
          ) : pets.length === 0 ? (
            <Card className="border-dashed">
              <CardContent className="flex flex-col items-center justify-center py-8 text-center">
                <PawPrint className="w-10 h-10 text-muted-foreground/40 mb-3" />
                <p className="text-muted-foreground mb-3 text-sm">
                  Nenhum pet cadastrado ainda.
                </p>
                <Button asChild variant="outline" size="sm" className="gap-2">
                  <Link href="/pets">
                    <Plus className="w-4 h-4" />
                    Cadastrar pet
                  </Link>
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              {pets.map((pet) => (
                <Link key={pet.identifier} href="/pets">
                  <Card className="group hover:border-primary/30 transition-colors cursor-pointer">
                    <CardContent className="p-4">
                      <div className="flex items-center gap-4">
                        <Avatar className="w-14 h-14 border-2 border-primary/20">
                          <AvatarImage src={petPhotoUrl(pet)} alt={pet.name} className="object-cover" />
                          <AvatarFallback className="bg-primary/10 text-sm font-medium text-primary">
                            {pet.name.slice(0, 2).toUpperCase()}
                          </AvatarFallback>
                        </Avatar>
                        <div className="flex-1 min-w-0">
                          <p className="font-medium text-foreground truncate">{pet.name}</p>
                          <p className="text-sm text-muted-foreground truncate">{pet.species}</p>
                          {pet.age && (
                            <p className="text-xs text-muted-foreground/70">{pet.age}</p>
                          )}
                        </div>
                        <PawPrint className="w-5 h-5 text-primary/40 group-hover:text-primary transition-colors" />
                      </div>
                    </CardContent>
                  </Card>
                </Link>
              ))}
            </div>
          )}
        </section>
      )}

      {/* Último Passeio */}
      <section>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-medium text-foreground">Último Passeio</h2>
          <Link
            href="/tours"
            className="text-sm text-primary hover:underline flex items-center gap-1"
          >
            Ver histórico
            <ChevronRight className="w-4 h-4" />
          </Link>
        </div>

        {toursLoading ? (
          <div className="flex items-center justify-center py-8">
            <Loader2 className="w-5 h-5 animate-spin text-muted-foreground" />
          </div>
        ) : !lastTour ? (
          <Card className="border-dashed">
            <CardContent className="flex flex-col items-center justify-center py-8 text-center">
              <Route className="w-10 h-10 text-muted-foreground/40 mb-3" />
              <p className="text-muted-foreground text-sm">Nenhum passeio finalizado ainda.</p>
            </CardContent>
          </Card>
        ) : (
          <Card>
            <CardHeader className="pb-3">
              <div className="flex items-center justify-between gap-4">
                <div className="flex items-center gap-3 min-w-0">
                  <Avatar className="w-11 h-11 shrink-0 border border-border">
                    <AvatarImage
                      src={lastTour.pet?.photo_url ? `${API_URL}${lastTour.pet.photo_url}` : undefined}
                      alt={lastTour.pet?.name}
                      className="object-cover"
                    />
                    <AvatarFallback className="bg-muted text-sm font-medium">
                      {lastTour.pet?.name?.slice(0, 2).toUpperCase() ?? "P"}
                    </AvatarFallback>
                  </Avatar>
                  <div className="min-w-0">
                    <CardTitle className="text-base font-semibold truncate">
                      {lastTour.pet?.name ?? "—"}
                    </CardTitle>
                    <p className="text-sm text-muted-foreground truncate">
                      {userRole === "walker"
                        ? `Tutor: ${lastTour.tutor?.user?.name ?? "—"}`
                        : `com ${lastTour.walker?.user?.name ?? "—"}`}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <span className={`hidden sm:inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium ${STATUS_COLORS[lastTour.status]}`}>
                    {STATUS_LABELS[lastTour.status]}
                  </span>
                  <Button asChild variant="ghost" size="sm" className="gap-1 text-muted-foreground hover:text-foreground">
                    <Link href={`/tours/${lastTour.identifier}`}>
                      Ver detalhes
                      <ChevronRight className="w-4 h-4" />
                    </Link>
                  </Button>
                </div>
              </div>
            </CardHeader>

            <CardContent className="pt-0">
              <div className="flex gap-6">
                {/* Informações — metade esquerda */}
                <div className="w-1/2 flex flex-col divide-y divide-border">
                  {[
                    { label: "Duração",   value: formatDuration(lastTour.total_time_seconds) },
                    { label: "Distância", value: formatDistance(lastTour.distance_meters) },
                    { label: "Início",    value: formatDateTime(lastTour.started_at) },
                    { label: "Fim",       value: formatDateTime(lastTour.finished_at) },
                    { label: "Valor",     value: lastTour.price != null ? `R$ ${Number(lastTour.price).toFixed(2)}` : "—" },
                  ].map(({ label, value }) => (
                    <div key={label} className="flex items-center justify-between py-3">
                      <p className="text-sm text-muted-foreground">{label}</p>
                      <p className="text-sm font-medium text-foreground">{value}</p>
                    </div>
                  ))}
                </div>

                {/* Mapa — metade direita */}
                <div className="w-1/2 flex flex-col gap-2">
                  <p className="text-sm text-muted-foreground font-medium">Trajeto percorrido</p>
                  <div className="flex-1 rounded-xl overflow-hidden" style={{ minHeight: 250 }}>
                  {lastTourPoints.length >= 2 ? (
                    <TourHistoryMap points={lastTourPoints} />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center bg-muted/30 rounded-xl">
                      <p className="text-xs text-muted-foreground">Rota não disponível</p>
                    </div>
                  )}
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        )}
      </section>

      {/* Avaliações recentes — somente walker */}
      {userRole === "walker" && (
        <section>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-medium text-foreground">Avaliações Recentes</h2>
            <div className="flex items-center gap-1.5 text-sm text-muted-foreground">
              <Star className="w-4 h-4 fill-yellow-400 text-yellow-400" />
              <span className="font-semibold text-foreground">4.9</span>
              <span>média</span>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {recentReviews.map((review, i) => (
              <Card key={i}>
                <CardContent className="p-4 flex flex-col gap-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <Avatar className="w-9 h-9">
                        <AvatarFallback className="bg-red-100 text-red-500 text-xs font-semibold">
                          {review.initials}
                        </AvatarFallback>
                      </Avatar>
                      <div>
                        <p className="text-sm font-semibold leading-tight">{review.tutor}</p>
                        <p className="text-xs text-muted-foreground">Pet: {review.pet}</p>
                      </div>
                    </div>
                    <span className="text-xs text-muted-foreground shrink-0">{review.date}</span>
                  </div>
                  <StarRating rating={review.rating} />
                  <p className="text-sm text-muted-foreground leading-relaxed">"{review.comment}"</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </section>
      )}
    </div>
  )
}

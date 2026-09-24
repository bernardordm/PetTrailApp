"use client"

import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { Loader2, ArrowRight, PawPrint } from "lucide-react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Tour, TourStatus } from "@/shared/interfaces/tours.interface"
import { getMyTours } from "@/shared/services/tours.service"
import { API_URL } from "@/shared/consts/api"

const STATUS_LABELS: Record<TourStatus, string> = {
  [TourStatus.WAITING_ACCEPTANCE]: "Aguardando aceitação",
  [TourStatus.WALKER_ON_THE_WAY]: "Passeador a caminho",
  [TourStatus.IN_PROGRESS]: "Em andamento",
  [TourStatus.FINISHED]: "Finalizado",
  [TourStatus.REFUSED]: "Recusado",
}
const STATUS_COLORS: Record<TourStatus, string> = {
  [TourStatus.WAITING_ACCEPTANCE]: "text-amber-600 bg-amber-50",
  [TourStatus.WALKER_ON_THE_WAY]: "text-blue-600 bg-blue-50",
  [TourStatus.IN_PROGRESS]: "text-green-600 bg-green-50",
  [TourStatus.FINISHED]: "text-gray-600 bg-gray-50",
  [TourStatus.REFUSED]: "text-red-600 bg-red-50",
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleDateString("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  })
}

function getUserFromStorage() {
  try {
    const raw = localStorage.getItem("user")
    if (!raw) return null
    return JSON.parse(raw) as { identifier: string; name: string; role: string }
  } catch {
    return null
  }
}

function petPhotoUrl(photoUrl: string | null) {
  if (!photoUrl) return undefined
  return `${API_URL}${photoUrl}`
}


export default function ToursPage() {
  const router = useRouter()
  const [tours, setTours] = useState<Tour[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [userRole, setUserRole] = useState<string | null>(null)
  const [filterStatus, setFilterStatus] = useState<TourStatus | "ALL">("ALL")

  useEffect(() => {
    const user = getUserFromStorage()
    if (!user) {
      router.push("/login")
      return
    }
    setUserRole(user.role)

    getMyTours()
      .then(setTours)
      .catch((err: Error) => setError(err.message))
      .finally(() => setLoading(false))
  }, [router])

  const filtered = filterStatus === "ALL" ? tours : tours.filter((t) => t.status === filterStatus)

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl sm:text-3xl font-bold text-foreground">Passeios</h1>
        <p className="text-muted-foreground mt-1">
          {userRole === "walker" ? "Passeios realizados por você" : "Passeios dos seus pets"}
        </p>
      </div>

      {/* Status filter */}
      <div className="flex flex-wrap gap-2">
        <button
          onClick={() => setFilterStatus("ALL")}
          className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
            filterStatus === "ALL"
              ? "bg-red-400 text-white"
              : "bg-gray-100 text-gray-600 hover:bg-gray-200"
          }`}
        >
          Todos ({tours.length})
        </button>
        {Object.values(TourStatus).map((status) => {
          const count = tours.filter((t) => t.status === status).length
          if (count === 0) return null
          return (
            <button
              key={status}
              onClick={() => setFilterStatus(status)}
              className={`px-3 py-1.5 rounded-full text-sm font-medium transition-colors ${
                filterStatus === status
                  ? "bg-red-400 text-white"
                  : "bg-gray-100 text-gray-600 hover:bg-gray-200"
              }`}
            >
              {STATUS_LABELS[status]} ({count})
            </button>
          )
        })}
      </div>

      {loading && (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="w-8 h-8 text-red-400 animate-spin" />
        </div>
      )}

      {error && (
        <Card className="border-red-200 bg-red-50">
          <CardContent className="pt-6 text-center text-red-600">{error}</CardContent>
        </Card>
      )}

      {!loading && !error && filtered.length === 0 && (
        <Card>
          <CardContent className="pt-12 pb-12 flex flex-col items-center gap-3 text-center">
            <div className="w-16 h-16 rounded-full bg-gray-100 flex items-center justify-center">
              <PawPrint className="w-8 h-8 text-gray-300" />
            </div>
            <p className="text-gray-500 font-medium">Nenhum passeio encontrado</p>
            <p className="text-gray-400 text-sm">
              {filterStatus === "ALL"
                ? "Você ainda não tem passeios registrados."
                : "Nenhum passeio com este status."}
            </p>
          </CardContent>
        </Card>
      )}

      {!loading && !error && filtered.length > 0 && (
        <div className="space-y-3">
          {filtered.map((tour) => (
            <Card
              key={tour.identifier}
              className="hover:shadow-md transition-shadow border-border/80"
            >
              <CardContent className="p-4 sm:p-5">
                <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:gap-5">
                  <div
                    role="button"
                    tabIndex={0}
                    className="flex min-w-0 flex-1 cursor-pointer items-center gap-4 rounded-lg outline-none transition-colors hover:bg-muted/50 focus-visible:ring-2 focus-visible:ring-red-400/60 focus-visible:ring-offset-2"
                    onClick={() => router.push(`/tours/${tour.identifier}`)}
                    onKeyDown={(e) => {
                      if (e.key === "Enter" || e.key === " ") {
                        e.preventDefault()
                        router.push(`/tours/${tour.identifier}`)
                      }
                    }}
                  >
                    <Avatar className="h-12 w-12 shrink-0 sm:h-14 sm:w-14">
                      <AvatarImage src={petPhotoUrl(tour.pet?.photo_url ?? null)} />
                      <AvatarFallback className="bg-red-100 text-red-500 font-semibold">
                        {tour.pet?.name?.[0]?.toUpperCase() ?? "P"}
                      </AvatarFallback>
                    </Avatar>

                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="font-semibold text-gray-900">
                          {tour.pet?.name ?? "Pet"}
                        </span>
                        <span
                          className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${STATUS_COLORS[tour.status]}`}
                        >
                          {STATUS_LABELS[tour.status]}
                        </span>
                      </div>
                      <div className="mt-0.5 flex flex-wrap gap-x-3 gap-y-0.5 text-sm text-gray-500">
                        {userRole === "tutor" && (
                          <span>Passeador: {tour.walker?.user?.name ?? "—"}</span>
                        )}
                        {userRole === "walker" && (
                          <span>Tutor: {tour.tutor?.user?.name ?? "—"}</span>
                        )}
                        <span>{formatDate(tour.created_at)}</span>
                        {tour.price != null && (
                          <span className="font-medium text-green-600">
                            R$ {Number(tour.price).toFixed(2)}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  <Button
                    type="button"
                    size="lg"
                    className="h-11 w-full shrink-0 gap-2 bg-red-500 text-white shadow-sm hover:bg-red-600 sm:h-11 sm:w-auto sm:min-w-[10.5rem] sm:px-5"
                    onClick={() => router.push(`/tours/${tour.identifier}`)}
                  >
                    Ver detalhes
                    <ArrowRight className="size-5" aria-hidden />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}

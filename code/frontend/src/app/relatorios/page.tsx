"use client"

import { useState, useEffect, useCallback } from "react"
import type { DateRange } from "react-day-picker"
import { PieChart, Pie, Cell, ResponsiveContainer } from "recharts"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Calendar } from "@/components/ui/calendar"
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover"
import { CalendarIcon, DollarSign, Clock, Star, MapPin, Route, Loader2, Download } from "lucide-react"
import { getReports, exportReports, type ReportData } from "@/shared/services/reports.service"

type Period = "week" | "month" | "custom"

function formatSeconds(seconds: number): string {
  const mins = Math.floor(seconds / 60)
  const secs = Math.floor(seconds % 60)
  if (mins === 0) return `${secs}s`
  return `${mins}min ${secs}s`
}

function formatDistance(meters: number): string {
  if (meters >= 1000) return `${(meters / 1000).toFixed(2)} km`
  return `${meters.toFixed(0)} m`
}

function formatCurrency(value: number): string {
  return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value)
}

function buildKpiCards(data: ReportData, period: Period) {
  return [
    {
      title: "Lucro Total",
      value: formatCurrency(data.totalEarnings),
      description: period === "week" ? "Esta semana" : "Este mês",
      icon: DollarSign,
      color: "text-green-500",
      bg: "bg-green-50",
    },
    {
      title: "Distância Total",
      value: formatDistance(data.totalDistanceMeters),
      description: "Percorrida no período",
      icon: Route,
      color: "text-blue-500",
      bg: "bg-blue-50",
    },
    {
      title: "Tempo Total",
      value: formatSeconds(data.totalTimeSeconds),
      description: "Em passeios",
      icon: Clock,
      color: "text-orange-500",
      bg: "bg-orange-50",
    },
    {
      title: "Duração Média",
      value: formatSeconds(data.averageTimeSeconds),
      description: "Por passeio",
      icon: Clock,
      color: "text-orange-400",
      bg: "bg-orange-50",
    },
    {
      title: "Avaliação Média",
      value: data.averageRating.toFixed(1),
      description: "De 5.0 estrelas",
      icon: Star,
      color: "text-yellow-500",
      bg: "bg-yellow-50",
    },
    {
      title: "Distância Média",
      value: formatDistance(data.averageDistanceMeters),
      description: "Por passeio",
      icon: MapPin,
      color: "text-purple-500",
      bg: "bg-purple-50",
    },
  ]
}

function formatDateLabel(date: Date): string {
  return date.toLocaleDateString("pt-BR", { day: "2-digit", month: "2-digit", year: "numeric" })
}

function toISODate(date: Date): string {
  return date.toISOString().split("T")[0]
}

export default function RelatoriosPage() {
  const [period, setPeriod] = useState<Period>("month")
  const [customRange, setCustomRange] = useState<DateRange | undefined>()
  const [calendarOpen, setCalendarOpen] = useState(false)
  const [data, setData] = useState<ReportData | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [exporting, setExporting] = useState(false)

  const loadData = useCallback(async () => {
    if (period === "custom" && (!customRange?.from || !customRange?.to)) return
    setLoading(true)
    setError(null)
    try {
      const params =
        period === "custom"
          ? { startDate: toISODate(customRange!.from!), endDate: toISODate(customRange!.to!) }
          : { period }
      const report = await getReports(params)
      setData(report)
    } catch {
      setError("Não foi possível carregar o relatório. Tente novamente.")
    } finally {
      setLoading(false)
    }
  }, [period, customRange])

  useEffect(() => {
    loadData()
  }, [loadData])

  const completionData = data
    ? [
        { name: "Concluídos", value: data.completionRate, color: "#22c55e" },
        { name: "Outros", value: Math.max(0, 100 - data.completionRate), color: "#f1f5f9" },
      ]
    : []

  const kpiCards = data ? buildKpiCards(data, period) : []

  function currentParams() {
    return period === "custom"
      ? { startDate: toISODate(customRange!.from!), endDate: toISODate(customRange!.to!) }
      : { period } as { period: "week" | "month" }
  }

  function exportFilename(): string {
    if (period === "custom" && customRange?.from && customRange?.to) {
      return `relatorio_${toISODate(customRange.from)}_${toISODate(customRange.to)}.xlsx`
    }
    return `relatorio_${period}.xlsx`
  }

  async function handleExport() {
    setExporting(true)
    try {
      const blob = await exportReports(currentParams())
      const url = URL.createObjectURL(blob)
      const a = document.createElement("a")
      a.href = url
      a.download = exportFilename()
      a.click()
      URL.revokeObjectURL(url)
    } catch {
      // silently fail — user can retry
    } finally {
      setExporting(false)
    }
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-foreground">Relatórios</h1>
          <p className="text-muted-foreground mt-1">Acompanhe suas métricas e desempenho como passeador</p>
        </div>
        <Button
          variant="outline"
          size="sm"
          className="gap-1.5 shrink-0"
          disabled={exporting || (!data && period !== "custom")}
          onClick={handleExport}
        >
          {exporting
            ? <Loader2 className="w-3.5 h-3.5 animate-spin" />
            : <Download className="w-3.5 h-3.5" />}
          Exportar
        </Button>
      </div>

      {/* Period selector */}
      <div className="flex gap-2">
          <Button
            variant={period === "week" ? "default" : "outline"}
            size="sm"
            onClick={() => setPeriod("week")}
          >
            Semana
          </Button>
          <Button
            variant={period === "month" ? "default" : "outline"}
            size="sm"
            onClick={() => setPeriod("month")}
          >
            Mês
          </Button>
          <Popover open={calendarOpen} onOpenChange={setCalendarOpen}>
            <PopoverTrigger asChild>
              <Button
                variant={period === "custom" ? "default" : "outline"}
                size="sm"
                className="gap-1.5"
              >
                <CalendarIcon className="w-3.5 h-3.5" />
                {period === "custom" && customRange?.from && customRange?.to
                  ? `${formatDateLabel(customRange.from)} – ${formatDateLabel(customRange.to)}`
                  : "Personalizado"}
              </Button>
            </PopoverTrigger>
            <PopoverContent className="w-auto p-0" align="end">
              <Calendar
                mode="range"
                selected={customRange}
                onSelect={(range) => {
                  setCustomRange(range)
                  if (range?.from && range?.to) {
                    setPeriod("custom")
                    setCalendarOpen(false)
                  }
                }}
                disabled={{ after: new Date() }}
                numberOfMonths={2}
              />
            </PopoverContent>
          </Popover>
        </div>

      {loading && (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="w-6 h-6 animate-spin text-muted-foreground" />
        </div>
      )}

      {error && (
        <div className="flex flex-col items-center gap-3 py-12 text-center">
          <p className="text-sm text-red-500">{error}</p>
          <Button variant="outline" size="sm" onClick={loadData}>
            Tentar novamente
          </Button>
        </div>
      )}

      {!loading && data && (
        <>
          {/* KPI Cards */}
          <div className="grid grid-cols-2 sm:grid-cols-3 xl:grid-cols-6 gap-4">
            {kpiCards.map((card) => (
              <Card key={card.title} className="overflow-hidden">
                <CardContent className="p-4 flex flex-col gap-3">
                  <div className={`w-10 h-10 rounded-xl ${card.bg} flex items-center justify-center`}>
                    <card.icon className={`w-5 h-5 ${card.color}`} />
                  </div>
                  <div>
                    <p className="text-2xl font-bold text-foreground leading-tight">{card.value}</p>
                    <p className="text-xs font-medium text-foreground/80 mt-0.5">{card.title}</p>
                    <p className="text-xs text-muted-foreground mt-0.5">{card.description}</p>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>

          {/* Completion rate + period summary */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
            <Card>
              <CardHeader className="pb-2">
                <CardTitle className="text-base">Taxa de conclusão</CardTitle>
                <CardDescription>Percentual de passeios concluídos</CardDescription>
              </CardHeader>
              <CardContent className="flex flex-col items-center gap-3">
                <ResponsiveContainer width="100%" height={160}>
                  <PieChart>
                    <Pie
                      data={completionData}
                      cx="50%"
                      cy="50%"
                      innerRadius={52}
                      outerRadius={76}
                      startAngle={90}
                      endAngle={-270}
                      dataKey="value"
                      paddingAngle={2}
                    >
                      {completionData.map((entry, index) => (
                        <Cell key={index} fill={entry.color} />
                      ))}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
                <div className="text-center mb-8">
                  <p className="text-3xl font-bold">{data.completionRate.toFixed(1)}%</p>
                  <p className="text-xs text-muted-foreground">de passeios concluídos</p>
                </div>
              </CardContent>
            </Card>

            <Card className="lg:col-span-2">
              <CardHeader className="pb-2">
                <CardTitle className="text-base">Resumo do período</CardTitle>
                <CardDescription>
                  {new Date(data.period.startDate).toLocaleDateString("pt-BR")} —{" "}
                  {new Date(data.period.endDate).toLocaleDateString("pt-BR")}
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-x-6 gap-y-5">
                  <div className="space-y-0.5">
                    <p className="text-xs text-muted-foreground">Lucro total</p>
                    <p className="text-base font-semibold text-green-600">{formatCurrency(data.totalEarnings)}</p>
                  </div>
                  <div className="space-y-0.5">
                    <p className="text-xs text-muted-foreground">Avaliação média</p>
                    <p className="text-base font-semibold">{data.averageRating.toFixed(1)} ★</p>
                  </div>
                  <div className="space-y-0.5">
                    <p className="text-xs text-muted-foreground">Distância total</p>
                    <p className="text-base font-semibold">{formatDistance(data.totalDistanceMeters)}</p>
                  </div>
                  <div className="space-y-0.5">
                    <p className="text-xs text-muted-foreground">Tempo total</p>
                    <p className="text-base font-semibold">{formatSeconds(data.totalTimeSeconds)}</p>
                  </div>
                  <div className="space-y-0.5">
                    <p className="text-xs text-muted-foreground">Duração média</p>
                    <p className="text-base font-semibold">{formatSeconds(data.averageTimeSeconds)}</p>
                  </div>
                  <div className="space-y-0.5">
                    <p className="text-xs text-muted-foreground">Distância média</p>
                    <p className="text-base font-semibold">{formatDistance(data.averageDistanceMeters)}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>
        </>
      )}
    </div>
  )
}

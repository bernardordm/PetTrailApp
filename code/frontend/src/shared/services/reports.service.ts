import { API_URL } from "@/shared/consts/api"

export interface ReportData {
  period: {
    startDate: string
    endDate: string
  }
  totalEarnings: number
  totalDistanceMeters: number
  totalTimeSeconds: number
  completionRate: number
  averageTimeSeconds: number
  averageDistanceMeters: number
  averageRating: number
}

type ReportParams =
  | { period: "week" | "month" }
  | { startDate: string; endDate: string }

function authHeaders() {
  const token = localStorage.getItem("token")
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  }
}

function buildQuery(params: ReportParams): URLSearchParams {
  const query = new URLSearchParams()
  if ("period" in params) {
    query.set("period", params.period)
  } else {
    query.set("startDate", params.startDate)
    query.set("endDate", params.endDate)
  }
  return query
}

export async function getReports(params: ReportParams): Promise<ReportData> {
  const res = await fetch(`${API_URL}/reports?${buildQuery(params)}`, {
    headers: authHeaders(),
  })

  if (!res.ok) throw new Error("Erro ao buscar relatório")
  return res.json()
}

export async function exportReports(params: ReportParams): Promise<Blob> {
  const res = await fetch(`${API_URL}/reports/export?${buildQuery(params)}`, {
    headers: authHeaders(),
  })

  if (!res.ok) throw new Error("Erro ao exportar relatório")
  return res.blob()
}

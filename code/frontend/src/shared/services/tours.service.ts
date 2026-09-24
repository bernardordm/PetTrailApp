import { WORKER_URL } from "@/shared/consts/api"
import { Tour } from "@/shared/interfaces/tours.interface"

function authHeaders() {
  const token = localStorage.getItem("token")
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  }
}

export async function getMyTours(): Promise<Tour[]> {
  const res = await fetch(`${WORKER_URL}/tours/my`, {
    headers: authHeaders(),
  })
  if (!res.ok) throw new Error("Erro ao buscar passeios")
  return res.json()
}

export async function getMyLastCompletedTour(): Promise<Tour | null> {
  const res = await fetch(`${WORKER_URL}/tours/my/last-completed`, {
    headers: authHeaders(),
  })
  if (!res.ok) throw new Error("Erro ao buscar último passeio")
  const text = await res.text()
  if (!text) return null
  return JSON.parse(text)
}

export async function getTourById(identifier: string): Promise<Tour> {
  const res = await fetch(`${WORKER_URL}/tours/${identifier}`, {
    headers: authHeaders(),
  })
  if (!res.ok) throw new Error("Erro ao buscar passeio")
  return res.json()
}

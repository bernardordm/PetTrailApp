import { API_URL } from "@/shared/consts/api"
import {UpdateWalkerDto, WalkerProfile} from "@/shared/interfaces/walkers.interface";

function authHeaders() {
  const token = localStorage.getItem("token")
  return {
    "Content-Type": "application/json",
    Authorization: `Bearer ${token}`,
  }
}

function authHeadersRaw() {
  const token = localStorage.getItem("token")
  return {
    Authorization: `Bearer ${token}`,
  }
}

export async function getWalker(identifier: string): Promise<WalkerProfile> {
  const res = await fetch(`${API_URL}/walkers/${identifier}`, {
    headers: authHeaders(),
  })

  if (!res.ok) throw new Error("Erro ao buscar dados do passeador")
  return res.json()
}


export async function updateWalker(identifier: string, data: UpdateWalkerDto): Promise<WalkerProfile> {
  const res = await fetch(`${API_URL}/walkers/${identifier}`, {
    method: "PATCH",
    headers: authHeaders(),
    body: JSON.stringify(data),
  })

  if (!res.ok) throw new Error("Erro ao atualizar dados do passeador")
  return res.json()
}

export async function uploadWalkerPhoto(identifier: string, file: File): Promise<WalkerProfile> {
  const formData = new FormData()
  formData.append("photo", file)

  const res = await fetch(`${API_URL}/walkers/${identifier}/photo`, {
    method: "POST",
    headers: authHeadersRaw(),
    body: formData,
  })

  if (!res.ok) throw new Error("Erro ao enviar foto do passeador")
  return res.json()
}

export function getWalkerPhotoUrl(identifier: string): string {
  return `${API_URL}/walkers/${identifier}/photo`
}

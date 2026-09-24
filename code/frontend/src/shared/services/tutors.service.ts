import { API_URL } from "@/shared/consts/api"
import {TutorProfile, UpdateTutorDto} from "@/shared/interfaces/tutors.interface";

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

export async function getTutor(identifier: string): Promise<TutorProfile> {
  const res = await fetch(`${API_URL}/tutors/${identifier}`, {
    headers: authHeaders(),
  })

  if (!res.ok) throw new Error("Erro ao buscar dados do tutor")
  return res.json()
}

export async function updateTutor(identifier: string, data: UpdateTutorDto): Promise<TutorProfile> {
  const res = await fetch(`${API_URL}/tutors/${identifier}`, {
    method: "PATCH",
    headers: authHeaders(),
    body: JSON.stringify(data),
  })

  if (!res.ok) throw new Error("Erro ao atualizar dados do tutor")
  return res.json()
}

export async function uploadTutorPhoto(identifier: string, file: File): Promise<TutorProfile> {
  const formData = new FormData()
  formData.append("photo", file)

  const res = await fetch(`${API_URL}/tutors/${identifier}/photo`, {
    method: "POST",
    headers: authHeadersRaw(),
    body: formData,
  })

  if (!res.ok) throw new Error("Erro ao enviar foto do tutor")
  return res.json()
}

export function getTutorPhotoUrl(identifier: string): string {
  return `${API_URL}/tutors/${identifier}/photo`
}

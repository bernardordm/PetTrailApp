import { API_URL } from "@/shared/consts/api"
import { Pet, CreatePetDto, UpdatePetDto } from "@/shared/interfaces/pets.interface"

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

export async function getPets(tutorIdentifier: string): Promise<Pet[]> {
  const res = await fetch(`${API_URL}/tutors/${tutorIdentifier}/pets`, {
    headers: authHeaders(),
  })
  if (!res.ok) throw new Error("Erro ao buscar pets")
  return res.json()
}

export async function getPet(tutorIdentifier: string, identifier: string): Promise<Pet> {
  const res = await fetch(`${API_URL}/tutors/${tutorIdentifier}/pets/${identifier}`, {
    headers: authHeaders(),
  })
  if (!res.ok) throw new Error("Erro ao buscar pet")
  return res.json()
}

export async function createPet(tutorIdentifier: string, data: CreatePetDto): Promise<Pet> {
  const res = await fetch(`${API_URL}/tutors/${tutorIdentifier}/pets`, {
    method: "POST",
    headers: authHeaders(),
    body: JSON.stringify(data),
  })
  if (!res.ok) {
    const error = await res.json().catch(() => ({}))
    throw new Error(error.message ?? "Erro ao cadastrar pet")
  }
  return res.json()
}

export async function updatePet(tutorIdentifier: string, identifier: string, data: UpdatePetDto): Promise<Pet> {
  const res = await fetch(`${API_URL}/tutors/${tutorIdentifier}/pets/${identifier}`, {
    method: "PATCH",
    headers: authHeaders(),
    body: JSON.stringify(data),
  })
  if (!res.ok) {
    const error = await res.json().catch(() => ({}))
    throw new Error(error.message ?? "Erro ao atualizar pet")
  }
  return res.json()
}

export async function deletePet(tutorIdentifier: string, identifier: string): Promise<void> {
  const res = await fetch(`${API_URL}/tutors/${tutorIdentifier}/pets/${identifier}`, {
    method: "DELETE",
    headers: authHeaders(),
  })
  if (!res.ok) {
    const error = await res.json().catch(() => ({}))
    throw new Error(error.message ?? "Erro ao remover pet")
  }
}

export async function uploadPetPhoto(
  tutorIdentifier: string,
  identifier: string,
  file: File,
): Promise<Pet> {
  const formData = new FormData()
  formData.append("photo", file)

  const res = await fetch(`${API_URL}/tutors/${tutorIdentifier}/pets/${identifier}/photo`, {
    method: "POST",
    headers: authHeadersRaw(),
    body: formData,
  })
  if (!res.ok) {
    const error = await res.json().catch(() => ({}))
    throw new Error(error.message ?? "Erro ao enviar foto")
  }
  return res.json()
}

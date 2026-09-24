import { API_URL } from "@/shared/consts/api"
import {LoginResponse} from "@/shared/interfaces/auth.interface";

export async function login(email: string, password: string): Promise<LoginResponse> {
  const res = await fetch(`${API_URL}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  })

  if (!res.ok) {
    const error = await res.json().catch(() => ({}))
    throw new Error(error.message ?? "E-mail ou senha inválidos")
  }

  return res.json()
}

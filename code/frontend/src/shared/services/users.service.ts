import { API_URL } from "@/shared/consts/api"
import {User} from "@/shared/interfaces/users.interface";

export async function createUser(data: User): Promise<User> {
    const res = await fetch(`${API_URL}/users`, {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify(data),
    })

    if (!res.ok) {
        const error = await res.json().catch(() => ({}))
        throw new Error(error.message ?? "Erro ao criar usuário")
    }
    return res.json()
}
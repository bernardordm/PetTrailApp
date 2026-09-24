interface UserBase {
    identifier: string
    name: string
    email: string
    role: string
}

export interface TutorProfile {
    identifier: string
    user: UserBase
    address: string
    phone: string
    photo_url: string | null
    latitude: string
    longitude: string
    created_at: string
    updated_at: string
}

export interface UpdateTutorDto {
    address?: string
    phone?: string
    latitude?: number
    longitude?: number
}
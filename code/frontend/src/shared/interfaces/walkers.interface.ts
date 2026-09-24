interface UserBase {
    identifier: string
    name: string
    email: string
    role: string
}

export interface WalkerProfile {
    identifier: string
    user: UserBase
    phone: string
    photo_url: string | null
    document: string
    walkPrice: string
    available: boolean
    averageRideTime: string
    latitude: string
    longitude: string
    averageRating: string
    created_at: string
    updated_at: string
}

export interface UpdateWalkerDto {
    phone?: string
    document?: string
    walkPrice?: number
    available?: boolean
    latitude?: number
    longitude?: number
}
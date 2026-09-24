export interface Pet {
  identifier: string
  name: string
  species: string
  size: string
  age: string | null
  photo_url: string | null
  tutor_identifier: string
  observations: string | null
  created_at: string
  updated_at: string
}

export interface CreatePetDto {
  name: string
  species: string
  size: string
  age?: string
  observations?: string
}

export interface UpdatePetDto {
  name?: string
  species?: string
  size?: string
  age?: string
  observations?: string
}

export interface IPet {
  identifier: string;
  name: string;
  species: string;
  size: string;
  age: string | null;
  photo_url: string | null;
  tutor_identifier: string;
  observations: string | null;
  created_at: Date;
  updated_at: Date;
}

export interface ICreatePet {
  name: string;
  species: string;
  size: string;
  age?: string;
  observations?: string;
}

export interface IUpdatePet {
  name?: string;
  species?: string;
  size?: string;
  age?: string;
  observations?: string;
}

"use client"

import { useEffect, useState, useCallback, useRef } from "react"
import { useRouter } from "next/navigation"
import type { ChangeEvent } from "react"
import Cropper, { type Area } from "react-easy-crop"
import "react-easy-crop/react-easy-crop.css"
import { PawPrint, Plus, Pencil, Trash2, Loader2, Camera, ImageIcon } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Pet, CreatePetDto, UpdatePetDto } from "@/shared/interfaces/pets.interface"
import { getPets, createPet, updatePet, deletePet, uploadPetPhoto } from "@/shared/services/pets.service"
import { API_URL } from "@/shared/consts/api"

const SPECIES_OPTIONS = ["Cachorro", "Gato", "Bode", "Alpaca", "Cavalo", "Coelho", "Outro"]
const SIZE_OPTIONS = [
  { value: "pequeno", label: "Pequeno" },
  { value: "medio", label: "Medio" },
  { value: "grande", label: "Grande" },
]

function getTutorIdentifierFromStorage() {
  const userRaw = localStorage.getItem("user")
  if (!userRaw) return null

  try {
    const parsed = JSON.parse(userRaw) as { identifier?: string }
    return parsed.identifier ?? null
  } catch {
    return null
  }
}

function petPhotoUrl(pet: Pet) {
  if (!pet.photo_url) return undefined
  return `${API_URL}${pet.photo_url}`
}

function createImage(url: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const image = new Image()
    image.onload = () => resolve(image)
    image.onerror = (error) => reject(error)
    image.src = url
  })
}

async function getCroppedImageFile(
  imageSrc: string,
  pixelCrop: Area,
  fileType: string,
  fileName: string,
): Promise<File> {
  const image = await createImage(imageSrc)
  const canvas = document.createElement("canvas")
  const context = canvas.getContext("2d")
  if (!context) throw new Error("Erro ao preparar imagem")

  canvas.width = pixelCrop.width
  canvas.height = pixelCrop.height

  context.drawImage(
    image,
    pixelCrop.x,
    pixelCrop.y,
    pixelCrop.width,
    pixelCrop.height,
    0,
    0,
    pixelCrop.width,
    pixelCrop.height,
  )

  const normalizedType = fileType || "image/jpeg"
  const extension = normalizedType.split("/")[1] || "jpg"

  return new Promise((resolve, reject) => {
    canvas.toBlob(
      (blob) => {
        if (!blob) {
          reject(new Error("Não foi possível recortar a imagem"))
          return
        }
        resolve(new File([blob], `${fileName}.${extension}`, { type: normalizedType }))
      },
      normalizedType,
      0.92,
    )
  })
}

export default function PetsPage() {
  const router = useRouter()
  const [pets, setPets] = useState<Pet[]>([])
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [tutorIdentifier, setTutorIdentifier] = useState<string | null>(null)
  const [authError, setAuthError] = useState("")

  const [dialogOpen, setDialogOpen] = useState(false)
  const [editingPet, setEditingPet] = useState<Pet | null>(null)

  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false)
  const [deletingPet, setDeletingPet] = useState<Pet | null>(null)

  const [formName, setFormName] = useState("")
  const [formSpecies, setFormSpecies] = useState("")
  const [formSize, setFormSize] = useState("")
  const [formAge, setFormAge] = useState("")
  const [formObservations, setFormObservations] = useState("")
  const [formPhoto, setFormPhoto] = useState<File | null>(null)
  const [formPhotoPreview, setFormPhotoPreview] = useState<string | null>(null)
  const [formError, setFormError] = useState("")

  const [cropDialogOpen, setCropDialogOpen] = useState(false)
  const [cropImageSrc, setCropImageSrc] = useState<string | null>(null)
  const [cropImageType, setCropImageType] = useState("image/jpeg")
  const [cropImageName, setCropImageName] = useState("pet")
  const [crop, setCrop] = useState({ x: 0, y: 0 })
  const [zoom, setZoom] = useState(1)
  const [croppedAreaPixels, setCroppedAreaPixels] = useState<Area | null>(null)

  const fileInputRef = useRef<HTMLInputElement>(null)

  const loadPets = useCallback(async () => {
    if (!tutorIdentifier) {
      setLoading(false)
      return
    }

    try {
      setLoading(true)
      const data = await getPets(tutorIdentifier)
      setPets(data)
    } catch {
      console.error("Erro ao carregar pets")
    } finally {
      setLoading(false)
    }
  }, [tutorIdentifier])

  useEffect(() => {
    try {
      const raw = localStorage.getItem("user")
      if (raw) {
        const parsed = JSON.parse(raw) as { role?: string }
        if (parsed.role === "walker") {
          router.replace("/dashboard")
          return
        }
      }
    } catch {
      // ignore
    }

    const tutorId = getTutorIdentifierFromStorage()
    if (!tutorId) {
      setAuthError("Não foi possível identificar o tutor logado. Faca login novamente.")
      setLoading(false)
      return
    }
    setTutorIdentifier(tutorId)
  }, [])

  useEffect(() => {
    loadPets()
  }, [loadPets])

  useEffect(() => {
    return () => {
      if (formPhotoPreview?.startsWith("blob:")) {
        URL.revokeObjectURL(formPhotoPreview)
      }
    }
  }, [formPhotoPreview])

  function openCreateDialog() {
    if (formPhotoPreview?.startsWith("blob:")) {
      URL.revokeObjectURL(formPhotoPreview)
    }
    setEditingPet(null)
    setFormName("")
    setFormSpecies("")
    setFormSize("")
    setFormAge("")
    setFormObservations("")
    setFormPhoto(null)
    setFormPhotoPreview(null)
    setFormError("")
    setDialogOpen(true)
  }

  function openEditDialog(pet: Pet) {
    if (formPhotoPreview?.startsWith("blob:")) {
      URL.revokeObjectURL(formPhotoPreview)
    }
    setEditingPet(pet)
    setFormName(pet.name)
    setFormSpecies(pet.species)
    setFormSize(pet.size)
    setFormAge(pet.age ?? "")
    setFormObservations(pet.observations ?? "")
    setFormPhoto(null)
    setFormPhotoPreview(petPhotoUrl(pet) ?? null)
    setFormError("")
    setDialogOpen(true)
  }

  function openDeleteDialog(pet: Pet) {
    setDeletingPet(pet)
    setDeleteDialogOpen(true)
  }

  function closeCropDialog() {
    setCropDialogOpen(false)
    setCropImageSrc(null)
    setCropImageName("pet")
    setCropImageType("image/jpeg")
    setCrop({ x: 0, y: 0 })
    setZoom(1)
    setCroppedAreaPixels(null)
  }

  function handlePhotoChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = () => {
      setCropImageSrc(reader.result as string)
      setCropImageType(file.type || "image/jpeg")
      setCropImageName(file.name.replace(/\.[^/.]+$/, "") || "pet")
      setCropDialogOpen(true)
    }
    reader.readAsDataURL(file)
  }

  async function handleApplyCrop() {
    if (!cropImageSrc || !croppedAreaPixels) return

    try {
      const croppedFile = await getCroppedImageFile(
        cropImageSrc,
        croppedAreaPixels,
        cropImageType,
        cropImageName,
      )
      const previewUrl = URL.createObjectURL(croppedFile)

      if (formPhotoPreview?.startsWith("blob:")) {
        URL.revokeObjectURL(formPhotoPreview)
      }

      setFormPhoto(croppedFile)
      setFormPhotoPreview(previewUrl)
      closeCropDialog()
    } catch (error) {
      setFormError(error instanceof Error ? error.message : "Erro ao recortar imagem")
    }
  }

  function clearSelectedPhoto() {
    if (formPhotoPreview?.startsWith("blob:")) {
      URL.revokeObjectURL(formPhotoPreview)
    }
    setFormPhoto(null)
    if (editingPet) {
      setFormPhotoPreview(petPhotoUrl(editingPet) ?? null)
      return
    }
    setFormPhotoPreview(null)
    if (fileInputRef.current) {
      fileInputRef.current.value = ""
    }
  }

  async function savePet(): Promise<Pet> {
    if (!tutorIdentifier) throw new Error("Tutor não identificado")

    if (editingPet) {
      const dto: UpdatePetDto = {
        name: formName.trim(),
        species: formSpecies,
        size: formSize,
        age: formAge.trim() || undefined,
        observations: formObservations.trim() || undefined,
      }
      return updatePet(tutorIdentifier, editingPet.identifier, dto)
    }

    const dto: CreatePetDto = {
      name: formName.trim(),
      species: formSpecies,
      size: formSize,
      age: formAge.trim() || undefined,
      observations: formObservations.trim() || undefined,
    }
    return createPet(tutorIdentifier, dto)
  }

  async function uploadPhotoIfSelected(petIdentifier: string): Promise<void> {
    if (!tutorIdentifier || !formPhoto) return
    await uploadPetPhoto(tutorIdentifier, petIdentifier, formPhoto)
  }

  async function handleSubmit() {
    if (!tutorIdentifier) {
      setFormError("Tutor não identificado. Faca login novamente.")
      return
    }

    if (!formName.trim() || !formSpecies || !formSize) {
      setFormError("Preencha os campos obrigatórios: nome, espécie e porte.")
      return
    }

    setSaving(true)
    setFormError("")

    try {
      const pet = await savePet()
      await uploadPhotoIfSelected(pet.identifier)
      setDialogOpen(false)
      await loadPets()
    } catch (error) {
      setFormError(error instanceof Error ? error.message : "Erro ao salvar pet")
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete() {
    if (!deletingPet || !tutorIdentifier) return
    setSaving(true)
    try {
      await deletePet(tutorIdentifier, deletingPet.identifier)
      setDeleteDialogOpen(false)
      setDeletingPet(null)
      await loadPets()
    } catch (error) {
      console.error(error)
    } finally {
      setSaving(false)
    }
  }

  function getSizeLabel(size: string) {
    return SIZE_OPTIONS.find((option) => option.value === size)?.label ?? size
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl sm:text-3xl font-bold text-foreground">Meus Pets</h1>
          <p className="text-muted-foreground mt-1">Gerencie os pets cadastrados</p>
        </div>
        <Button onClick={openCreateDialog} className="gap-2">
          <Plus className="w-4 h-4" />
          Novo Pet
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <PawPrint className="w-5 h-5" />
            Lista de Pets
          </CardTitle>
          <CardDescription>
            {pets.length > 0
              ? `Voce possui ${pets.length} pet${pets.length > 1 ? "s" : ""} cadastrado${pets.length > 1 ? "s" : ""}`
              : "Nenhum pet cadastrado ainda"}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {authError ? (
            <p className="text-sm text-destructive">{authError}</p>
          ) : loading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="w-6 h-6 animate-spin text-muted-foreground" />
            </div>
          ) : pets.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-center">
              <PawPrint className="w-12 h-12 text-muted-foreground/40 mb-4" />
              <p className="text-muted-foreground mb-4">Voce ainda não cadastrou nenhum pet.</p>
              <Button onClick={openCreateDialog} variant="outline" className="gap-2">
                <Plus className="w-4 h-4" />
                Cadastrar primeiro pet
              </Button>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-[60px]">Foto</TableHead>
                  <TableHead>Nome</TableHead>
                  <TableHead>Espécie</TableHead>
                  <TableHead>Porte</TableHead>
                  <TableHead className="hidden sm:table-cell">Idade</TableHead>
                  <TableHead className="hidden md:table-cell">Observações</TableHead>
                  <TableHead className="text-right">Ações</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {pets.map((pet) => (
                  <TableRow key={pet.identifier}>
                    <TableCell>
                      <Avatar className="w-10 h-10 border-2 border-primary/20">
                        <AvatarImage src={petPhotoUrl(pet)} alt={pet.name} className="object-cover" />
                        <AvatarFallback className="bg-primary/10 text-xs font-medium text-primary">
                          {pet.name.slice(0, 2).toUpperCase()}
                        </AvatarFallback>
                      </Avatar>
                    </TableCell>
                    <TableCell className="font-medium">{pet.name}</TableCell>
                    <TableCell>{pet.species}</TableCell>
                    <TableCell>{getSizeLabel(pet.size)}</TableCell>
                    <TableCell className="hidden sm:table-cell text-muted-foreground">
                      {pet.age || "-"}
                    </TableCell>
                    <TableCell className="hidden md:table-cell max-w-[200px] truncate text-muted-foreground">
                      {pet.observations || "-"}
                    </TableCell>
                    <TableCell className="text-right">
                      <div className="flex items-center justify-end gap-1">
                        <Button variant="ghost" size="icon" onClick={() => openEditDialog(pet)} title="Editar">
                          <Pencil className="w-4 h-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => openDeleteDialog(pet)}
                          title="Remover"
                          className="text-destructive hover:text-destructive"
                        >
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>{editingPet ? "Editar Pet" : "Novo Pet"}</DialogTitle>
            <DialogDescription>
              {editingPet
                ? "Altere as informações do seu pet."
                : "Preencha as informações para cadastrar um novo pet."}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2">
            <div className="flex flex-col items-center gap-3">
              <div
                className="relative w-24 h-24 rounded-full border-2 border-dashed border-muted-foreground/30 hover:border-primary/50 transition-colors cursor-pointer overflow-hidden group"
                onClick={() => fileInputRef.current?.click()}
              >
                {formPhotoPreview ? (
                  <>
                    <img src={formPhotoPreview} alt="Preview" className="w-full h-full object-cover" />
                    <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                      <Camera className="w-6 h-6 text-white" />
                    </div>
                  </>
                ) : (
                  <div className="w-full h-full flex flex-col items-center justify-center text-muted-foreground/50">
                    <ImageIcon className="w-8 h-8" />
                  </div>
                )}
              </div>
              <div className="flex items-center gap-3 text-xs">
                <button
                  type="button"
                  className="text-primary hover:underline"
                  onClick={() => fileInputRef.current?.click()}
                >
                  {formPhotoPreview ? "Trocar foto" : "Adicionar foto"}
                </button>
                {formPhotoPreview && (
                  <button type="button" className="text-muted-foreground hover:underline" onClick={clearSelectedPhoto}>
                    Remover foto
                  </button>
                )}
              </div>
              <input
                ref={fileInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp,image/gif"
                className="hidden"
                aria-label="Foto do pet"
                onChange={handlePhotoChange}
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="pet-name">Nome *</Label>
              <Input id="pet-name" placeholder="Ex: Luna" value={formName} onChange={(event) => setFormName(event.target.value)} />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Espécie *</Label>
                <Select value={formSpecies} onValueChange={setFormSpecies}>
                  <SelectTrigger className="w-full">
                    <SelectValue placeholder="Selecione" />
                  </SelectTrigger>
                  <SelectContent>
                    {SPECIES_OPTIONS.map((species) => (
                      <SelectItem key={species} value={species}>
                        {species}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Porte *</Label>
                <Select value={formSize} onValueChange={setFormSize}>
                  <SelectTrigger className="w-full">
                    <SelectValue placeholder="Selecione" />
                  </SelectTrigger>
                  <SelectContent>
                    {SIZE_OPTIONS.map((size) => (
                      <SelectItem key={size.value} value={size.value}>
                        {size.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="pet-age">Idade</Label>
              <Input id="pet-age" placeholder="Ex: 3 anos" value={formAge} onChange={(event) => setFormAge(event.target.value)} />
            </div>

            <div className="space-y-2">
              <Label htmlFor="pet-obs">Observações</Label>
              <Textarea
                id="pet-obs"
                placeholder="Alergias, medicamentos, comportamento..."
                value={formObservations}
                onChange={(event) => setFormObservations(event.target.value)}
                rows={3}
              />
            </div>

            {formError && <p className="text-sm text-destructive">{formError}</p>}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setDialogOpen(false)} disabled={saving}>
              Cancelar
            </Button>
            <Button onClick={handleSubmit} disabled={saving}>
              {saving && <Loader2 className="w-4 h-4 animate-spin mr-2" />}
              {editingPet ? "Salvar" : "Cadastrar"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={cropDialogOpen} onOpenChange={(open) => (!open ? closeCropDialog() : setCropDialogOpen(true))}>
        <DialogContent className="sm:max-w-xl">
          <DialogHeader>
            <DialogTitle>Ajustar foto do pet</DialogTitle>
            <DialogDescription>Arraste e ajuste o zoom para escolher a parte da imagem que vai aparecer.</DialogDescription>
          </DialogHeader>

          <div className="space-y-4">
            <div className="relative h-80 w-full rounded-md overflow-hidden bg-black">
              {cropImageSrc && (
                <Cropper
                  image={cropImageSrc}
                  crop={crop}
                  zoom={zoom}
                  aspect={1}
                  cropShape="round"
                  showGrid={false}
                  onCropChange={setCrop}
                  onZoomChange={setZoom}
                  onCropComplete={(_crop, areaPixels) => setCroppedAreaPixels(areaPixels)}
                />
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="zoom-range">Zoom</Label>
              <input
                id="zoom-range"
                type="range"
                aria-label="Ajuste de zoom do recorte"
                title="Ajuste de zoom do recorte"
                min={1}
                max={3}
                step={0.1}
                value={zoom}
                onChange={(event) => setZoom(Number(event.target.value))}
                className="w-full"
              />
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={closeCropDialog}>
              Cancelar
            </Button>
            <Button type="button" onClick={handleApplyCrop}>
              Usar esta foto
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog open={deleteDialogOpen} onOpenChange={setDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Remover pet</AlertDialogTitle>
            <AlertDialogDescription>
              Tem certeza que deseja remover <strong>{deletingPet?.name}</strong>? Esta ação não pode ser desfeita.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel disabled={saving}>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={handleDelete}
              disabled={saving}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              {saving && <Loader2 className="w-4 h-4 animate-spin mr-2" />}
              Remover
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}

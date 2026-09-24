"use client"

import { useEffect, useRef, useState } from "react"
import type { ChangeEvent, ReactNode } from "react"
import Cropper, { type Area } from "react-easy-crop"
import "react-easy-crop/react-easy-crop.css"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { User, Phone, DollarSign, Pencil, Check, X, Camera, Loader2 } from "lucide-react"
import {
  getTutor,
  getTutorPhotoUrl,
  updateTutor,
  uploadTutorPhoto,
} from "@/shared/services/tutors.service"
import {
  getWalker,
  getWalkerPhotoUrl,
  updateWalker,
  uploadWalkerPhoto,
} from "@/shared/services/walkers.service"
import { TutorProfile } from "@/shared/interfaces/tutors.interface"
import { WalkerProfile } from "@/shared/interfaces/walkers.interface"

type Profile = TutorProfile | WalkerProfile

function maskPhone(value: string | null | undefined) {
  if (!value) return "-"
  const digits = value.replace(/\D/g, "").slice(0, 11)
  if (digits.length <= 10) {
    return digits.replace(/(\d{2})(\d{4})(\d{0,4})/, "($1) $2-$3").replace(/-$/, "")
  }
  return digits.replace(/(\d{2})(\d{5})(\d{0,4})/, "($1) $2-$3").replace(/-$/, "")
}

function maskCpf(value: string) {
  const digits = value.replace(/\D/g, "").slice(0, 11)
  return digits
    .replace(/(\d{3})(\d)/, "$1.$2")
    .replace(/(\d{3})(\d)/, "$1.$2")
    .replace(/(\d{3})(\d{1,2})$/, "$1-$2")
}

function stripMask(value: string) {
  return value.replace(/\D/g, "")
}

function isTutor(profile: Profile): profile is TutorProfile {
  return profile.user.role === "tutor"
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
          reject(new Error("Nao foi possivel recortar a imagem"))
          return
        }
        resolve(new File([blob], `${fileName}.${extension}`, { type: normalizedType }))
      },
      normalizedType,
      0.92,
    )
  })
}

function profilePhotoUrl(profile: Profile): string {
  return isTutor(profile)
    ? getTutorPhotoUrl(profile.identifier)
    : getWalkerPhotoUrl(profile.identifier)
}

function EditableCardHeader({
  icon,
  title,
  isEditing,
  saving,
  onEdit,
  onSave,
  onCancel,
}: {
  icon: ReactNode
  title: string
  isEditing: boolean
  saving: boolean
  onEdit: () => void
  onSave: () => void
  onCancel: () => void
}) {
  return (
    <CardHeader>
      <CardTitle className="flex items-center justify-between text-base">
        <span className="flex items-center gap-2">
          {icon}
          {title}
        </span>
        {isEditing ? (
          <div className="flex items-center gap-1">
            <Button variant="ghost" size="icon" className="h-7 w-7 text-destructive" onClick={onCancel} disabled={saving}>
              <X className="w-4 h-4" />
            </Button>
            <Button variant="ghost" size="icon" className="h-7 w-7 text-green-600" onClick={onSave} disabled={saving}>
              <Check className="w-4 h-4" />
            </Button>
          </div>
        ) : (
          <Button variant="ghost" size="icon" className="h-7 w-7 text-muted-foreground" onClick={onEdit}>
            <Pencil className="w-4 h-4" />
          </Button>
        )}
      </CardTitle>
    </CardHeader>
  )
}

export default function PerfilPage() {
  const [profile, setProfile] = useState<Profile | null>(null)
  const [error, setError] = useState("")
  const [editingCard, setEditingCard] = useState<string | null>(null)
  const [draft, setDraft] = useState<Record<string, string | boolean>>({})
  const [saving, setSaving] = useState(false)
  const [uploadingPhoto, setUploadingPhoto] = useState(false)

  const [selectedPhoto, setSelectedPhoto] = useState<File | null>(null)
  const [photoPreview, setPhotoPreview] = useState<string | null>(null)
  const [photoInputResetKey, setPhotoInputResetKey] = useState(0)

  const fileInputRef = useRef<HTMLInputElement>(null)

  const [cropDialogOpen, setCropDialogOpen] = useState(false)
  const [cropImageSrc, setCropImageSrc] = useState<string | null>(null)
  const [cropImageType, setCropImageType] = useState("image/jpeg")
  const [cropImageName, setCropImageName] = useState("perfil")
  const [crop, setCrop] = useState({ x: 0, y: 0 })
  const [zoom, setZoom] = useState(1)
  const [croppedAreaPixels, setCroppedAreaPixels] = useState<Area | null>(null)

  useEffect(() => {
    const raw = localStorage.getItem("user")
    if (!raw) return
    const user = JSON.parse(raw) as { identifier: string; role: string }
    const fetchFn = user.role === "tutor" ? getTutor : getWalker
    fetchFn(user.identifier)
      .then(setProfile)
      .catch((err) => setError(err.message))
  }, [])

  useEffect(() => {
    return () => {
      if (photoPreview?.startsWith("blob:")) {
        URL.revokeObjectURL(photoPreview)
      }
    }
  }, [photoPreview])

  function startEdit(cardId: string, fields: Record<string, string | boolean>) {
    setEditingCard(cardId)
    setDraft(fields)
  }

  function cancelEdit() {
    setEditingCard(null)
    setDraft({})
  }

  async function saveEdit() {
    if (!profile) return
    setSaving(true)
    setError("")
    try {
      let updated: Profile
      if (isTutor(profile)) {
        updated = await updateTutor(profile.identifier, {
          phone: stripMask(draft.phone as string),
          address: draft.address as string,
        })
      } else {
        updated = await updateWalker(profile.identifier, {
          phone: stripMask(draft.phone as string),
          document: stripMask(draft.document as string),
          walkPrice: draft.walkPrice ? Number(draft.walkPrice) : undefined,
        })
      }
      setProfile(updated)
      setEditingCard(null)
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro ao salvar")
    } finally {
      setSaving(false)
    }
  }

  function closeCropDialog() {
    setCropDialogOpen(false)
    setCropImageSrc(null)
    setCropImageName("perfil")
    setCropImageType("image/jpeg")
    setCrop({ x: 0, y: 0 })
    setZoom(1)
    setCroppedAreaPixels(null)
  }

  function handlePhotoSelection(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = () => {
      setCropImageSrc(reader.result as string)
      setCropImageType(file.type || "image/jpeg")
      setCropImageName(file.name.replace(/\.[^/.]+$/, "") || "perfil")
      setCropDialogOpen(true)
    }
    reader.readAsDataURL(file)
  }

  async function applyPhotoCrop() {
    if (!cropImageSrc || !croppedAreaPixels) return

    try {
      const croppedFile = await getCroppedImageFile(
        cropImageSrc,
        croppedAreaPixels,
        cropImageType,
        cropImageName,
      )

      if (photoPreview?.startsWith("blob:")) {
        URL.revokeObjectURL(photoPreview)
      }

      const previewUrl = URL.createObjectURL(croppedFile)
      setSelectedPhoto(croppedFile)
      setPhotoPreview(previewUrl)
      closeCropDialog()
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro ao recortar imagem")
    }
  }

  function clearSelectedPhoto() {
    if (photoPreview?.startsWith("blob:")) {
      URL.revokeObjectURL(photoPreview)
    }
    setSelectedPhoto(null)
    setPhotoPreview(null)
    setPhotoInputResetKey((key) => key + 1)
  }

  async function saveProfilePhoto() {
    if (!profile || !selectedPhoto) return

    setUploadingPhoto(true)
    setError("")
    try {
      const updated = isTutor(profile)
        ? await uploadTutorPhoto(profile.identifier, selectedPhoto)
        : await uploadWalkerPhoto(profile.identifier, selectedPhoto)

      if (photoPreview?.startsWith("blob:")) {
        URL.revokeObjectURL(photoPreview)
      }

      setProfile(updated)
      setSelectedPhoto(null)
      setPhotoPreview(`${profilePhotoUrl(updated)}?t=${Date.now()}`)
      setPhotoInputResetKey((key) => key + 1)
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro ao salvar foto")
    } finally {
      setUploadingPhoto(false)
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl sm:text-3xl font-bold text-foreground">Perfil</h1>
        <p className="text-muted-foreground mt-1">Suas informações pessoais</p>
      </div>

      {error && <p className="text-sm text-destructive">{error}</p>}

      {!profile && !error && (
        <p className="text-muted-foreground text-sm">Carregando...</p>
      )}

      {profile && (
        <div className="grid gap-4 sm:grid-cols-2">

          {/* Card largo: foto + dados pessoais */}
          <Card className="sm:col-span-2">
            <CardContent className="flex flex-col sm:flex-row gap-6 pt-6">
              <div className="flex flex-col items-center gap-3">
                <Avatar className="w-24 h-24 border-2 border-primary/20">
                  <AvatarImage
                    src={photoPreview || (profile.photo_url ? profilePhotoUrl(profile) : undefined)}
                    alt={profile.user.name}
                    className="object-cover"
                  />
                  <AvatarFallback className="bg-primary/10 text-sm font-medium text-primary">
                    {profile.user.name.slice(0, 2).toUpperCase()}
                  </AvatarFallback>
                </Avatar>
                <input
                  key={photoInputResetKey}
                  ref={fileInputRef}
                  type="file"
                  accept="image/jpeg,image/png,image/webp,image/gif"
                  onChange={handlePhotoSelection}
                  className="hidden"
                />
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={uploadingPhoto}
                >
                  <Camera className="w-4 h-4 mr-2" />
                  {profile.photo_url || photoPreview ? "Alterar foto" : "Adicionar foto"}
                </Button>
                {selectedPhoto && (
                  <div className="flex gap-2">
                    <Button size="sm" onClick={saveProfilePhoto} disabled={uploadingPhoto}>
                      {uploadingPhoto && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                      Salvar
                    </Button>
                    <Button size="sm" variant="outline" onClick={clearSelectedPhoto} disabled={uploadingPhoto}>
                      Cancelar
                    </Button>
                  </div>
                )}
              </div>

              <div className="hidden sm:block w-px bg-border self-stretch" />

              <div className="flex-1 space-y-3">
                <p className="font-semibold text-base flex items-center gap-2">
                  <User className="w-4 h-4" />
                  Dados pessoais
                </p>
                <div className="space-y-2 text-sm">
                  <p><span className="text-muted-foreground">Nome:</span> {profile.user.name}</p>
                  <p><span className="text-muted-foreground">E-mail:</span> {profile.user.email}</p>
                  <p><span className="text-muted-foreground">Perfil:</span> {profile.user.role === "tutor" ? "Tutor" : "Passeador"}</p>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Tutor: contato e endereço */}
          {isTutor(profile) && (
            <Card className="sm:col-span-2">
              <EditableCardHeader
                icon={<Phone className="w-4 h-4" />}
                title="Contato e Endereço"
                isEditing={editingCard === "contato"}
                saving={saving}
                onEdit={() => startEdit("contato", { phone: maskPhone(profile.phone), address: profile.address })}
                onSave={saveEdit}
                onCancel={cancelEdit}
              />
              <CardContent className="space-y-3 text-sm">
                {editingCard === "contato" ? (
                  <>
                    <div className="space-y-1">
                      <p className="text-muted-foreground">Telefone</p>
                      <Input value={draft.phone as string} onChange={(e) => setDraft((d) => ({ ...d, phone: maskPhone(e.target.value) }))} />
                    </div>
                    <div className="space-y-1">
                      <p className="text-muted-foreground">Endereço</p>
                      <Input value={draft.address as string} onChange={(e) => setDraft((d) => ({ ...d, address: e.target.value }))} />
                    </div>
                  </>
                ) : (
                  <>
                    <p><span className="text-muted-foreground">Telefone:</span> {maskPhone(profile.phone)}</p>
                    <p><span className="text-muted-foreground">Endereço:</span> {profile.address}</p>
                  </>
                )}
              </CardContent>
            </Card>
          )}

          {/* Walker: dois cards menores */}
          {!isTutor(profile) && (
            <>
              <Card>
                <EditableCardHeader
                  icon={<DollarSign className="w-4 h-4" />}
                  title="Dados do passeio"
                  isEditing={editingCard === "passeio"}
                  saving={saving}
                  onEdit={() => startEdit("passeio", { walkPrice: profile.walkPrice })}
                  onSave={saveEdit}
                  onCancel={cancelEdit}
                />
                <CardContent className="space-y-3 text-sm">
                  {editingCard === "passeio" ? (
                    <div className="space-y-1">
                      <p className="text-muted-foreground">Preço por passeio (R$)</p>
                      <Input
                        type="number"
                        value={draft.walkPrice as string}
                        onChange={(e) => setDraft((d) => ({ ...d, walkPrice: e.target.value }))}
                      />
                    </div>
                  ) : (
                    <>
                      <p><span className="text-muted-foreground">Preço:</span> R$ {profile.walkPrice}</p>
                      <p><span className="text-muted-foreground">Tempo médio de passeio:</span> {Math.round(Number(profile.averageRideTime))} min</p>
                      <p><span className="text-muted-foreground">Avaliação:</span> {profile.averageRating} / 5.00</p>
                    </>
                  )}
                </CardContent>
              </Card>

              <Card>
                <EditableCardHeader
                  icon={<Phone className="w-4 h-4" />}
                  title="Contato e Documento"
                  isEditing={editingCard === "contato"}
                  saving={saving}
                  onEdit={() => startEdit("contato", { phone: maskPhone(profile.phone), document: maskCpf(profile.document) })}
                  onSave={saveEdit}
                  onCancel={cancelEdit}
                />
                <CardContent className="space-y-3 text-sm">
                  {editingCard === "contato" ? (
                    <>
                      <div className="space-y-1">
                        <p className="text-muted-foreground">Telefone</p>
                        <Input value={draft.phone as string} onChange={(e) => setDraft((d) => ({ ...d, phone: maskPhone(e.target.value) }))} />
                      </div>
                      <div className="space-y-1">
                        <p className="text-muted-foreground">Documento</p>
                        <Input value={draft.document as string} onChange={(e) => setDraft((d) => ({ ...d, document: maskCpf(e.target.value) }))} />
                      </div>
                    </>
                  ) : (
                    <>
                      <p><span className="text-muted-foreground">Telefone:</span> {maskPhone(profile.phone)}</p>
                      <p><span className="text-muted-foreground">Documento:</span> {maskCpf(profile.document)}</p>
                    </>
                  )}
                </CardContent>
              </Card>
            </>
          )}
        </div>
      )}

      <Dialog
        open={cropDialogOpen}
        onOpenChange={(open) => (!open ? closeCropDialog() : setCropDialogOpen(true))}
      >
        <DialogContent className="sm:max-w-xl">
          <DialogHeader>
            <DialogTitle>Ajustar foto de perfil</DialogTitle>
            <DialogDescription>
              Arraste e ajuste o zoom para escolher a parte da imagem.
            </DialogDescription>
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
              <label htmlFor="zoom-range-profile" className="text-sm font-medium">
                Zoom
              </label>
              <input
                id="zoom-range-profile"
                type="range"
                min={1}
                max={3}
                step={0.1}
                value={zoom}
                onChange={(event) => setZoom(Number(event.target.value))}
                className="w-full"
                aria-label="Ajuste de zoom do recorte da foto de perfil"
              />
            </div>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={closeCropDialog}>
              Cancelar
            </Button>
            <Button type="button" onClick={applyPhotoCrop}>
              Usar esta foto
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

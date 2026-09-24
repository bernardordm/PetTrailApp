"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import Image from "next/image"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { FieldGroup, Field, FieldLabel } from "@/components/ui/field"
import { PawPrint, Eye, EyeOff, Dog, Footprints } from "lucide-react"
import { cn } from "@/shared/lib/utils"
import { createUser } from "@/shared/services/users.service"

type UserType = "tutor" | "passeador"

export default function CadastroPage() {
  const router = useRouter()
  const [showPassword, setShowPassword] = useState(false)
  const [nome, setNome] = useState("")
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [userType, setUserType] = useState<UserType>("tutor")
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState("")

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError("")
    try {
      await createUser({
        name: nome,
        email,
        password,
        role: userType === "passeador" ? "walker" : "tutor",
      })
      router.push("/login")
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro ao criar conta")
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex">
      {/* Lado esquerdo - Imagem */}
      <div className="hidden lg:block lg:w-1/2 relative">
        <Image
          src="/images/woman-with-pet.jpg"
          alt="Mulher feliz passeando com seu cachorro"
          fill
          className="object-cover"
          priority
        />
        <div className="absolute inset-0 bg-linear-to-t from-black/60 via-transparent to-transparent" />
        <div className="absolute top-8 left-8 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-red-400 flex items-center justify-center">
            <PawPrint className="w-6 h-6 text-primary-foreground" />
          </div>
          <span className="text-xl font-semibold text-white">PetTrail</span>
        </div>
        <div className="absolute bottom-8 left-8 right-8">
          <p className="text-white/90 text-lg font-medium">
            Junte-se a milhares de donos que confiam no PetTrail para cuidar de seus pets.
          </p>
        </div>
      </div>

      {/* Lado direito - Formulário */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-6 sm:p-12 bg-background">
        <div className="w-full max-w-md">
          {/* Logo mobile */}
          <div className="lg:hidden flex items-center gap-3 mb-10 justify-center">
            <div className="w-10 h-10 rounded-xl bg-primary flex items-center justify-center">
              <PawPrint className="w-6 h-6 text-primary-foreground" />
            </div>
            <span className="text-xl font-semibold text-foreground">PetTrail</span>
          </div>

          <Card className="border-0 shadow-none bg-transparent">
            <CardHeader className="px-0 pt-0">
              <CardTitle className="text-2xl sm:text-3xl font-semibold text-foreground">
                Criar conta
              </CardTitle>
              <CardDescription className="text-muted-foreground text-base">
                Cadastre-se para começar a usar o PetTrail
              </CardDescription>
            </CardHeader>
            <CardContent className="px-0">
              <form onSubmit={handleRegister} className="space-y-5">
                <FieldGroup>
                  <Field>
                    <FieldLabel htmlFor="nome">Nome completo</FieldLabel>
                    <Input
                      id="nome"
                      type="text"
                      placeholder="Seu nome"
                      value={nome}
                      onChange={(e) => setNome(e.target.value)}
                      required
                      className="h-12"
                    />
                  </Field>
                  <Field>
                    <FieldLabel htmlFor="email">E-mail</FieldLabel>
                    <Input
                      id="email"
                      type="email"
                      placeholder="seu@email.com"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      required
                      className="h-12"
                    />
                  </Field>
                  <Field>
                    <FieldLabel htmlFor="password">Senha</FieldLabel>
                    <div className="relative">
                      <Input
                        id="password"
                        type={showPassword ? "text" : "password"}
                        placeholder="Crie uma senha"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        required
                        className="h-12 pr-12"
                      />
                      <button
                        type="button"
                        onClick={() => setShowPassword(!showPassword)}
                        className="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground transition-colors"
                      >
                        {showPassword ? (
                          <EyeOff className="w-5 h-5" />
                        ) : (
                          <Eye className="w-5 h-5" />
                        )}
                      </button>
                    </div>
                  </Field>
                </FieldGroup>

                {/* Seletor Tutor/Passeador */}
                <div className="space-y-2">
                  <FieldLabel>Você é</FieldLabel>
                  <div className="grid grid-cols-2 gap-3">
                    <button
                      type="button"
                      onClick={() => setUserType("tutor")}
                      className={cn(
                        "flex flex-col items-center gap-2 p-4 rounded-xl border-2 transition-all",
                        userType === "tutor"
                          ? "border-red-400 bg-primary/5"
                          : "border-border hover:border-red-400"
                      )}
                    >
                      <Dog className={cn(
                        "w-8 h-8",
                        userType === "tutor" ? "text-red-400" : "text-muted-foreground"
                      )} />
                      <span className={cn(
                        "font-medium text-sm",
                        userType === "tutor" ? "text-red-400" : "text-muted-foreground"
                      )}>
                        Tutor
                      </span>
                      <span className="text-xs text-muted-foreground text-center">
                        Tenho um pet
                      </span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setUserType("passeador")}
                      className={cn(
                        "flex flex-col items-center gap-2 p-4 rounded-xl border-2 transition-all",
                        userType === "passeador"
                          ? "border-red-400 bg-primary/5"
                          : "border-border hover:border-red-400"
                      )}
                    >
                      <Footprints className={cn(
                        "w-8 h-8",
                        userType === "passeador" ? "text-red-400" : "text-muted-foreground"
                      )} />
                      <span className={cn(
                        "font-medium text-sm",
                        userType === "passeador" ? "text-red-400" : "text-muted-foreground"
                      )}>
                        Passeador
                      </span>
                      <span className="text-xs text-muted-foreground text-center">
                        Quero passear pets
                      </span>
                    </button>
                  </div>
                </div>

                {error && (
                  <p className="text-sm text-destructive text-center">{error}</p>
                )}

                <Button
                  type="submit"
                  className="w-full h-12 text-base font-medium bg-red-400 hover:bg-red-500"
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <div className="flex items-center gap-2">
                      <div className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                      Criando conta...
                    </div>
                  ) : (
                    "Criar conta"
                  )}
                </Button>
              </form>

              <p className="mt-8 text-center text-sm text-muted-foreground">
                Já tem uma conta?{" "}
                <Link
                  href="/"
                  className="text-red-400 font-medium hover:text-red-500"
                >
                  Entrar
                </Link>
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}

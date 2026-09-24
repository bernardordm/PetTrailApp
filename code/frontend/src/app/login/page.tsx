"use client"

import { useState } from "react"
import { useRouter } from "next/navigation"
import Link from "next/link"
import Image from "next/image"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { FieldGroup, Field, FieldLabel } from "@/components/ui/field"
import { PawPrint, Eye, EyeOff } from "lucide-react"
import { login } from "@/shared/services/auth.service"

export default function LoginPage() {
  const router = useRouter()
  const [showPassword, setShowPassword] = useState(false)
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState("")

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError("")

    try {
      const data = await login(email, password)
      document.cookie = `token=${data.accessToken}; path=/; max-age=${7 * 24 * 60 * 60}`
      localStorage.setItem("token", data.accessToken)
      localStorage.setItem("user", JSON.stringify({ identifier: data.identifier, name: data.name, email: data.email, role: data.role }))
      router.push("/dashboard")
    } catch (err) {
      setError(err instanceof Error ? err.message : "Erro ao fazer login")
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
        {/* Overlay com logo */}
        <div className="absolute inset-0 bg-linear-to-t from-black/60 via-transparent to-transparent" />
        <div className="absolute top-8 left-8 flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-red-400 flex items-center justify-center">
            <PawPrint className="w-6 h-6 text-primary-foreground" />
          </div>
          <span className="text-xl font-semibold text-white">PetTrail</span>
        </div>
        <div className="absolute bottom-8 left-8 right-8">
          <p className="text-white/90 text-lg font-medium">
            Passeios seguros e acompanhamento em tempo real para seu melhor amigo.
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
                Bem-vindo de volta
              </CardTitle>
              <CardDescription className="text-muted-foreground text-base">
                Entre para acompanhar os passeios do seu pet
              </CardDescription>
            </CardHeader>
            <CardContent className="px-0">
              <form onSubmit={handleLogin} className="space-y-6">
                <FieldGroup>
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
                        placeholder="Digite sua senha"
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

                {error && (
                  <p className="text-sm text-destructive text-center">{error}</p>
                )}

                <Button
                  type="submit"
                  className="w-full h-12 text-base font-medium bg-red-400 hover:bg-red-500"
                  disabled={isLoading}
                >
                  {isLoading ? (
                    <div className="flex items-center gap-2 ">
                      <div className="w-5 h-5 border-2 border-primary-foreground/30 border-t-primary-foreground rounded-full animate-spin" />
                      Entrando...
                    </div>
                  ) : (
                    "Entrar"
                  )}
                </Button>
              </form>

              <p className="mt-8 text-center text-sm text-muted-foreground">
                Não tem uma conta?{" "}
                <Link
                  href="/cadastro"
                  className="text-red-400 font-medium hover:underline"
                >
                  Criar conta
                </Link>
              </p>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}

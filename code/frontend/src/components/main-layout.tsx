"use client"

import { useState, useEffect } from "react"
import { AppSidebar } from "@/components/app-sidebar"
import { Button } from "@/components/ui/button"
import { Menu, Bell } from "lucide-react"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { getTutorPhotoUrl } from "@/shared/services/tutors.service"
import { getWalkerPhotoUrl } from "@/shared/services/walkers.service"

export function MainLayout({ children }: { children: React.ReactNode }) {
  const [sidebarOpen, setSidebarOpen] = useState(true)
  const [photoUrl, setPhotoUrl] = useState<string | null>(null)
  const [userInitials, setUserInitials] = useState("JP")

  useEffect(() => {
    const raw = localStorage.getItem("user")
    if (!raw) return
    const user = JSON.parse(raw) as { identifier: string; role: string; name?: string }
    if (user.name) {
      setUserInitials(user.name.slice(0, 2).toUpperCase())
    }
    const url =
      user.role === "tutor"
        ? getTutorPhotoUrl(user.identifier)
        : getWalkerPhotoUrl(user.identifier)
    setPhotoUrl(url)
  }, [])

  return (
    <div className="flex min-h-screen bg-background">
      <AppSidebar isOpen={sidebarOpen} onToggle={() => setSidebarOpen(!sidebarOpen)} />

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-border bg-card px-4 lg:px-6">
          <div className="flex items-center gap-4">
            <Button
              variant="ghost"
              size="icon"
              className="lg:hidden"
              onClick={() => setSidebarOpen(!sidebarOpen)}
              aria-label="Abrir menu"
            >
              <Menu className="h-5 w-5" />
            </Button>
          </div>

          <div className="flex items-center gap-3">
            <Avatar className="h-9 w-9 border-2 border-primary/20">
              <AvatarImage src={photoUrl ?? undefined} alt="Foto de perfil" className="object-cover" />
              <AvatarFallback className="bg-primary text-sm text-primary-foreground">
                {userInitials}
              </AvatarFallback>
            </Avatar>
          </div>
        </header>

        <main className="flex-1 overflow-auto p-4 lg:p-6">{children}</main>
      </div>
    </div>
  )
}

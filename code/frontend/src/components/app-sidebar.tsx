"use client"

import Link from "next/link"
import { useEffect, useState } from "react"
import { usePathname, useRouter } from "next/navigation"
import { cn } from "@/shared/lib/utils"
import {
  Home,
  User,
  PawPrint,
  BarChart3,
  LogOut,
  ChevronLeft,
  Route,
} from "lucide-react"
import { Button } from "@/components/ui/button"

const navItems = [
  {
    title: "Home",
    href: "/dashboard",
    icon: Home,
    roles: ["tutor", "walker"],
  },
  {
    title: "Perfil",
    href: "/perfil",
    icon: User,
    roles: ["tutor", "walker"],
  },
  {
    title: "Pets",
    href: "/pets",
    icon: PawPrint,
    roles: ["tutor"],
  },
  {
    title: "Passeios",
    href: "/tours",
    icon: Route,
    roles: ["tutor", "walker"],
  },
  {
    title: "Relatórios",
    href: "/relatorios",
    icon: BarChart3,
    roles: ["walker"],
  },
]

interface AppSidebarProps {
  isOpen: boolean
  onToggle: () => void
}

export function AppSidebar({ isOpen, onToggle }: AppSidebarProps) {
  const pathname = usePathname()
  const router = useRouter()
  const [userRole, setUserRole] = useState<string | null>(null)

  useEffect(() => {
    try {
      const raw = localStorage.getItem("user")
      if (raw) {
        const parsed = JSON.parse(raw) as { role?: string }
        setUserRole(parsed.role ?? null)
      }
    } catch {
      // ignore
    }
  }, [])

  function handleLogout() {
    localStorage.removeItem("token")
    localStorage.removeItem("user")
    document.cookie = "token=; path=/; max-age=0"
    router.push("/login")
  }

  return (
    <>
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-foreground/20 backdrop-blur-sm lg:hidden"
          onClick={onToggle}
        />
      )}

      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 flex flex-col bg-red-400 transition-all duration-300 ease-in-out",
          isOpen ? "w-64" : "w-0 lg:w-20",
          "lg:sticky lg:top-0 lg:h-screen"
        )}
      >
        <div
          className={cn(
            "flex h-full flex-col overflow-y-auto overflow-x-hidden",
            isOpen ? "w-64" : "w-0 lg:w-20"
          )}
        >
          <div className="flex items-center gap-3 border-b border-red-300 p-5">
            <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white">
              <PawPrint className="h-5 w-5 text-red-400" />
            </div>
            <span
              className={cn(
                "whitespace-nowrap text-xl font-semibold text-white transition-opacity duration-200",
                isOpen ? "opacity-100" : "opacity-0 lg:hidden"
              )}
            >
              PetTrail
            </span>
          </div>

          <nav className="flex-1 space-y-1 p-3">
            {navItems
              .filter((item) => !userRole || item.roles.includes(userRole))
              .map((item) => {
                const isActive =
                  pathname === item.href ||
                  (item.href !== "/dashboard" && pathname.startsWith(`${item.href}/`))
                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    className={cn(
                      "flex items-center gap-3 rounded-xl px-4 py-3 transition-all duration-200",
                      isActive
                        ? "bg-white text-red-400"
                        : "text-white/80 hover:bg-white/10 hover:text-white"
                    )}
                    aria-current={isActive ? "page" : undefined}
                  >
                    <item.icon className="h-5 w-5 shrink-0" />
                    <span
                      className={cn(
                        "whitespace-nowrap font-medium transition-opacity duration-200",
                        isOpen ? "opacity-100" : "opacity-0 lg:hidden"
                      )}
                    >
                      {item.title}
                    </span>
                  </Link>
                )
              })}
          </nav>

          <div className="mt-auto border-t border-red-300 p-3">
            <Button
              variant="ghost"
              onClick={handleLogout}
              className={cn(
                "w-full justify-start text-white/80 hover:bg-white/10 hover:text-white",
                !isOpen && "lg:justify-center lg:px-0"
              )}
            >
              <LogOut className="h-5 w-5 shrink-0" />
              <span
                className={cn(
                  "ml-3 whitespace-nowrap transition-opacity duration-200",
                  isOpen ? "opacity-100" : "opacity-0 lg:hidden"
                )}
              >
                Sair
              </span>
            </Button>
          </div>
        </div>

        <button
          type="button"
          onClick={onToggle}
          className="absolute top-20 -right-3 hidden h-6 w-6 items-center justify-center rounded-full bg-white text-red-400 shadow-lg transition-transform hover:scale-110 lg:flex"
          aria-label={isOpen ? "Recolher menu" : "Expandir menu"}
        >
          <ChevronLeft
            className={cn("h-4 w-4 transition-transform duration-200", !isOpen && "rotate-180")}
          />
        </button>
      </aside>
    </>
  )
}

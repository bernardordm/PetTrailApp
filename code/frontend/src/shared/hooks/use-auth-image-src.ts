import { useEffect, useState } from 'react'

export function useAuthImageSrc(url: string | undefined): string | undefined {
  const [src, setSrc] = useState<string | undefined>()

  useEffect(() => {
    if (!url) {
      setSrc(undefined)
      return
    }

    let objectUrl: string | undefined
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') : null

    fetch(url, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    })
      .then((res) => {
        if (!res.ok) throw new Error()
        return res.blob()
      })
      .then((blob) => {
        objectUrl = URL.createObjectURL(blob)
        setSrc(objectUrl)
      })
      .catch(() => setSrc(undefined))

    return () => {
      if (objectUrl) URL.revokeObjectURL(objectUrl)
    }
  }, [url])

  return src
}

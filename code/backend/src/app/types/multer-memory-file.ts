/** File from multer `memoryStorage()` — fields used by our photo upload handlers. */
export interface MulterMemoryFile {
  buffer: Buffer;
  mimetype: string;
  size: number;
}

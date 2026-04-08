import path from 'path';

export function safeJoin(root, targetPath) {
  const resolvedRoot = path.resolve(root);
  const resolved = path.resolve(resolvedRoot, targetPath);
  if (!resolved.startsWith(resolvedRoot + path.sep) && resolved !== resolvedRoot) {
    throw new Error('Invalid path');
  }
  return resolved;
}

export function sanitizeUploadPath(filename) {
  if (!filename) return '';
  const normalized = filename.replace(/\\/g, '/').replace(/^\/+/, '');
  const parts = normalized.split('/').filter((part) => part && part !== '.' && part !== '..');
  return parts.join('/');
}

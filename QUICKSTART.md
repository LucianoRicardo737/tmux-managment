# Inicio Rápido - tmux Session Switcher

## Instalación en 3 pasos

### 1. Instalar fzf (opcional pero recomendado)
```bash
sudo apt install fzf  # Ubuntu/Debian
```

### 2. Ejecutar el instalador
```bash
chmod +x install.sh
./install.sh
```

### 3. ¡Listo! Usa Alt+s dentro de tmux

## Atajos de teclado

| Tecla | Función |
|-------|---------|
| `Alt+s` | Abrir selector de sesiones |
| `Alt+n` | Siguiente sesión |
| `Alt+p` | Sesión anterior |

## Probar con datos de demo

```bash
# Desde dentro de tmux
./demo.sh

# Ahora presiona Alt+s para ver las sesiones
```

## Uso del selector

1. Presiona `Alt+s`
2. Navega con flechas ↑/↓
3. Presiona `Enter` para cambiar
4. `Esc` para cancelar

**Atajos dentro del selector:**
- `Ctrl+x` - Eliminar sesión
- `Ctrl+r` - Recargar lista

## Instalación manual

Si prefieres no usar el instalador:

```bash
# 1. Copiar script
mkdir -p ~/.local/bin
cp tmux-session-switcher.sh ~/.local/bin/
chmod +x ~/.local/bin/tmux-session-switcher.sh

# 2. Agregar a ~/.tmux.conf
echo 'bind-key -n M-s run-shell "tmux neww ~/.local/bin/tmux-session-switcher.sh fzf"' >> ~/.tmux.conf

# 3. Recargar configuración
tmux source-file ~/.tmux.conf
```

## Problemas comunes

### Alt+s no funciona
Usa `Ctrl+b` luego `s` en su lugar. Agrega esta línea a tu `~/.tmux.conf`:
```bash
bind-key s run-shell "tmux neww ~/.local/bin/tmux-session-switcher.sh fzf"
```

### fzf no está instalado
El script usará el menú nativo de tmux automáticamente.

### El script no se encuentra
Verifica la ruta en tu `~/.tmux.conf`. Debe apuntar a donde copiaste el script.

## Más información

Lee el archivo `README.md` para documentación completa.

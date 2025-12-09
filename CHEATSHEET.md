# tmux Session Switcher v2.0 - Cheat Sheet

Referencia rápida de todos los comandos, atajos y funcionalidades.

## 🎹 Keybindings (Atajos de Teclado)

### Navegación Principal

| Atajo | Acción | Descripción |
|-------|--------|-------------|
| `Alt+m` | Session Manager | **RECOMENDADO** - Menú completo con ventanas jerárquicas |
| `Alt+a` | **Hierarchical** | **RECOMENDADO** - FZF con sesiones + ventanas navegables |
| `Alt+s` | FZF Selector | Selector completo con fzf y preview |
| `Alt+d` | Search Directories | Buscar directorios y crear sesiones |
| `Alt+n` | Next Session | Cambiar a siguiente sesión |
| `Alt+p` | Previous Session | Cambiar a sesión anterior |
| `Prefix` `a` | Popup (Alt) | Popup alternativo sin Alt |
| `Prefix` `s` | FZF (Alt) | FZF alternativo sin Alt |

### Session Commands

| Atajo | Acción | Descripción |
|-------|--------|-------------|
| `Ctrl+b` `w` | Commands Menu | Menú de comandos configurables |
| `Alt+h` | Quick Command | Comando rápido (ejemplo: htop) |
| `Alt+g` | Git Command | Comando git (ejemplo: lazygit) |

### Controles en Hierarchical Switcher (Alt+a) - RECOMENDADO

| Tecla | Acción |
|-------|--------|
| `↑/↓` | Navegar entre sesiones y ventanas |
| `Enter` | Ir a sesión/ventana seleccionada |
| `Ctrl+n` | Nueva sesión |
| `Ctrl+w` | Nueva ventana en sesión seleccionada |
| `Ctrl+x` | Eliminar sesión/ventana |
| `Ctrl+r` | Renombrar sesión/ventana |
| `Ctrl+v` | Split vertical |
| `Ctrl+h` | Split horizontal |
| `Esc` | Cerrar |

### Controles en FZF Selector

| Tecla | Acción |
|-------|--------|
| `↑/↓` | Navegar arriba/abajo |
| `Ctrl+j/k` | Navegar (alternativo) |
| `Enter` | Seleccionar sesión |
| `Ctrl+x` | Eliminar sesión |
| `Ctrl+r` | Recargar lista |
| `Esc` o `Ctrl+c` | Cancelar |

## 💻 Comandos CLI

### Modos de Operación

```bash
# Session Manager (RECOMENDADO - menú completo con ventanas)
tmux-session-switcher.sh manager

# Popup switcher (default)
tmux-session-switcher.sh popup

# FZF selector con preview
tmux-session-switcher.sh fzf

# Menú nativo de tmux
tmux-session-switcher.sh menu

# Ciclar sesiones
tmux-session-switcher.sh next
tmux-session-switcher.sh prev

# Buscar directorios
tmux-session-switcher.sh search

# Crear sesión desde path
tmux-session-switcher.sh ~/projects/my-app
```

### Session Commands

```bash
# Ejecutar comando en ventana (índice 69+)
tmux-session-switcher.sh -s 0

# Ejecutar comando en split vertical
tmux-session-switcher.sh -s 1 --vsplit

# Ejecutar comando en split horizontal
tmux-session-switcher.sh -s 2 --hsplit
```

### Opciones Generales

```bash
# Ver ayuda
tmux-session-switcher.sh --help
tmux-session-switcher.sh -h

# Ver versión
tmux-session-switcher.sh --version
tmux-session-switcher.sh -v
```

## ⚙️ Configuración

### Archivo Principal

**Ubicación**: `~/.config/tmux-sessionizer/tmux-sessionizer.conf`

```bash
# Search paths
TS_SEARCH_PATHS=(~/ ~/projects ~/work)
TS_EXTRA_SEARCH_PATHS=(~/github:3 ~/git:3)
TS_MAX_DEPTH=2

# Session commands
TS_SESSION_COMMANDS=(
    "htop"              # 0
    "nvim ~/notes.md"   # 1
    "python3"           # 2
    "lazygit"           # 3
    "docker ps -a"      # 4
)

# Logging
TS_LOG="file"
TS_LOG_FILE="~/.local/share/tmux-sessionizer/tmux-sessionizer.logs"
```

### Keybindings Personalizados

**Archivo**: `~/.tmux.conf`

```bash
# Básico (recomendado)
bind-key -n M-a run-shell "~/.local/bin/tmux-session-switcher.sh popup"
bind-key -n M-s run-shell "tmux neww ~/.local/bin/tmux-session-switcher.sh fzf"

# Con prefijo (alternativas)
bind-key Space run-shell "~/.local/bin/tmux-session-switcher.sh popup"
bind-key a run-shell "~/.local/bin/tmux-session-switcher.sh popup"

# Menú de comandos
bind-key w display-menu -T "Commands" \
    "Monitor"  0 "run-shell '~/.local/bin/tmux-session-switcher.sh -s 0'" \
    "Notes"    1 "run-shell '~/.local/bin/tmux-session-switcher.sh -s 1 --vsplit'"
```

## 📝 Hydration Scripts

### Script Global

**Ubicación**: `~/.tmux-sessionizer`

```bash
#!/bin/bash
tmux rename-window "editor"
tmux send-keys "nvim ." C-m
tmux new-window -n "shell"
tmux select-window -t 1
```

### Script Por Proyecto

**Ubicación**: `<proyecto>/.tmux-sessionizer`

```bash
#!/bin/bash
tmux rename-window "editor"
tmux send-keys "nvim ." C-m
tmux new-window -n "server"
tmux send-keys "npm run dev" C-m
tmux select-window -t 1
```

**Nota**: Debe ser ejecutable (`chmod +x .tmux-sessionizer`)

## 🎯 Símbolos y Estados

### Indicadores de Sesión

| Símbolo | Color | Significado |
|---------|-------|-------------|
| `●` | Verde | Sesión actual |
| `○` | Cyan | Sesión con clientes conectados |
| ` ` | Blanco | Sesión inactiva |

### Formato de Display

```
[1] ● development (4 ventanas)
[2] ○ frontend (3 ventanas)
[3]   backend (2 ventanas)
```

## 🔍 Búsqueda de Directorios

### Formato de Resultados

```bash
# Sesiones tmux existentes (prefijo [TMUX])
[TMUX] development
[TMUX] frontend

# Directorios encontrados
/home/user/projects/web-app
/home/user/projects/api-server
/home/user/github/dotfiles
```

### Configurar Paths de Búsqueda

```bash
# Paths básicos (depth default)
TS_SEARCH_PATHS=(
    ~/
    ~/projects
)

# Paths con depth personalizado
TS_EXTRA_SEARCH_PATHS=(
    ~/github:3      # Buscar hasta 3 niveles
    ~/.config:2     # Buscar hasta 2 niveles
)

# Depth por defecto
TS_MAX_DEPTH=1
```

## 📋 Workflows Comunes

### Workflow 1: Navegación Rápida (RECOMENDADO)

```bash
# 1. Abrir hierarchical switcher
Alt+a

# 2. Navegar con flechas entre sesiones y ventanas
↑/↓

# 3. Ir a la selección
Enter

# 4. Crear nueva sesión
Ctrl+n → Escribir nombre → Enter

# 5. Crear nueva ventana
Ctrl+w → Escribir nombre → Enter
```

### Workflow 2: Session Manager (Gestión Completa)

```bash
# 1. Abrir Session Manager
Alt+m

# 2. Navegar al submenú de ventanas de una sesión
Seleccionar "└─ ventanas >" de cualquier sesión

# 3. Ver todas las ventanas y cambiar a una
Presionar 1-9 para cambiar a ventana específica

# 4. Crear nueva ventana desde el submenú
Presionar n → Ingresar nombre → Enter

# 5. Crear splits
Presionar h (horizontal) o v (vertical)

# 6. Volver al menú principal
Presionar b

# 7. Acciones principales desde menú principal
n → Nueva sesión
r → Renombrar sesión
k → Eliminar sesión
d → Buscar directorios
```

### Workflow 3: FZF con Preview

```bash
# 1. Abrir FZF
Alt+s

# 2. Navegar con flechas
↑/↓

# 3. Ver preview de ventanas
Panel derecho muestra ventanas

# 4. Seleccionar
Enter

# 5. Eliminar sesiones viejas
Ctrl+x sobre sesión a eliminar
```

### Workflow 4: Comandos Rápidos

```bash
# 1. Abrir menú de comandos
Ctrl+b w

# 2. Seleccionar comando por número
0-4

# 3. O usar atajos directos
Alt+h  # htop
Alt+g  # lazygit
```

### Workflow 5: Proyectos Nuevos

```bash
# 1. Buscar directorio
Alt+d

# 2. Seleccionar proyecto
Navegar con fzf → Enter

# 3. Se crea sesión automáticamente
# 4. Se ejecuta .tmux-sessionizer si existe
# 5. Se cambia a la nueva sesión
```

## 🔧 Troubleshooting Rápido

| Problema | Solución |
|----------|----------|
| Popup no aparece | Verificar tmux 3.2+ con `tmux -V` |
| fzf no funciona | Instalar: `sudo apt install fzf` |
| Alt+Tab capturado por sistema | **Usar Alt+a** o Prefix+Space |
| Ctrl+b no funciona | Usar Alt+a, Alt+s, etc (sin prefix) |
| Alt no responde | Usar Prefix+Space o Prefix+a |
| Directorios no aparecen | Verificar `TS_SEARCH_PATHS` en config |
| Session commands fallan | Verificar `TS_SESSION_COMMANDS` en config |
| Hydration no ejecuta | Hacer script ejecutable: `chmod +x` |

## 📦 Directorios Importantes

```bash
# Script principal
~/.local/bin/tmux-session-switcher.sh

# Configuración
~/.config/tmux-sessionizer/tmux-sessionizer.conf

# Cache de panes
~/.cache/tmux-sessionizer/panes.cache

# Logs
~/.local/share/tmux-sessionizer/tmux-sessionizer.logs

# Hydration scripts
~/.tmux-sessionizer                    # Global
<proyecto>/.tmux-sessionizer           # Por proyecto
```

## 🚀 Tips y Trucos

### Tip 1: Splits Persistentes

Los splits creados con `--vsplit` o `--hsplit` se cachean:

```bash
# Primera vez: crea el split
tmux-session-switcher.sh -s 1 --vsplit

# Siguientes veces: reutiliza el mismo split
tmux-session-switcher.sh -s 1 --vsplit
```

### Tip 2: Logging para Debug

Habilitar logging en la config:

```bash
TS_LOG="file"
TS_LOG_FILE="~/.local/share/tmux-sessionizer/debug.log"
```

Luego ver logs:

```bash
tail -f ~/.local/share/tmux-sessionizer/debug.log
```

### Tip 3: Alias Útiles

Agregar a `~/.bashrc` o `~/.zshrc`:

```bash
alias tsp='tmux-session-switcher.sh popup'
alias tsf='tmux-session-switcher.sh fzf'
alias tss='tmux-session-switcher.sh search'
alias tsn='tmux-session-switcher.sh next'
```

### Tip 4: Hydration Condicional

Script con lógica condicional:

```bash
#!/bin/bash
# .tmux-sessionizer

# Si existe package.json, es proyecto Node
if [ -f "package.json" ]; then
    tmux rename-window "editor"
    tmux send-keys "nvim ." C-m
    tmux new-window -n "server"
    tmux send-keys "npm run dev" C-m
fi

# Si existe Makefile, es proyecto C/C++
if [ -f "Makefile" ]; then
    tmux rename-window "editor"
    tmux send-keys "nvim ." C-m
    tmux new-window -n "build"
    tmux send-keys "make watch" C-m
fi

tmux select-window -t 1
```

### Tip 5: Menú Personalizado

Crear menú custom en tmux.conf:

```bash
bind-key m display-menu -T "My Workflows" \
    "Web Dev"     w "run-shell 'tmux-session-switcher.sh ~/projects/web'" \
    "Backend"     b "run-shell 'tmux-session-switcher.sh ~/projects/api'" \
    "Monitor"     m "run-shell 'tmux-session-switcher.sh -s 0'" \
    "Git"         g "run-shell 'tmux-session-switcher.sh -s 3'"
```

## 📚 Referencias Rápidas

- **README.md** - Documentación completa
- **tmux.conf.example** - Ejemplos de configuración
- **config.example** - Ejemplos de configuración avanzada
- **QUICKSTART.md** - Guía rápida de inicio

---

**Versión**: 2.1.0
**Última actualización**: 2025-12-09

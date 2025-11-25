# tmux Session Switcher v2.0

Switcher visual de sesiones tmux estilo Alt+Tab con integración completa de tmux-sessionizer para gestión avanzada de sesiones, búsqueda de directorios y comandos configurables.

## ✨ Características Principales

### 🚀 Modo Manager (Nuevo! - Recomendado)
- **Menú nativo completo** con navegación jerárquica
- **Ver ventanas dentro de cada sesión** en submenú
- **Crear, renombrar, eliminar** sesiones desde el menú
- **Crear ventanas y splits** sin salir del manager
- **Cambiar entre ventanas** de una sesión específica
- Indicadores visuales (● sesión actual, ○ sesión attached)
- 100% nativo tmux - sin dependencias

### 🎯 Modo Popup
- **Interfaz estilo Alt+Tab** con overlay centrado
- **Selección rápida 1-9** sin navegación adicional
- Búsqueda de directorios integrada (presiona `D`)
- Indicadores visuales de estado
- No requiere fzf

### 🔍 Modo FZF
- Interfaz interactiva con preview de ventanas
- Eliminar sesiones con `Ctrl+x`
- Recargar lista con `Ctrl+r`
- Búsqueda fuzzy y navegación con flechas

### 📁 Búsqueda de Directorios (tmux-sessionizer)
- Busca automáticamente en paths configurados
- Crea sesiones nuevas desde directorios
- Soporte para hydration scripts
- Integración con proyectos existentes

### ⚙️ Comandos de Sesión Configurables
- Ejecuta comandos predefinidos en ventanas o splits
- Splits cacheados y reutilizables
- Configuración flexible por archivo

### 🔄 Navegación Rápida
- Ciclar entre sesiones (next/prev)
- Menú nativo como fallback
- Múltiples keybindings configurables

## 📦 Instalación

### Instalación Automática (Recomendado)

```bash
./install.sh
```

Esto hará:
- ✅ Instalar el script en `~/.local/bin/`
- ✅ Crear directorios de configuración y cache
- ✅ Copiar archivo de configuración ejemplo
- ✅ Agregar keybindings a `~/.tmux.conf`
- ✅ Recargar configuración de tmux automáticamente

### Instalación Manual

#### 1. Copiar el script

```bash
mkdir -p ~/.local/bin
cp tmux-session-switcher.sh ~/.local/bin/
chmod +x ~/.local/bin/tmux-session-switcher.sh
```

#### 2. Crear directorios

```bash
mkdir -p ~/.config/tmux-sessionizer
mkdir -p ~/.cache/tmux-sessionizer
mkdir -p ~/.local/share/tmux-sessionizer
```

#### 3. Copiar configuración

```bash
cp config.example ~/.config/tmux-sessionizer/tmux-sessionizer.conf
```

#### 4. Configurar tmux

Agrega estos keybindings a tu `~/.tmux.conf`:

```bash
# Alt+m - Session Manager (RECOMENDADO - menú completo con ventanas)
bind-key -n M-m run-shell "~/.local/bin/tmux-session-switcher.sh show-menu '#{client_name}'"

# Alt+a - Popup switcher (estilo Alt-tab, 'a' = alt-tab alternative)
# NOTA: Alt+Tab es capturado por el sistema, usa Alt+a
bind-key -n M-a run-shell "~/.local/bin/tmux-session-switcher.sh popup"

# Alt+s - Selector FZF completo
bind-key -n M-s run-shell "tmux neww ~/.local/bin/tmux-session-switcher.sh fzf"

# Alt+d - Buscar directorios y crear sesiones
bind-key -n M-d run-shell "~/.local/bin/tmux-session-switcher.sh search"

# Alt+n/p - Ciclar sesiones
bind-key -n M-n run-shell "~/.local/bin/tmux-session-switcher.sh next"
bind-key -n M-p run-shell "~/.local/bin/tmux-session-switcher.sh prev"

# Alternativas con prefix:
bind-key a run-shell "~/.local/bin/tmux-session-switcher.sh popup"         # Prefix + a
```

#### 5. Recargar tmux

```bash
tmux source-file ~/.tmux.conf
```

## 🚀 Uso

### Session Manager (Modo Recomendado)

**Atajo**: `Alt+a`

Popup interactivo con gestión completa:

```
╔══════════════════════════════════════════════════════════════╗
║              SESSION MANAGER                                 ║
╠══════════════════════════════════════════════════════════════╣

  [1] ● development (4w)
       ✓ editor
         server
         logs

  [2] ○ frontend (3w)
       ✓ code
         terminal
         docker

  [3]   backend (2w)
       ✓ api
         database

╠══════════════════════════════════════════════════════════════╣
  [D] Buscar dirs   [X] Eliminar   [N] Nueva   [Q] Salir
╚══════════════════════════════════════════════════════════════╝

Selección: _
```

**Controles**:
- `1-9`: Cambiar instantáneamente a esa sesión
- `D`: Buscar directorios y crear nueva sesión
- `X`: Eliminar sesión (muestra lista para seleccionar)
- `N`: Crear nueva sesión (prompt para nombre)
- `Q`: Cerrar el manager

**Submenú de Ventanas**:
Cuando seleccionas "└─ ventanas >" para una sesión:

```
╔═════════════════════════════════════════╗
║        📁 development                   ║
╠═════════════════════════════════════════╣
║ ═══ VENTANAS ═══                        ║
║                                         ║
║ 1  ● editor (2p)                        ║
║ 2    server (1p)                        ║
║ 3    logs (1p)                          ║
║ 4    terminal (1p)                      ║
║                                         ║
║ ═══ ACCIONES ═══                        ║
║ n  + Nueva ventana                      ║
║ r  ⎘ Renombrar ventana                  ║
║ h  ⊟ Split horizontal                   ║
║ v  ⊞ Split vertical                     ║
║ k  ✕ Kill ventana                       ║
║ b  ← Volver                             ║
╚═════════════════════════════════════════╝
```

**Controles de Ventanas**:
- `1-9`: Cambiar a ventana específica (y cambiar a la sesión)
- `n`: Crear nueva ventana en esta sesión
- `r`: Renombrar ventana actual
- `h`: Crear split horizontal
- `v`: Crear split vertical
- `k`: Eliminar ventana (con confirmación)
- `b`: Volver al menú principal

**Símbolos**:
- `●` = Activa/actual
- `○` = Sesión con clientes conectados
- `(Xw)` = Número de ventanas
- `(Xp)` = Número de panes

### Popup Switcher

**Atajo**: `Alt+a` (también: `Prefix` + `Space` o `Prefix` + `a`)

```
╔════════════════════════════════════════════════════════╗
║         TMUX SESSION SWITCHER                          ║
╠════════════════════════════════════════════════════════╣

  [1] ● development (4 ventanas)
  [2] ○ frontend (3 ventanas)
  [3]   backend (2 ventanas)
  [4]   testing (1 ventana)

╠════════════════════════════════════════════════════════╣
  [D] Buscar directorios        [Q] Salir
╚════════════════════════════════════════════════════════╝

Selección: _
```

**Controles**:
- `1-9`: Cambiar instantáneamente a esa sesión
- `D`: Abrir búsqueda de directorios
- `Q` o `Esc`: Cerrar el popup

**Símbolos**:
- `●` = Sesión actual (verde)
- `○` = Sesión con clientes conectados (cyan)
- ` ` = Sesión inactiva

### Selector FZF

**Atajo**: `Alt+s`

Interfaz interactiva con preview:

```
Switch to session:
  ● development (4 windows)
  ○ frontend (3 windows)
    backend (2 windows)
    testing (1 window)

[Preview Panel]
  [1] editor ✓
  [2] server
  [3] logs
  [4] terminal
```

**Controles**:
- `↑/↓` o `Ctrl+j/k`: Navegar
- `Enter`: Seleccionar sesión
- `Ctrl+x`: Eliminar sesión seleccionada
- `Ctrl+r`: Recargar lista
- `Esc` o `Ctrl+c`: Cancelar

### Búsqueda de Directorios

**Atajo**: `Alt+d` o presiona `D` en el popup

Busca en paths configurados y crea sesiones nuevas:

```bash
# Busca automáticamente en:
# - Sesiones tmux existentes ([TMUX] session-name)
# - Directorios en TS_SEARCH_PATHS
# - Directorios en TS_EXTRA_SEARCH_PATHS con depth custom

Select directory:
> [TMUX] development
  /home/user/projects/web-app
  /home/user/projects/api-server
  /home/user/github/dotfiles
```

Al seleccionar un directorio:
1. Se crea una sesión con el nombre del directorio
2. Se ejecuta `.tmux-sessionizer` si existe (hydration)
3. Se cambia automáticamente a la nueva sesión

### Ciclar entre Sesiones

**Atajos**: `Alt+n` (siguiente) / `Alt+p` (anterior)

Cambia a la siguiente/anterior sesión en orden alfabético.

## ⚙️ Configuración

### Archivo de Configuración

**Ubicación**: `~/.config/tmux-sessionizer/tmux-sessionizer.conf`

```bash
# Search paths para directorios
TS_SEARCH_PATHS=(
    ~/
    ~/projects
    ~/work
)

# Search paths adicionales con depth custom
TS_EXTRA_SEARCH_PATHS=(
    ~/github:3
    ~/git:3
    ~/.config:2
)

# Profundidad máxima de búsqueda (default: 1)
TS_MAX_DEPTH=2

# Comandos de sesión configurables
TS_SESSION_COMMANDS=(
    "htop"                    # 0: System monitor
    "nvim ~/notes.md"         # 1: Quick notes
    "python3"                 # 2: Python REPL
    "lazygit"                 # 3: Git TUI
    "docker ps -a"            # 4: Docker status
)

# Logging para debug
# TS_LOG="file"  # o "echo" para stdout
# TS_LOG_FILE="$HOME/.local/share/tmux-sessionizer/tmux-sessionizer.logs"
```

Ver `config.example` para más ejemplos detallados.

### Session Commands (Comandos Configurables)

Los session commands permiten ejecutar comandos predefinidos en ventanas o splits persistentes.

#### Uso Básico

```bash
# Ejecutar comando en ventana (índice 69+)
tmux-session-switcher.sh -s 0

# Ejecutar comando en split vertical (cacheado)
tmux-session-switcher.sh -s 1 --vsplit

# Ejecutar comando en split horizontal (cacheado)
tmux-session-switcher.sh -s 2 --hsplit
```

#### Configurar Keybindings

Agrega a `~/.tmux.conf`:

```bash
# Menú de comandos con Ctrl+b w
bind-key w display-menu -T "Session Commands" \
    "System Monitor"    0 "run-shell '~/.local/bin/tmux-session-switcher.sh -s 0'" \
    "Notes (vsplit)"    1 "run-shell '~/.local/bin/tmux-session-switcher.sh -s 1 --vsplit'" \
    "Python REPL"       2 "run-shell '~/.local/bin/tmux-session-switcher.sh -s 2 --hsplit'" \
    "Git Client"        3 "run-shell '~/.local/bin/tmux-session-switcher.sh -s 3'"

# Atajos directos (opcional)
bind-key -n M-h run-shell "~/.local/bin/tmux-session-switcher.sh -s 0"  # Alt+h: htop
bind-key -n M-g run-shell "~/.local/bin/tmux-session-switcher.sh -s 3"  # Alt+g: git
```

### Hydration Scripts

Los hydration scripts permiten configurar automáticamente sesiones nuevas.

#### Script Global

Crea `~/.tmux-sessionizer`:

```bash
#!/bin/bash
# Se ejecuta al crear cualquier sesión desde un directorio

tmux rename-window "editor"
tmux send-keys "nvim ." C-m
tmux new-window -n "shell"
tmux select-window -t 1
```

#### Script Por Proyecto

Crea `.tmux-sessionizer` en el directorio del proyecto:

```bash
#!/bin/bash
# Se ejecuta solo para este proyecto

tmux rename-window "editor"
tmux send-keys "nvim ." C-m

tmux new-window -n "server"
tmux send-keys "npm run dev" C-m

tmux new-window -n "logs"
tmux send-keys "tail -f logs/development.log" C-m

tmux new-window -n "git"
tmux send-keys "lazygit" C-m

tmux select-window -t 1
```

**Nota**: Los scripts por proyecto tienen prioridad sobre el global.

## 📚 Referencia de Comandos

### Modos

```bash
tmux-session-switcher.sh [MODE] [OPTIONS]
```

| Modo | Descripción |
|------|-------------|
| `popup` | Popup overlay con selección numérica 1-9 (default) |
| `fzf` | Selector interactivo con fzf y preview |
| `menu` | Menú nativo de tmux |
| `next` | Cambiar a siguiente sesión |
| `prev` | Cambiar a sesión anterior |
| `search` | Buscar directorios y crear sesión |

### Options (Session Commands)

| Opción | Descripción |
|--------|-------------|
| `-s <idx>` | Ejecutar `TS_SESSION_COMMANDS[idx]` |
| `--vsplit` | Crear/usar split vertical (con `-s`) |
| `--hsplit` | Crear/usar split horizontal (con `-s`) |
| `-h, --help` | Mostrar ayuda |
| `-v, --version` | Mostrar versión |

### Ejemplos

```bash
# Popup switcher
tmux-session-switcher.sh popup

# FZF selector
tmux-session-switcher.sh fzf

# Búsqueda de directorios
tmux-session-switcher.sh search

# Ejecutar comando en ventana
tmux-session-switcher.sh -s 0

# Ejecutar comando en split vertical
tmux-session-switcher.sh -s 1 --vsplit

# Crear sesión desde path específico
tmux-session-switcher.sh ~/projects/my-app
```

## 🔧 Troubleshooting

### El popup no aparece

- Requiere tmux 3.2+
- Verifica: `tmux -V`
- Actualiza tmux si es necesario

### fzf no funciona

- Instala fzf: `sudo apt install fzf` (Ubuntu/Debian)
- O usa el modo popup que no requiere fzf

### Alt+Tab/Ctrl no responde

- **Alt+Tab es capturado por el sistema operativo** (window manager)
- **Usa Alt+a en su lugar** (recomendado)
- O usa `Prefix` + `Space` (Ctrl+b luego Space)
- O usa `Prefix` + `a` (Ctrl+b luego a)
- Alt+s (FZF mode) suele funcionar sin problemas

### Los directorios no aparecen en búsqueda

- Verifica `TS_SEARCH_PATHS` en el archivo de configuración
- Los directorios deben existir
- Revisa permisos de lectura

### Los session commands no funcionan

- Verifica `TS_SESSION_COMMANDS` en el archivo de configuración
- Asegúrate de que los índices sean válidos
- Revisa logs si está habilitado

## 🎨 Personalización

### Cambiar Keybindings

Edita `~/.tmux.conf` y modifica los keybindings:

```bash
# Usar Alt+w en lugar de Alt+a
bind-key -n M-w run-shell "~/.local/bin/tmux-session-switcher.sh popup"

# Usar F12 para búsqueda
bind-key -n F12 run-shell "~/.local/bin/tmux-session-switcher.sh search"

# Usar Alt+` (backtick) para popup
bind-key -n 'M-`' run-shell "~/.local/bin/tmux-session-switcher.sh popup"

# Usar Prefix + Tab
bind-key Tab run-shell "~/.local/bin/tmux-session-switcher.sh popup"
```

### Personalizar Search Paths

Edita `~/.config/tmux-sessionizer/tmux-sessionizer.conf`:

```bash
# Buscar solo en proyectos específicos
TS_SEARCH_PATHS=(
    ~/projects
    ~/work
)

# Agregar paths con depth custom
TS_EXTRA_SEARCH_PATHS=(
    ~/github:3        # Buscar 3 niveles de profundidad
    ~/.config:2       # Buscar 2 niveles
)

# Cambiar depth por defecto
TS_MAX_DEPTH=3
```

### Agregar Session Commands

Edita `~/.config/tmux-sessionizer/tmux-sessionizer.conf`:

```bash
TS_SESSION_COMMANDS=(
    "htop"                              # System monitor
    "nvim ~/TODO.md"                    # Quick notes
    "lazygit"                           # Git TUI
    "docker logs -f \$(docker ps -q | head -1)"  # Docker logs
    "k9s"                               # Kubernetes TUI
    "python3 -m http.server 8000"       # Local server
)
```

## 📖 Documentación Adicional

- **QUICKSTART.md** - Guía rápida de inicio
- **CHEATSHEET.md** - Referencia rápida de comandos
- **tmux.conf.example** - Ejemplos de configuración
- **config.example** - Ejemplos de configuración avanzada

## 🤝 Contribuir

Las contribuciones son bienvenidas! Por favor:

1. Reporta bugs en Issues
2. Propón nuevas funcionalidades
3. Envía pull requests con mejoras

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la licencia MIT.

## 🙏 Agradecimientos

- Inspirado por [tmux-sessionizer](https://github.com/ThePrimeagen/.dotfiles/blob/master/bin/.local/scripts/tmux-sessionizer) de ThePrimeagen
- Interfaz fzf inspirada en [t-smart-tmux-session-manager](https://github.com/joshmedeski/t-smart-tmux-session-manager)

## 📊 Características vs Otros Proyectos

| Característica | tmux-session-switcher v2 | tmux-sessionizer | t-smart |
|----------------|--------------------------|------------------|---------|
| Popup overlay visual | ✅ | ❌ | ✅ |
| Selección numérica 1-9 | ✅ | ❌ | ❌ |
| FZF con preview | ✅ | ❌ | ✅ |
| Búsqueda de directorios | ✅ | ✅ | ✅ |
| Hydration scripts | ✅ | ✅ | ❌ |
| Session commands | ✅ | ✅ | ❌ |
| Split management | ✅ | ✅ | ❌ |
| Sin dependencias (popup) | ✅ | ❌ | ❌ |
| Múltiples modos | ✅ | ❌ | ✅ |

---

**Versión**: 2.0.0
**Autor**: Claude Code
**Repositorio**: [github.com/your-repo/tmux-session-switcher](https://github.com)

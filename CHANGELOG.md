# Changelog - tmux-session-switcher

## [2025-11-17] - Mejoras Hierarchical Mode

### Mejora 1: Cursor inicia en sesión actual
- **Problema:** Al abrir Alt+a, el cursor iniciaba en la primera sesión alfabéticamente
- **Solución:** La lista se reordena para mostrar la sesión actual primero, luego el resto alfabéticamente
- **Beneficio:** Navegación más rápida, el cursor ya está en tu sesión actual

### Mejora 2: Ventanas ahora se muestran correctamente
- **Problema:** En algunos casos, las ventanas no aparecían en el selector hierarchical
- **Solución:** Agregada validación para evitar procesar listas vacías de ventanas
- **Beneficio:** Siempre verás las ventanas de cada sesión indentadas debajo

### Uso:
```bash
# Presiona Alt+a para abrir el selector hierarchical
# Ahora verás:
#   ● tu-sesion-actual (3w)      <- Cursor aquí
#       ✓ [0] ventana1 (1p)
#         [1] ventana2 (2p)
#         [2] ventana3 (1p)
#   ○ otra-sesion (2w)
#       ✓ [0] editor (1p)
#         [1] shell (1p)
```

### Commits:
- `8acfff4` - feat: estado funcional antes de mejoras hierarchical
- `efaec97` - feat: mejoras hierarchical mode

### Archivos modificados:
- `tmux-session-switcher.sh` (líneas 289-334)

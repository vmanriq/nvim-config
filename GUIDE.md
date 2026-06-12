# Guía: Funcionalidades nuevas (mayo 2026)

Resumen práctico de los 6 cambios añadidos al setup. Leader = `<Space>`.

---

## 1. Octo — PR Review desde Neovim

Revisar PRs de GitHub sin salir del editor: comentarios inline, threads, approve/request-changes.

**Setup inicial (una vez)**:
```bash
gh auth status   # si falla → gh auth login
```

### Listados y filtros

Estos atajos cubren los casos comunes de review de PRs del equipo. Estos atajos cubren los casos comunes sin escribir queries a mano:

| Atajo          | Acción                                                |
| -------------- | ----------------------------------------------------- |
| `<leader>opl`  | Listar **todos** los PRs abiertos del repo            |
| `<leader>opR`  | PRs donde **te pidieron review** (`reviewer=@me`)    |
| `<leader>opa`  | PRs **asignados a ti** (`assignee=@me`)              |
| `<leader>opm`  | PRs creados **por ti** (`author=@me`)                |
| `<leader>opu`  | PRs por **autor** (te pregunta el username)          |
| `<leader>oS`   | Búsqueda libre con sintaxis de GitHub                 |
| `<leader>oi`   | Listar issues                                         |

> **Tip EM**: `<leader>opR` es probablemente el que más vas a usar — muestra solo PRs donde tu review es bloqueante.

**Filtros avanzados ad-hoc** (escribe a mano):
```vim
:Octo pr list state=open base=master                  " contra master
:Octo pr list label=urgent                            " por label
:Octo pr list author=<username> state=merged          " mergeados de un autor
:Octo pr list reviewer=@me state=open is:ready-for-review
:Octo search is:pr is:open team-review-requested:@me  " PRs pedidos a tu equipo
```

### Acciones sobre un PR

| Atajo          | Acción                                                |
| -------------- | ----------------------------------------------------- |
| `<leader>opr`  | Iniciar review (abre diff side-by-side)               |
| `<leader>ops`  | Submit review (approve/comment/request changes)       |
| `<leader>orr`  | Resume review en progreso                             |
| `<leader>ord`  | Descartar review en curso                             |
| `<leader>opc`  | Checkout local del PR                                 |
| `<leader>opd`  | Ver diff completo del PR                              |
| `<leader>opb`  | Abrir PR en navegador                                 |
| `<leader>oc`   | Añadir comentario al thread actual (no review)        |

### Cómo añadir comentarios sobre líneas (review mode)

Este es el flujo crítico — cómo dejar comentarios línea por línea como en la UI web:

1. **Inicia review**: `<leader>opR` → seleccionas PR → `<leader>opr`.
   - Se abre layout split: panel izquierdo con archivos cambiados, dos columnas con diff (base ← → head).
2. **Navega al lugar a comentar**:
   - `]q` / `[q` → siguiente/anterior archivo en review.
   - `]c` / `[c` → siguiente/anterior hunk dentro del archivo.
   - `<leader>e` → enfocar panel de archivos / `<leader>b` → toggle panel.
3. **Comenta una línea**:
   - Posiciona el cursor en la línea (cualquiera de los dos panes).
   - Pulsa `<space>ca` (= `<leader>ca` dentro del buffer de review).
   - Se abre split inferior con buffer de comentario → escribe → `:w` para guardar el draft.
4. **Comenta un rango de líneas**:
   - Modo visual (`V` o `v`) → selecciona varias líneas.
   - `<space>ca` → comentario asociado al rango seleccionado.
5. **Sugerir un cambio (suggestion block)**:
   - Selecciona en visual el código que quieres reemplazar.
   - `<space>sa` → octo crea automáticamente un bloque ` ```suggestion` con el código original; lo editas con la propuesta.
6. **Navegar comentarios existentes**:
   - `]t` / `[t` → siguiente/anterior thread.
   - Sobre un thread: `<space>ca` añade reply, `<space>cd` borra el comentario propio.
7. **Marcar archivo como "viewed"**:
   - `<leader><space>` (espacio doble) → toggle viewed (tachado en sidebar).
8. **Submit**:
   - `<leader>ops` → elige `approve`, `comment` o `request_changes` → confirma.

**Atajos importantes durante review** (todos buffer-local en panes de review):

| Tecla              | Acción                                |
| ------------------ | ------------------------------------- |
| `<space>ca`        | Add comment / reply en thread         |
| `<space>sa`        | Add suggestion (visual selection)     |
| `<space>cd`        | Delete tu comentario                  |
| `]c` / `[c`        | Next/prev hunk                        |
| `]t` / `[t`        | Next/prev thread (comentario)         |
| `]q` / `[q`        | Next/prev archivo en el review        |
| `[Q` / `]Q`        | Primer/último archivo                 |
| `<leader>e`        | Focus file panel                      |
| `<leader>b`        | Toggle file panel                     |
| `<leader><space>`  | Toggle "viewed" del archivo actual    |
| `gf`               | **Go to file en el repo (full file)** |
| `<C-c>`            | Cerrar tab de review                  |

> Octo sobreescribe `<leader>ca` (code action) solo dentro de buffers de review. Fuera de review, `<leader>ca` sigue siendo code action de LSP.

### Cómo expandir contexto del código alrededor del diff

GitHub web limita el contexto a unas pocas líneas. **En octo no existe ese límite** — usa diffview por debajo, que carga el archivo completo. Los dos panes (base y head) muestran el archivo entero con las diferencias resaltadas.

**Para ver más contexto**:

1. **Scroll directo**: estás viendo el archivo completo. Solo navega con `j`/`k`, `<C-d>`/`<C-u>`, `gg`/`G`, `/buscar`. Las partes no cambiadas también están ahí.
2. **Sincronizar scroll entre panes**: ya viene activo (`scrollbind`). Mueve uno y el otro sigue. Si pierde sincronía: `:syncbind`.
3. **Saltar a la versión real del archivo en tu working copy**: `gf` sobre la línea → abre el archivo del checkout local. Puedes navegar referencias con LSP (`gd`, `gr`) — útil para entender qué llama a la función modificada.
4. **Abrir en una pestaña aparte para análisis profundo**:
   ```vim
   :tabnew
   :e ruta/al/archivo.ts
   ```
   Y usa LSP normal (`gd`, `<leader>ca`, etc.) sobre el archivo completo mientras mantienes el review en otra tab.
5. **Ver historia del archivo**:
   - `:DiffviewFileHistory %` (sobre el archivo abierto) → todos los commits que tocaron ese archivo.
   - `<leader>hb` (gitsigns) → blame de la línea actual.

> **Caso típico**: estás revisando un cambio en `apps/financial-bridge-service/src/handlers/X.ts` y quieres ver dónde se llama esa función. Pulsa `gf` para abrir el archivo real → `gr` (LSP references) → telescope te muestra todos los call sites en el monorepo.

### Comandos útiles adicionales

```vim
:Octo pr ready                  " draft → ready for review
:Octo pr merge squash           " merge con squash (default config)
:Octo pr close                  " cerrar PR
:Octo reaction add thumbs_up    " reacciones en comentario actual
:Octo thread resolve            " resolver thread bajo cursor
:Octo thread unresolve
:Octo label add bug             " añadir label
:Octo assignee add <username>   " asignar
:Octo reviewer add <username>   " pedir review
:Octo card move "In Review"     " mover en project board
```

---

## 2. vtsls — Reemplazo de ts_ls

LSP de TypeScript más rápido que `ts_ls` en monorepos grandes. Conserva todos tus keymaps LSP existentes (`gd`, `gS`, `<leader>ca`, etc.).

**Instalar (una vez)**:
```vim
:MasonInstall vtsls
```

**Lo que cambia**:
- ~30-40% menos latencia en monorepos grandes.
- `updateImportsOnFileMove` activo: si renombras un archivo, los imports se actualizan automáticamente (tip: combina con oil.nvim para mover archivos en monorepo NX).
- `gS` (go to source definition) sigue funcionando — útil cuando `gd` cae en `.d.ts` y necesitas el `.ts` real.

**Verificar**:
- Abre un `.ts` del monorepo → `:LspInfo` → debería mostrar `vtsls` attached.
- Si dice "no client attached", ejecuta `:LspStart vtsls` o `:Mason` para confirmar que está instalado.

**Rollback rápido**: `git diff lua/custom/plugins/lsp.lua` muestra el cambio. Si algo se rompe, `git checkout lua/custom/plugins/lsp.lua`.

---

## 3. Neogit — Magit para Neovim

Staging interactivo, rebase visual y commit UI. Complementa (no reemplaza) gitsigns y diffview.

**Keymaps** (bajo `<leader>g`):

| Atajo         | Acción                  |
| ------------- | ----------------------- |
| `<leader>gg`  | Status (vista principal) |
| `<leader>gc`  | Iniciar commit          |
| `<leader>gp`  | Pull                    |
| `<leader>gP`  | Push                    |
| `<leader>gl`  | Log                     |

**Cuándo usar qué**:
- **gitsigns** (`<leader>hs`, `<leader>hr`, etc.) → operar sobre hunks individuales en el buffer actual.
- **diffview** (`<leader>go`, `<leader>gx`) → comparar ramas / inspeccionar histórico estructurado.
- **neogit** (`<leader>gg`) → vista global del repo, staging multi-archivo, rebase, merge.

**Atajos dentro de Neogit status (`<leader>gg`)**:

| Tecla | Acción                                |
| ----- | ------------------------------------- |
| `s`   | Stage archivo/hunk bajo el cursor     |
| `S`   | Stage todo                            |
| `u`   | Unstage                               |
| `x`   | Discard cambios                       |
| `c c` | Abrir editor de commit                |
| `c a` | Amend last commit                     |
| `r`   | Menú de rebase (interactivo, fixup)   |
| `b b` | Cambiar de branch                     |
| `b c` | Crear branch                          |
| `P p` | Push                                  |
| `F p` | Pull                                  |
| `l l` | Log                                   |
| `Tab` | Expandir/contraer diff de un archivo  |
| `?`   | Ayuda contextual                      |

**Flujo típico (commit selectivo en monorepo)**:
1. `<leader>gg` → ves status con todos los cambios.
2. Navegas a un archivo → `Tab` para ver el diff.
3. En cada hunk → `s` para stage solo ese.
4. `c c` → editor de commit con diff staged visible arriba.
5. Escribe mensaje → `<C-c><C-c>` para confirmar (o `:wq`).

---

## 4. Gitsigns — Blame inline activado

Ahora ves en virtual text al final de cada línea: **autor, tiempo relativo y summary del commit** que la modificó.

Ejemplo:
```
const apiUrl = '...';                    Autor, 3 days ago · feat: add retry
```

**Aparece automáticamente** después de 500ms al posicionar el cursor. No necesita atajo.

**Para ocultarlo temporalmente**:
```vim
:Gitsigns toggle_current_line_blame
```

Ya tenías `<leader>tb` para esto si lo prefieres con keymap.

---

## 5. Snippets CDK

8 snippets para boilerplate AWS CDK. Funcionan en `.ts` y `.tsx` (no necesitas activar nada).

**Cómo usar**: escribe el trigger + `<Tab>` (o `<C-y>` en blink.cmp para aceptar la sugerencia).

| Trigger        | Genera                                                |
| -------------- | ----------------------------------------------------- |
| `cdkstack`     | `Stack` + `StackProps` interface + constructor        |
| `cdkconstruct` | `Construct` + `Props` interface                       |
| `cdklambda`    | `lambda.Function` (NODEJS_20_X, 30s, 512MB)           |
| `cdknodejs`    | `NodejsFunction` con bundling minify + sourcemap      |
| `cdkapi`       | `RestApi` con CORS y stage                            |
| `cdkdyn`       | `dynamodb.Table` con PK/SK + PAY_PER_REQUEST          |
| `cdksqs`       | `Queue` con DLQ y visibility timeout                  |
| `cdks3`        | `Bucket` con encryption + SSL + block public access   |

**Navegación dentro del snippet**: `<Tab>` salta al siguiente placeholder, `<S-Tab>` al anterior.

**Para añadir/editar snippets**: `lua/custom/snippets/typescript.lua`. Cualquier cambio se recarga al reiniciar Neovim (o `:LuaSnipUnlinkCurrent` + reload).

---

## 6. Oil.nvim — Edición de directorios como buffer

Convierte un directorio en un buffer de texto editable: cada línea = un archivo. Edítalo con comandos vim normales.

**Keymaps**:

| Atajo         | Acción                                  |
| ------------- | --------------------------------------- |
| `-`           | Abrir directorio del buffer actual      |
| `<leader>-`   | Igual pero en ventana flotante          |

**Operaciones (en el buffer de oil)**:

| Acción           | Cómo hacerla                                          |
| ---------------- | ----------------------------------------------------- |
| Crear archivo    | Escribir un nombre nuevo en una línea + `:w`          |
| Crear carpeta    | Escribir `nombre/` en una línea + `:w`                |
| Renombrar        | Editar el nombre de la línea + `:w`                   |
| Mover            | `dd` para cortar, `p` en otro oil buffer + `:w`       |
| Borrar           | `dd` (va al trash con `delete_to_trash`) + `:w`       |
| Entrar           | `<CR>` sobre directorio                               |
| Salir            | `-` (sube un nivel)                                   |
| Preview          | `<C-p>`                                               |
| Toggle ocultos   | `g.`                                                  |
| Refresh          | `<C-l>`                                               |
| Abrir en split   | `<C-s>` (vertical) / `<C-h>` (horizontal)             |
| Cerrar oil       | `<C-c>` o `:q`                                        |

**Flujo killer en monorepo NX**: muévete a `apps/some-app/src/` con `-`, edita varios nombres a la vez con `:%s/old/new/g` o macros, y `:w` aplica todos los cambios al filesystem. Combinado con `vtsls` + `updateImportsOnFileMove`, los imports se actualizan automáticamente.

**Coexiste con neo-tree**: oil para edición rápida, neo-tree (`\`) para sidebar visual.

---

## Cheatsheet — todos los atajos nuevos

```
PR Listados (Octo)              PR Review (Octo)
  <leader>opl  todos               <leader>opr  start review
  <leader>opR  reviewer=@me        <leader>ops  submit
  <leader>opa  assignee=@me        <leader>orr  resume review
  <leader>opm  author=@me          <leader>ord  discard review
  <leader>opu  por user (prompt)   <leader>opc  checkout
  <leader>oS   búsqueda libre      <leader>opd  diff
  <leader>oi   issues              <leader>opb  open in browser
                                   <leader>oc   add comment

Review mode (buffer-local)      Git workflow (Neogit)
  <space>ca  comment línea/rango   <leader>gg  status
  <space>sa  suggestion (visual)   <leader>gc  commit
  ]c / [c   next/prev hunk         <leader>gp  pull
  ]t / [t   next/prev thread       <leader>gP  push
  ]q / [q   next/prev archivo      <leader>gl  log
  gf        go to file real
  <leader><space>  toggle viewed  Filesystem (oil)
                                     -          parent dir
Snippets CDK (TS/TSX)               <leader>-  parent dir (float)
  cdkstack   cdklambda
  cdkconstruct cdknodejs          LSP (vtsls — sin cambios)
  cdkapi     cdkdyn                 gd, gS, gi, gt, K, gr
  cdksqs     cdks3                  <leader>ca  code action
                                    <leader>rn  rename
                                    <leader>D / <leader>d  diagnostics
```

---

## Troubleshooting

**`<leader>opl` no muestra nada o pide auth**:
- `gh auth status` → si "not logged in", `gh auth login`.
- `:checkhealth octo` para diagnóstico detallado.

**vtsls no se conecta**:
- `:Mason` → verifica que `vtsls` está instalado (✓ verde).
- `:LspInfo` en un `.ts` → debería listar `vtsls` como cliente activo.
- Si sigue sin conectar: `:LspRestart` o `<leader>rs`.

**Snippets CDK no expanden**:
- En el menú de blink.cmp el snippet debe aparecer marcado como `[Snippet]`.
- Si no aparece: `:LuaSnipListAvailable` debe mostrar `cdkstack`, etc.
- Reload: salir y entrar a Neovim.

**Neogit lento al abrir**:
- Primera ejecución compila/descarga deps; luego es rápido.
- En repos enormes, `:Neogit kind=tab` abre en pestaña aparte (más rápido que split).

**Conflicto de keymap `<leader>o*`**: si añades algo nuevo bajo `<leader>o`, octo usa `op*`, `oc`, `or*`, `oi`. Evita esos prefijos.

---

## 7. AWS SSO — Validar credenciales desde Neovim

Módulo casero (`lua/custom/aws/`), sin plugins. Lee los perfiles de `~/.aws/config`.

| Comando / Atajo       | Acción                                                       |
| --------------------- | ------------------------------------------------------------ |
| `:AwsCheck`           | Valida **todos** los perfiles en paralelo (sts get-caller-identity) |
| `:AwsCheck prod`      | Valida un perfil específico (con autocompletado)             |
| `:AwsLogin [perfil]`  | `aws sso login` en terminal flotante                         |
| `<leader>awc`         | = `:AwsCheck`                                                |
| `<leader>awl`         | = `:AwsLogin` (picker de perfil)                             |

Flujo típico: `<leader>awc` → si un perfil aparece **EXPIRED**, el picker te ofrece
hacer login de inmediato → se abre toggleterm flotante con `aws sso login`, autorizas
en el browser, y listo.

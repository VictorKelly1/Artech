# Bitácora del proyecto

Registro de todo lo que vale la pena contar: decisiones, mediciones, bugs, aprendizajes y trabajo que no se ve en el código.
Se escribe **en el momento**, no al final del mes. Es la materia prima de los reportes, los posts y el README.

## Cómo anotar

Una entrada por cosa, dentro del mes que toque. Formato:

```
### AAAA-MM-DD · [ETIQUETA] Título corto
Qué pasó, en 2–5 líneas.
**Por qué:** la razón (en decisiones) o la causa (en bugs).
**Evidencia:** commit, archivo, número medido, enlace al reporte.
```

Etiquetas:

| Etiqueta | Para qué |
|---|---|
| `[DECISIÓN]` | Elegí A sobre B. Siempre con el porqué y la alternativa descartada. |
| `[MEDICIÓN]` | Un número con su contexto: qué se midió, cómo, en qué entorno, contra qué línea base. |
| `[BUG]` | Un error que costó encontrarlo: síntoma, causa raíz, cómo se detectó (test, sanitizer, profiler). |
| `[APRENDIZAJE]` | Algo que entendí y no sabía: un concepto, una sorpresa, una intuición que resultó falsa. |
| `[INFRA]` | Herramientas, build, CI, entorno. |
| `[PENDIENTE]` | Algo que hay que retomar o documentar mejor. Se tacha (`~~...~~`) al resolverse. |

Reglas:
- Los números sin entorno no valen: anota preset, banderas, governor/boost y si había carga de fondo.
- Los fracasos también cuentan. Una optimización que no mejoró nada, con su explicación, es de lo más valioso para un revisor.
- Si algo merece un documento propio (diseño, reporte), la entrada lo enlaza en lugar de repetirlo.

---

## Mes 0 — Preparación (nov–dic 2026)

### 2026-11-17 · [INFRA] Toolchain y presets
CMake con presets `debug`, `release`, `asan`, `tsan` y `ci`. GoogleTest, Google Benchmark y fmt con FetchContent en versiones fijas. Warnings estrictos (`-Wconversion`, `-Wcast-align`, ...) y `-Werror` en CI.
**Por qué:** la misma configuración en la máquina local y en CI; los sanitizers y warnings detectan errores desde el primer día.
**Evidencia:** `CMakePresets.json`, `cmake/`.

### 2026-11-17 · [BUG] TSan falla con "unexpected memory mapping"
El runtime de ThreadSanitizer de GCC falla al arrancar en kernels recientes por la aleatoriedad de ASLR. Comprobado el 18 nov que pasa igual con GCC 14 (kernel 7.0).
**Por qué:** el runtime espera un layout de memoria que ASLR ya no respeta.
**Evidencia:** solución con `setarch -R` en `artech_add_test` (`tests/CMakeLists.txt`).

### 2026-11-18 · [INFRA] Repositorio en GitHub y CI en verde
CI con tres jobs en paralelo: `ci` (ASan + UBSan + tests), `tsan` (tests) y `release` (solo compila).

### 2026-11-18 · [DECISIÓN] GCC 14 en vez de GCC 13
**Por qué:** soporte más completo de C++23, y es el mismo compilador que usará el Dockerfile del mes 1.

### 2026-11-18 · [DECISIÓN] Archivo ITCH de referencia: 30 dic 2019
`12302019.NASDAQ_ITCH50.gz` (3.5 GB comprimido), de emi.nasdaq.com.
**Por qué:** es el día completo más pequeño disponible; tiene la sesión completa y todos los tipos de mensaje.

---

## Mes 1 — Memoria, contenedores, medición (ene 2027)

## Mes 2 — Order book y matching engine (feb 2027)

## Mes 3 — Optimización (mar 2027)

## Mes 4 — Concurrencia (abr 2027)

## Mes 5 — Networking (may 2027)

## Mes 6 — Cliente y estrategia (jun 2027)

## Mes 7 — Estrategias y benchmarks del sistema (jul 2027)

## Mes 8 — Cierre (ago 2027)

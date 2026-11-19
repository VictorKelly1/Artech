# Plan de desarrollo — Low-Latency Trading Engine & Exchange Simulator

- **Ventana:** 1 de enero – 31 de agosto de 2027 (8 meses), más preparación desde el 17 de noviembre de 2026.
- **Dedicación:** ~32 h/semana (4 h entre semana, 6 h sábado y domingo), unas 1,100 h en total.
- **Objetivo:** aprender lo máximo posible y terminar con un proyecto de portafolio para puestos de HFT / quant dev.
- **Modo de trabajo:** todo el código se escribe a mano. La IA es guía, fuente de información y revisora.

## Decisiones fijas

| Tema | Decisión |
|---|---|
| Lenguaje y compilador | C++23 con GCC |
| Estructuras de datos | Propias (vector, hash map, pools, listas intrusivas) |
| Librerías permitidas | GoogleTest, Google Benchmark, fmt |
| Protocolos | Reales: ITCH 5.0, OUCH, SoupBinTCP, MoldUDP64 (NASDAQ) |
| Tipos de orden | Limit, market, cancel |
| Instrumentos | De 2 a 4 |
| Fuera de alcance | Persistencia / journaling, kernel bypass (solo teoría), GUI de escritorio |
| Estrategias | Profundidad media: lo necesario para demostrar la infraestructura |
| Entregables | Repositorio, documentos de diseño, reportes de benchmarks, posts, demo web pública |
| Portabilidad | Dockerfile (GCC 14) + CMake presets; modo demo sin archivos ITCH |
| Demo pública | Web en VPS con dominio propio: gateway WebSocket en C++ + frontend vibecodeado |

## Principios del plan

1. **Primero un solo hilo, después concurrencia.** El núcleo de un matching engine es single-threaded porque así es determinista; la concurrencia solo conecta las piezas.
2. **Medir desde el mes 1, con contadores de hardware.** Un benchmark que solo dice "es más rápido" no enseña nada; hay que poder explicar por qué (cache misses, branch misses, IPC).
3. **Versión ingenua antes que la optimizada.** La ingenua es oráculo para los tests y línea base para el "antes/después".
4. **Determinismo como regla de arquitectura.** El engine es una función pura: flujo de entrada secuenciado → flujo de salida. Un hash de la salida sirve de test, y el backtesting sale casi gratis.
5. **La lectura va un mes por delante del código** en los temas que parten de cero (concurrencia).

## Demo web pública

Cualquiera puede abrir el dominio, elegir parámetros y lanzar una simulación remota sin descargar nada.

```
[ engine C++ ] ──MoldUDP64──► [ gateway web C++ ] ──WebSocket──► navegador
   (sin cambios)                (un cliente más del feed)         (frontend vibecodeado)
```

- **El gateway es un cliente más del feed.** El engine no sabe que la web existe; el hot path no se toca.
- **La web muestra comportamiento, no latencia.** Un VPS tiene vCPUs compartidas y sus números son ruido. Las latencias se muestran como gráficas estáticas de los reportes medidos en la máquina local, con su entorno anotado. La página lo dice explícitamente.
- **Seguridad.** El visitante solo elige parámetros acotados (semilla, duración, instrumento); nunca sube archivos ni mensajes crudos. Límite de simulaciones simultáneas con cola, duración máxima por corrida, contenedor Docker con usuario sin privilegios.
- **Frontend fuera del foco de aprendizaje:** se puede vibecodear. El gateway, el protocolo WebSocket y el despliegue sí se escriben a mano.

## Dos componentes que comparten estructuras

ITCH es un feed *posterior* al matching (add, execute, cancel, delete, replace). Reproducir un archivo ITCH ejercita la **construcción del libro**, no el matching. Por eso hay dos piezas:

- **Book builder guiado por ITCH.** Se reutiliza después como feed handler del cliente.
- **Matching engine** alimentado por flujo de órdenes sintético (o derivado de ITCH, documentado como aproximación).

Ambas comparten las estructuras del order book.

---

## Mes 0 — Preparación (17 nov – 31 dic 2026)

**Leer**
- *Computer Systems: A Programmer's Perspective* (CS:APP), caps. 3, 5 y 6.
- Harris, *Trading and Exchanges*: capítulos de órdenes y estructura de mercado.
- Bakhvalov, *Performance Analysis and Tuning on Modern CPUs* (gratuito): primeros capítulos.
- Por encima: especificaciones de ITCH 5.0, OUCH, SoupBinTCP y MoldUDP64.

**Hacer**
- ~~Toolchain: CMake, GCC con C++23, GoogleTest, Google Benchmark, sanitizers (ASan, UBSan, TSan), `perf`, repositorio con CI.~~ Hecho el 17 nov (presets debug/release/asan/tsan/ci). Primer commit, repo en GitHub y primer CI en verde el 18 nov. Cambio a GCC 14 el 18 nov.
- Descargar un archivo ITCH histórico de NASDAQ (elegido: `12302019.NASDAQ_ITCH50.gz`, 3.5 GB, de emi.nasdaq.com) y escribir un contador de mensajes desechable.
- Registrar la línea base de la máquina: governor, boost, topología de núcleos.

## Mes 1 (enero) — Memoria, contenedores, medición y `perf` básico

**Aprender:** modelo de memoria de C++, allocators, alineación, layout de structs, cachés (CS:APP cap. 9, Drepper), `perf stat`, `perf record`, flamegraphs, lectura de ensamblador.

**Construir**
- Vector de capacidad fija, pool allocator, hash map de open addressing, lista intrusiva.
- Harness de medición: reloj con `rdtsc` e histograma de latencias propio.
- Documento de higiene de benchmarks (governor, boost, SMT, warm-up, varianza entre corridas, costo del timer, entorno registrado en cada reporte).
- Semana 4: parser de ITCH 5.0, como ejercicio de endianness y layout.
- Dockerfile con GCC 14 que compila y corre los tests (unas horas).

**Entregable:** benchmarks contra `std`, explicados con contadores de hardware. Post 1.

## Mes 2 (febrero) — Order book y matching engine en un solo hilo

**Aprender:** microestructura, prioridad precio-tiempo, diseño de libros reales (WK Selph, "How to Build a Fast Limit Order Book").

**Construir**
- Libro v1 ingenuo (`std::map`), que queda como referencia.
- Libro v2: niveles de precio, listas intrusivas, cero allocations en el hot path.
- Órdenes limit, market y cancel.
- Generador de flujo de órdenes con semilla y mezcla realista (mayoría de cancelaciones, actividad cerca del mejor precio).
- Tests diferenciales v1 contra v2 y test de determinismo por hash de la salida.
- Replay de ITCH a través del book builder.
- Fuzzing del parser con AFL++ (funciona con GCC). Más importante por la demo pública.
- Modo demo: `artech demo --seed N` corre una simulación completa con el generador sintético e imprime el hash de la salida. Misma semilla → mismo hash en cualquier máquina.

**Entregable:** documento de diseño del matching engine. Post 2.

## Mes 3 (marzo) — Arquitectura de computadoras y optimización; lectura de concurrencia

**Aprender:** contadores de hardware, branch prediction, prefetching, huge pages, opciones del compilador (`-march=native`, LTO, PGO, `[[likely]]`).

**Construir**
- Optimización del libro, el parser y el hash map guiada por el profiler.
- Experimentos de layout, prefetch, huge pages y PGO/LTO, cada uno con su medición.

**En paralelo (~8 h/semana):** Williams, *C++ Concurrency in Action*, caps. 1–5; charlas de Sutter ("atomic<> Weapons") y Pikus (CppCon 2017, atomics); ejercicios pequeños con mutex y condition variable.

**Entregable:** reporte de optimización con números antes y después. Post 3.

## Mes 4 (abril) — Concurrencia: construcción

**Aprender:** memory orderings en la práctica, false sharing, scheduler de Linux, context switches, CPU affinity, `isolcpus`.

**Construir**
- Cola con mutex + condition variable (versión ingenua y oráculo).
- Cola SPSC lock-free: TSan, stress tests y argumento escrito de por qué cada `memory_order` es correcto.
- Demostración de false sharing con contadores.
- Pipeline de hilos fijados a núcleos: gateway → engine → publisher.
- Logger binario asíncrono fuera del hot path (segundo consumidor de la cola SPSC).
- Generador de carga open-loop: calendario de envío fijo y latencia medida desde el instante *previsto* de envío. Así se evita el coordinated omission.
- Timestamps por etapa del pipeline.
- Experimento de aislamiento del kernel (`isolcpus`, `nohz_full`, `rcu_nocbs`, afinidad de IRQs, `mlockall`), con antes y después.

**Entregable:** percentiles P50/P90/P99/P99.9 y curvas de latencia contra carga. Post 4.

## Mes 5 (mayo) — Networking

**Aprender:** `epoll`, sockets no bloqueantes, costo de syscalls, Nagle, buffers del kernel, multicast, busy polling.

**Construir**
- Semanas 1–2: OUCH sobre sesión estilo SoupBinTCP con `epoll`; cancel-on-disconnect.
- Semanas 3–4: publisher MoldUDP64, feed handler mínimo con detección de huecos de secuencia, inyección de fallos con veth + `tc netem`.
- Clientes en procesos separados. Network namespaces limitados a ~2 días de trabajo.

**Entregable:** latencia end-to-end de orden enviada a confirmación recibida. Post 5.

## Mes 6 (junio) — Lado del cliente y primera estrategia

**Aprender:** market making (Avellaneda & Stoikov 2008), inventario, selección adversa.

**Construir**
- Feed handler completo, reutilizando el book builder.
- Order manager, posiciones, PnL, chequeos de riesgo y kill switch.
- Agentes sintéticos para el generador de mercado.
- Estrategia de market making.
- Medición de **tick-to-trade** (paquete de market data que entra → orden que sale), la métrica principal en HFT.
- Gateway web: servidor WebSocket propio (handshake HTTP, framing, backpressure ante navegadores lentos) que reutiliza el feed handler y reparte market data a varios clientes.

**Entregable:** reporte de tick-to-trade. Post 6.

## Mes 7 (julio) — Estrategias restantes y benchmarks del sistema

**Aprender:** señales de imbalance (Cont, Kukanov & Stoikov; Stoikov, "The Micro-Price"), cointegración básica.

**Construir**
- Estrategia de order book imbalance.
- Backtesting por replay determinista.
- Exportación de métricas (latencia, throughput, CPU, memoria, PnL) a CSV, más scripts de Python (matplotlib) para las gráficas de los reportes.
- Frontend web (vibecodeado): libro en vivo, ejecuciones, PnL y gráficas estáticas de latencia.
- Despliegue en VPS: Docker, systemd, HTTPS, límites de concurrencia y duración, dominio.
- Arbitraje estadístico entre dos instrumentos correlacionados (primer candidato a recorte).
- Última semana: empiezan los benchmarks del sistema completo.

**Entregable:** reporte de estrategias. Post 7.

## Mes 8 (agosto) — Cierre

- Feature freeze el 8 de agosto.
- Benchmarks finales, README, documentos de diseño definitivos, post 8.
- Demo pública estable en línea.
- ~1.5 semanas de colchón (antes 2; media semana pasó a la demo web).

---

## Ritmo de trabajo

- Cada semana: ~30% estudio, 60% código, 10% escritura.
- Bitácora en `docs/BITACORA.md`: se anota cada decisión, medición, bug y aprendizaje en el momento, no al final.
- Inicio de mes: sesión de diseño antes de escribir código.
- Fin de mes: revisión de código, reporte de mediciones y un post.

## Orden de recorte si hay atraso

1. Arbitraje estadístico.
2. Demo web (respaldo: video o GIF de la simulación en el README).
3. Retransmisión de paquetes perdidos (la detección de huecos se queda).
4. Experimentos de huge pages y PGO.
5. Trabajo con namespaces más allá de `netem`.

## Trampas de este hardware (Ryzen 5 5600X, 16 GB, una sola máquina)

- **Presupuesto de núcleos.** Gateway, engine, publisher, feed handler, estrategia y generador de carga no caben en 6 núcleos físicos si todos hacen busy-spin. Hay que decidir qué hilos giran y cuáles bloquean, y dejar libre el hilo hermano (SMT) de cada núcleo caliente. Todos comparten la L3, así que el generador de carga perturba los resultados: decirlo en los reportes.
- **`rdtsc`.** Comprobar `constant_tsc` y `nonstop_tsc`. Usar `lfence; rdtsc` al inicio y `rdtscp` al final. Calibrar contra `CLOCK_MONOTONIC_RAW`.
- **Ruido de frecuencia.** Precision Boost y los C-states desestabilizan las mediciones: governor `performance` y probar con boost desactivado.
- **`perf` en AMD.** El muestreo preciso usa IBS, no PEBS; las herramientas top-down de Intel no aplican. Verificar qué soporta `perf c2c` / `perf mem` en el kernel instalado.
- **x86 oculta errores de memory ordering.** Su modelo de memoria fuerte enmascara elecciones incorrectas, y TSan no es una prueba. De ahí el argumento escrito del mes 4.
- **Tamaño de los archivos ITCH.** Un día completo ocupa varios GB. Con 16 GB de RAM hay que leerlo en streaming o con `mmap`, nunca cargarlo entero, y recortar unos pocos símbolos para CI.
- **Loopback no es una red.** No hay NIC ni interrupciones, y no pierde ni reordena paquetes. Los números se llaman "latencia del stack del kernel", y los huecos se prueban con veth + `tc netem`.
- **`isolcpus` en un escritorio.** Mantener una entrada de arranque separada para medir.
- **Tamaño de línea de caché.** GCC avisa al usar `hardware_destructive_interference_size`; fijar 64.
- **TSan con GCC 13/14 en kernels recientes.** Falla con "unexpected memory mapping"; los tests corren con `setarch -R` (ya integrado en `artech_add_test`).

## Decisiones pendientes

- SHA-1 y Base64 para el handshake de WebSocket: implementarlos a mano o permitir una librería.
- Proveedor de VPS y dominio.

## Recursos

**Rendimiento**
- Bakhvalov, *Performance Analysis and Tuning on Modern CPUs*
- Drepper, "What Every Programmer Should Know About Memory"
- Manuales de optimización de Agner Fog
- Gregg, *Systems Performance* (2.ª ed.)
- Carruth, CppCon 2015, "Tuning C++: Benchmarks, and CPUs, and Compilers! Oh My!"

**Latencia**
- Gil Tene, "How NOT to Measure Latency", y HdrHistogram
- Carl Cook, CppCon 2017, "When a Microsecond Is an Eternity"
- David Gross, CppCon 2024, "When Nanoseconds Matter"
- Erik Rigtorp: guía de tuning de baja latencia y SPSCQueue

**Concurrencia**
- Williams, *C++ Concurrency in Action*
- Sutter, "atomic<> Weapons"
- Pikus, CppCon 2017, "C++ atomics, from basic to advanced"
- Blog de Jeff Preshing
- Charles Frasch, CppCon 2023, "SPSC Lock-free, Wait-free Fifo from the Ground Up"
- Paper de LMAX Disruptor

**Contenedores**
- Kulukundis, CppCon 2017 (Swiss tables)
- Posts de Malte Skarupke sobre hash tables

**Sistemas operativos y redes**
- *Operating Systems: Three Easy Pieces* (OSTEP)
- Kerrisk, *The Linux Programming Interface*
- Stevens, *UNIX Network Programming*, vol. 1
- Cloudflare, "How to receive a million packets per second"

**Microestructura**
- Harris, *Trading and Exchanges*
- Bouchaud et al., *Trades, Quotes and Prices*
- Avellaneda & Stoikov (2008)
- Cont, Kukanov & Stoikov, "The Price Impact of Order Book Events"
- Stoikov, "The Micro-Price"

**Solo para comparar al final, no para copiar**
- Ghosh, *Building Low Latency Applications with C++*

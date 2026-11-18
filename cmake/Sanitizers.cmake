# Sanitizers: el compilador inserta comprobaciones en tu binario que detectan
# errores en tiempo de ejecución y abortan con un reporte (archivo:línea + pila).
#
#   address -> ASan + UBSan: fuera de límites, use-after-free, double free,
#              leaks, overflow de enteros con signo, shifts inválidos,
#              punteros desalineados, etc.
#   thread  -> TSan: data races entre hilos.
#
# ASan y TSan NO se pueden combinar (ambos reorganizan la memoria del proceso),
# por eso son dos builds separados.
function(artech_set_sanitizers target)
    if(ARTECH_SANITIZER STREQUAL "")
        return()
    elseif(ARTECH_SANITIZER STREQUAL "address")
        set(flags -fsanitize=address,undefined)
    elseif(ARTECH_SANITIZER STREQUAL "thread")
        set(flags -fsanitize=thread)
    else()
        message(FATAL_ERROR "ARTECH_SANITIZER desconocido: '${ARTECH_SANITIZER}'")
    endif()

    # -fno-omit-frame-pointer: pilas legibles en los reportes.
    # -fno-sanitize-recover=all: UBSan aborta al primer error en vez de solo avisar
    #   (si no, un test con UB podría "pasar").
    target_compile_options(${target} INTERFACE
        ${flags} -fno-omit-frame-pointer -fno-sanitize-recover=all)
    # Hay que pasarlas también al linker: enlaza el runtime del sanitizer.
    target_link_options(${target} INTERFACE ${flags})
endfunction()

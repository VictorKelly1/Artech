# Warnings de GCC para nuestro código.
# Cada una atrapa una clase de bug típica en código de bajo nivel.
function(artech_set_warnings target)
    target_compile_options(${target} INTERFACE
        -Wall -Wextra -Wpedantic   # el conjunto base
        -Wshadow                   # una variable tapa a otra del mismo nombre
        -Wconversion               # conversiones implícitas que pierden datos (int64 -> int32)
        -Wsign-conversion          # signed <-> unsigned implícito (clásico con índices y size_t)
        -Wold-style-cast           # obliga a usar static_cast/reinterpret_cast, que se pueden buscar
        -Wnon-virtual-dtor         # clase con virtuales pero destructor no virtual
        -Woverloaded-virtual       # un overload oculta una función virtual de la base
        -Wnull-dereference
        -Wdouble-promotion         # float promovido a double sin querer
        -Wformat=2
        -Wcast-align               # casts que rompen alineación (importante al parsear ITCH)
        -Wimplicit-fallthrough
    )
    if(ARTECH_WARNINGS_AS_ERRORS)
        target_compile_options(${target} INTERFACE -Werror)
    endif()
endfunction()

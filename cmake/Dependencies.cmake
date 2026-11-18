# Dependencias externas con FetchContent.
#
# FetchContent descarga el código fuente de cada librería (en una versión fija)
# durante la configuración y lo compila como parte de tu proyecto, en build/_deps/.
# Ventajas frente a instalarlas con apt:
#   - la versión es la misma en tu máquina y en CI (reproducible);
#   - se compilan con tu mismo compilador y tus mismas banderas de ABI;
#   - no hace falta sudo.
# Cambiar de versión = cambiar GIT_TAG.
include(FetchContent)

# --- GoogleTest -------------------------------------------------------------
if(ARTECH_BUILD_TESTS)
    FetchContent_Declare(googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG        v1.15.2
        GIT_SHALLOW    TRUE
        SYSTEM)                         # sus headers no generan warnings en tu código
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
    set(BUILD_GMOCK   ON  CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)
endif()

# --- Google Benchmark -------------------------------------------------------
if(ARTECH_BUILD_BENCHMARKS)
    FetchContent_Declare(benchmark
        GIT_REPOSITORY https://github.com/google/benchmark.git
        GIT_TAG        v1.9.1
        GIT_SHALLOW    TRUE
        SYSTEM)
    # Sus propios tests no nos interesan.
    set(BENCHMARK_ENABLE_TESTING       OFF CACHE BOOL "" FORCE)
    set(BENCHMARK_ENABLE_GTEST_TESTS   OFF CACHE BOOL "" FORCE)
    set(BENCHMARK_ENABLE_INSTALL       OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(benchmark)
endif()

# --- fmt --------------------------------------------------------------------
FetchContent_Declare(fmt
    GIT_REPOSITORY https://github.com/fmtlib/fmt.git
    GIT_TAG        11.0.2
    GIT_SHALLOW    TRUE
    SYSTEM)
FetchContent_MakeAvailable(fmt)

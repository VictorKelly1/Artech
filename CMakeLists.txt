cmake_minimum_required(VERSION 3.25)

project(Artech
    VERSION 0.1.0
    DESCRIPTION "Low-latency trading engine & exchange simulator"
    LANGUAGES CXX)

# ---------------------------------------------------------------------------
# Opciones que se eligen al configurar:  cmake -DARTECH_SANITIZER=address ...
# (los presets de CMakePresets.json ya las fijan por ti)
# ---------------------------------------------------------------------------
option(ARTECH_BUILD_TESTS      "Compilar los tests (GoogleTest)"          ON)
option(ARTECH_BUILD_BENCHMARKS "Compilar los benchmarks (Google Benchmark)" ON)
option(ARTECH_WARNINGS_AS_ERRORS "Convertir warnings en errores (CI)"     OFF)
set(ARTECH_SANITIZER "" CACHE STRING "none | address | thread")
set_property(CACHE ARTECH_SANITIZER PROPERTY STRINGS "" address thread)

# Genera build/compile_commands.json para que clangd / el IDE entiendan el proyecto.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
    set(CMAKE_BUILD_TYPE Debug CACHE STRING "Tipo de build" FORCE)
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(Warnings)
include(Sanitizers)
include(Dependencies)

# ---------------------------------------------------------------------------
# artech_options: target "INTERFACE" que no compila nada; solo transporta
# estándar, warnings y sanitizers. Todo target NUESTRO lo enlaza, así las
# banderas se aplican a nuestro código y no al de las librerías de terceros.
# ---------------------------------------------------------------------------
add_library(artech_options INTERFACE)
target_compile_features(artech_options INTERFACE cxx_std_23)
set(CMAKE_CXX_EXTENSIONS OFF)   # -std=c++23, no -std=gnu++23
artech_set_warnings(artech_options)
artech_set_sanitizers(artech_options)

target_include_directories(artech_options INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/include)

# Ejecutable principal
add_executable(artech src/main.cpp)
target_link_libraries(artech PRIVATE artech_options)

# Cuando escribas código reutilizable (contenedores, parser, libro), irá en una
# librería, p. ej.:
#   add_library(artech_core STATIC src/....cpp)
#   target_link_libraries(artech_core PUBLIC artech_options)
# y artech, los tests y los benchmarks enlazarán artech_core.

if(ARTECH_BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()

if(ARTECH_BUILD_BENCHMARKS)
    add_subdirectory(bench)
endif()

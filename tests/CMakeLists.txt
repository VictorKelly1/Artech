include(GoogleTest)

# artech_add_test(nombre fuente1.cpp ...)
# Crea un ejecutable de tests enlazado a GoogleTest y registra cada TEST(...)
# en CTest. Un ejecutable por módulo: test_containers, test_itch, ...
function(artech_add_test name)
    add_executable(${name} ${ARGN})
    target_link_libraries(${name} PRIVATE artech_options GTest::gtest_main)

    if(ARTECH_SANITIZER STREQUAL "thread")
        # El runtime de TSan de GCC 13 falla con la aleatoriedad de ASLR de los
        # kernels recientes ("unexpected memory mapping"). `setarch -R` lanza el
        # test con ASLR desactivado solo para ese proceso.
        set_target_properties(${name} PROPERTIES
            CROSSCOMPILING_EMULATOR "setarch;${CMAKE_HOST_SYSTEM_PROCESSOR};-R")
    endif()

    # Lee los TEST(...) del binario y registra cada uno en CTest, así `ctest`
    # los ejecuta y reporta uno por uno.
    gtest_discover_tests(${name})
endfunction()

artech_add_test(test_smoke test_smoke.cpp)

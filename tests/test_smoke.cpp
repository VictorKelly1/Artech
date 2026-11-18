// Test de humo: solo comprueba que el toolchain funciona.
// Bórralo cuando tengas tus primeros tests reales.
#include <gtest/gtest.h>

TEST(Toolchain, CompilaConCpp23) {
    // GCC 13 reporta 202100L con -std=c++23; GCC 14+ reporta 202302L.
    EXPECT_GT(__cplusplus, 202002L);  // 202002L = C++20
}

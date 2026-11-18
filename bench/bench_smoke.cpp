// Benchmark de humo: solo comprueba que Google Benchmark enlaza y corre.
// Bórralo cuando tengas tus primeros benchmarks reales.
#include <benchmark/benchmark.h>

static void BM_Vacio(benchmark::State& state) {
    for (auto _ : state) {
        benchmark::DoNotOptimize(state.iterations());
    }
}
BENCHMARK(BM_Vacio);

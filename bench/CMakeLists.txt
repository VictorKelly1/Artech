add_executable(bench_smoke bench_smoke.cpp)
target_link_libraries(bench_smoke PRIVATE artech_options benchmark::benchmark_main)

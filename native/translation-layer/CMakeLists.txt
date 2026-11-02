cmake_minimum_required(VERSION 3.18)
project(stride_translation_layer C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)

find_package(ZLIB REQUIRED)
find_package(Threads REQUIRED)

add_library(stride_tl_parser STATIC
    husk-tl-json.c
    husk-tl-zip.c
    husk-tl-elf.c
    husk-tl-scan.c
    stride-elf-image.c
    husk-tl-a64.c
    husk-tl-dexindex.c
)

target_include_directories(stride_tl_parser PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(stride_tl_parser PUBLIC ZLIB::ZLIB Threads::Threads)
target_compile_options(stride_tl_parser PRIVATE -Wall -Wextra)

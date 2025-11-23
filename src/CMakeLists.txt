cmake_minimum_required(VERSION 3.15)

# Adicionar arquivos fonte
file(GLOB_RECURSE SOURCES "*.cpp" "*.h")

# Criar executável
add_executable(otclient ${SOURCES})

# Incluir diretórios
include_directories(${CMAKE_CURRENT_SOURCE_DIR})
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/../framework)

# Linkar bibliotecas básicas
target_link_libraries(otclient
    ${CMAKE_DL_LIBS}
)

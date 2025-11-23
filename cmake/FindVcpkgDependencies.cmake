# Arquivo auxiliar para encontrar dependências do vcpkg
# Este arquivo ajuda o CMake a encontrar bibliotecas mesmo quando
# estão apenas em packages e não em installed

if(DEFINED ENV{VCPKG_ROOT})
    set(VCPKG_ROOT $ENV{VCPKG_ROOT})
elseif(EXISTS "C:/vcpkg")
    set(VCPKG_ROOT "C:/vcpkg")
elseif(EXISTS "C:/tools/vcpkg")
    set(VCPKG_ROOT "C:/tools/vcpkg")
endif()

if(VCPKG_ROOT)
    set(VCPKG_INSTALLED_DIR "${VCPKG_ROOT}/installed/${VCPKG_TARGET_TRIPLET}")
    set(VCPKG_PACKAGES_DIR "${VCPKG_ROOT}/packages")
    
    # Função para procurar biblioteca em packages também
    function(find_vcpkg_library LIB_NAME LIB_PATTERNS)
        # Primeiro procurar em installed
        find_library(${LIB_NAME}_LIBRARY
            NAMES ${LIB_PATTERNS}
            PATHS "${VCPKG_INSTALLED_DIR}/lib"
            NO_DEFAULT_PATH
        )
        
        # Se não encontrou, procurar em packages
        if(NOT ${LIB_NAME}_LIBRARY)
            file(GLOB PACKAGE_DIRS "${VCPKG_PACKAGES_DIR}/*${LIB_NAME}*")
            foreach(PACKAGE_DIR ${PACKAGE_DIRS})
                find_library(${LIB_NAME}_LIBRARY
                    NAMES ${LIB_PATTERNS}
                    PATHS "${PACKAGE_DIR}/lib"
                    NO_DEFAULT_PATH
                )
                if(${LIB_NAME}_LIBRARY)
                    break()
                endif()
            endforeach()
        endif()
        
        if(${LIB_NAME}_LIBRARY)
            set(${LIB_NAME}_LIBRARY ${${LIB_NAME}_LIBRARY} PARENT_SCOPE)
            message(STATUS "Found ${LIB_NAME}: ${${LIB_NAME}_LIBRARY}")
        else()
            message(WARNING "Could not find ${LIB_NAME}")
        endif()
    endfunction()
    
    # Procurar LIBZIP
    if(NOT LIBZIP_LIBRARY)
        find_vcpkg_library(LIBZIP "zip" "zip.lib" "libzip.lib")
    endif()
    
    # Procurar BZIP2
    if(NOT BZIP2_LIBRARIES)
        find_vcpkg_library(BZIP2 "bz2" "bz2.lib" "libbz2.lib")
        if(BZIP2_LIBRARY)
            set(BZIP2_LIBRARIES ${BZIP2_LIBRARY})
        endif()
    endif()
    
    # Procurar OPENAL
    if(NOT OPENAL_LIBRARY)
        find_vcpkg_library(OPENAL "OpenAL32" "OpenAL32.lib" "openal.lib" "al.lib")
    endif()
endif()

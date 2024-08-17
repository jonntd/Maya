# This cmake file builds plugins both in Maya and devkit

# The option to determian the plugin is application or library
option(IS_APPLICATION "is Application not plugin" OFF)

# Plugin flags on different platforms
if(WIN32)
    add_definitions(-DNT_PLUGIN)
elseif(APPLE)
    add_definitions(-DMAC_PLUGIN)
endif()

set(PLUGIN_CMAKE_ROOT ${CMAKE_CURRENT_LIST_DIR})

if (INSIDE_MAYA)
	# for CMakeLists.txt for devkit, the flag is LINUX
	if (PEPTIDE_IS_LINUX)
		set(LINUX TRUE)
	else()
		set(LINUX FALSE)
	endif()

    if (PEPTIDE_IS_OSX)
        maya_get_build_path(frameworkDir frameworks)
    endif()
	
	set(IS_PYTHON_3_BUILD ON)

else() 
	# Include the cmake file for the compilatin options to build devkit
	include(${CMAKE_CURRENT_LIST_DIR}/devkit.cmake)
	option(IS_PYTHON_3_BUILD "Target the Python 3 devkit files" ON)
endif()

set(PY_VER_A 3)
set(PY_VER_AB 39)

# Find libxml2
macro(find_libxml2)
	if(WIN32)
		if (NOT INSIDE_MAYA)
			set(INCLUDE_DIRS $ENV{DEVKIT_LOCATION}/include/libxml)
		endif()
		set(LIBRARIES ${LIBRARIES} awxml2) 
	else()
		find_package(LibXml2 REQUIRED)
		if (LIBXML2_FOUND)
			include_directories(${LIBXML2_INCLUDE_DIR})
			set(PACKAGE_LIBS ${PACKAGE_LIBS} ${LIBXML2_LIBRARIES})
		endif()
	endif()
endmacro()

# Find OpenGL
macro(find_opengl)
	find_package(OpenGL REQUIRED) 
	if (OPENGL_FOUND) 
		set(INCLUDE_DIRS ${INCLUDE_DIRS} ${OPENGL_INCLUDE_DIR})
		set(PACKAGE_LIBS ${PACKAGE_LIBS} ${OPENGL_LIBRARIES})
	endif()
endmacro()

# Find glew
macro(find_glew)
	if (INSIDE_MAYA)
		set(GLEW_LIBRARIES glew )
		set(INCLUDE_DIRS ${INCLUDE_DIRS} $ENV{DEVKIT_LOCATION}/include/glew)
		set(PACKAGE_LIBS ${PACKAGE_LIBS} ${GLEW_LIBRARIES})
		add_definitions( -DMAYA_PLUGIN_USES_GLEW )
		set( GLEW_FOUND ON )
	else()
		find_package(GLEW)
		if (GLEW_FOUND)
			set(INCLUDE_DIRS ${INCLUDE_DIRS} ${GLEW_INCLUDE_DIRS})
			set(PACKAGE_LIBS ${PACKAGE_LIBS} ${GLEW_LIBRARIES})
			add_definitions( -DMAYA_PLUGIN_USES_GLEW )
		else()
			remove_definitions( -DMAYA_PLUGIN_USES_GLEW )
		endif()
	endif()
endmacro()

# Find Alembic
macro(find_alembic)
	if (INSIDE_MAYA)
			set(ALEMBIC_LIBRARIES Alembic::Alembic Imath::Imath)
			set(LIBRARIES ${LIBRARIES} ${ALEMBIC_LIBRARIES})
	else()
		find_package(Alembic REQUIRED)
		if (ALEMBIC_FOUND)
			set(INCLUDE_DIRS ${INCLUDE_DIRS} ${ALEMBIC_INCLUDE_DIRS})
			set(PACKAGE_LIBS ${PACKAGE_LIBS} ${ALEMBIC_LIBRARIES})
		endif()
	endif()
endmacro()

# Find Arnold
macro(find_arnold)
	find_package(Arnold REQUIRED)
	if (ARNOLD_FOUND)
		include_directories(${ARNOLD_INCLUDE_DIR})
		if (INSIDE_MAYA)
			set(PACKAGE_LIBS ${PACKAGE_LIBS} ai)
		else()
			set(PACKAGE_LIBS ${PACKAGE_LIBS} ${ARNOLD_LIBRARY})
		endif()
	endif()
endmacro()

# Find TBB
macro(find_tbb)
	if (INSIDE_MAYA)
		set(PACKAGE_LIBS ${PACKAGE_LIBS} ${MAYA_TBB_IMPORTLIB})
		set(LIBRARIES ${LIBRARIES} TBB)
	else()
        set(LIBRARIES ${LIBRARIES} tbb)
	endif()
endmacro()

# Find DirectX libraries
macro(find_directX libs)
	find_package(DirectXSDK REQUIRED)

	if(DIRECTXSDK_FOUND)
		set(INCLUDE_DIRS ${INCLUDE_DIRS} ${DIRECTXSDK_INCLUDE_DIR})
		foreach(lib ${libs})
			set(PACKAGE_LIBS ${PACKAGE_LIBS} DirectXSDK::${lib})
		endforeach()
	endif()
endmacro()

# Add cg and CgGL libraries
macro(find_cg)
    if (WIN32)
        set(LIBRARIES ${LIBRARIES} cg cgGL)
    elseif(LINUX)
        set(LIBRARIES ${LIBRARIES} Cg CgGL)
        set(PACKAGE_LIBS ${PACKAGE_LIBS} "-lX11 -lXext -DGLX_GLXEXT_PROTOTYPES")
    elseif(APPLE)
        if (INSIDE_MAYA)
            maya_get_build_path(frameworkDir frameworks)
        else()
            set(frameworkDir ${DEVKIT_LIBRARY_DIR})
        endif()
        set(INCLUDE_DIRS ${frameworkDir}/Cg.framework)
        set(PACKAGE_LIBS ${PACKAGE_LIBS} "-F${frameworkDir} -framework Cg")
    endif()
endmacro()

# Find boost
macro(find_boost)
	if (INSIDE_MAYA)
		#TODO: PEPTIDE boost include
		set(INCLUDE_DIRS ${INCLUDE_DIRS} ${MAYA_BOOST_INCLUDE_DIR})
	else()
		#TODO: PEPTIDE boost include for the devkit
	endif()
endmacro()


# Find D3DX11Effects lib
macro(find_D3DX11Effects)
	find_package(D3DX11Effects REQUIRED)

	if(D3DX11EFFECTS_FOUND)
		set(INCLUDE_DIRS ${INCLUDE_DIRS} ${D3DX11EFFECTS_INCLUDE_DIR})
		set(PACKAGE_LIBS ${PACKAGE_LIBS} DirectXSDK::D3DX11Effects)
		
		add_definitions(-DUSE_D3DX11EFFECTS=1)
		if(DIRECTXSDK_D3DX11EFFECTS_FOUND)
			add_definitions(-DUSE_DIRECTXSDK_D3DX11EFFECTS=1)
		endif()
	endif()
endmacro()

# Function to build plugin application
function(build_application)
	set(IS_APPLICATION ON)
	build_plugin()
endfunction()

	
# Function to build plugin
function(build_plugin)
    # Info:
    # INCLUDE_DIRS  -   header search directories
    # LIBRARY_DIRS  -   library search directories
    # LIBRARIES     -   library names to link
	# PACKAGE_LIBS  -   libraries in the packages of different platforms
    # Most recent project name will be used for target name
    # Maya libraries and headers are automatically included
	
	set(project ${PROJECT_NAME})
	
	
	if (INSIDE_MAYA)
		# The cmake file to build plugin in maya
		include(${PLUGIN_CMAKE_ROOT}/buildPlugin.cmake)
	else()
		# Build plugin in devkit
		list(APPEND INCLUDE_DIRS $ENV{DEVKIT_LOCATION}/include $ENV{DEVKIT_LOCATION}/include/Python${PY_VER_AB})
		
		include_directories(${INCLUDE_DIRS})

		if (IS_APPLICATION)
			if(LINUX)
				include(${PLUGIN_CMAKE_ROOT}/mayald.cmake)
			endif()
			add_executable(${PROJECT_NAME} ${SOURCE_FILES})
		else()
			add_library(${PROJECT_NAME} SHARED ${SOURCE_FILES})
		endif()
		
		set(LIBRARY_DIRS ${LIBRARY_DIRS} ${DEVKIT_LIBRARY_DIR})
		foreach(MAYA_LIB ${LIBRARIES})
			find_library(${MAYA_LIB}_PATH NAMES ${MAYA_LIB} PATHS ${LIBRARY_DIRS} NO_DEFAULT_PATH)
			set(MAYA_LIBRARIES ${MAYA_LIBRARIES} ${${MAYA_LIB}_PATH})
		endforeach(MAYA_LIB)
		
		if (PACKAGE_LIBS)
			set(MAYA_LIBRARIES ${MAYA_LIBRARIES} ${PACKAGE_LIBS})
		endif()
		
		target_link_libraries(${PROJECT_NAME} ${MAYA_LIBRARIES})
		
		if(NOT IS_APPLICATION)
			set_target_properties(${PROJECT_NAME} PROPERTIES PREFIX "")
			set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX "${SUFFIX_NAME}")
		endif()
	
	endif()

	
endfunction()

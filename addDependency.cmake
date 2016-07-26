include(ExternalProject)

macro(initCPM)
	if(NOT DEFINED CPM_PACKAGE_DIR) #not set assume part of source tree
		set(CPM_PACKAGE_DIR "${CMAKE_SOURCE_DIR}/cpmPackages/" CACHE TYPE STRING)
	endif()
	set(CPM_DIR "${CPM_PACKAGE_DIR}/CPM" CACHE TYPE STRING)
	set(CPM_ROOT_BIN_DIR "${CPM_PACKAGE_DIR}/bin")

	find_package(Git)

	if(NOT GIT_FOUND)
		message(FATAL_ERROR "CPM requires Git.")
	endif()
	if (NOT EXISTS ${CPM_DIR}/CPM.cmake)
		message(STATUS "Cloning repo (https://github.com/iauns/cpm)")
		execute_process(
			COMMAND "${GIT_EXECUTABLE}" clone https://github.com/iauns/cpm ${CPM_DIR}
			RESULT_VARIABLE error_code
			OUTPUT_QUIET ERROR_QUIET
		)
		if(error_code)
			message(FATAL_ERROR "CPM failed to get the hash for HEAD")
		endif()
	endif()

	include(${CPM_DIR}/CPM.cmake)
	CPM_Finish()
endmacro(initCPM)

function(add_dependency DEPENDENCY)
	set(options "")
	set(oneValueArgs GIT_REPOSITORY GIT_TAG)
	set(multiValueArgs "")
	cmake_parse_arguments(ADD_DEPENDENCY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

	message(STATUS "Git Tag: ${ADD_DEPENDENCY_GIT_TAG}")
	#set cpm folders
	if(NOT DEFINED ADD_DEPENDENCY_GIT_TAG)
		set(ADD_DEPENDENCY_GIT_TAG "head")
	endif()

	set(DEPENDENCY_PACKAGE_SOURCE_DIR "${CPM_PACKAGE_DIR}/source/${DEPENDENCY}-${ADD_DEPENDENCY_GIT_TAG}")
	set(DEPENDENCY_PACKAGE_BUILD_DIR "${CPM_PACKAGE_DIR}/build/${DEPENDENCY}-${ADD_DEPENDENCY_GIT_TAG}")
	set(DEPENDENCY_PACKAGE_INSTALL_DIR "${CPM_PACKAGE_DIR}/${DEPENDENCY}-${ADD_DEPENDENCY_GIT_TAG}")

	get_filename_component(DEPENDENCY_PACKAGE_SOURCE_DIR ${DEPENDENCY_PACKAGE_SOURCE_DIR} ABSOLUTE)
	get_filename_component(DEPENDENCY_PACKAGE_BUILD_DIR ${DEPENDENCY_PACKAGE_BUILD_DIR} ABSOLUTE)
	get_filename_component(DEPENDENCY_PACKAGE_INSTALL_DIR ${DEPENDENCY_PACKAGE_INSTALL_DIR} ABSOLUTE)

	if(NOT DEFINED ADD_GIT_DEPENDENCY_GIT_TAG) #not set origin master
		set(ADD_GIT_DEPENDENCY_GIT_TAG "origin/master")
	endif()


	message(STATUS "add_dependency: ${DEPENDENCY}")
	message(STATUS "Pkg Source Dir: ${DEPENDENCY_PACKAGE_SOURCE_DIR}")
	message(STATUS "Pkg Build Dir: ${DEPENDENCY_PACKAGE_SOURCE_DIR}")
	message(STATUS "Pkg Install Dir: ${DEPENDENCY_PACKAGE_INSTALL_DIR}")

	set(CPM_LOCAL_PACKAGE "${CMAKE_MODULE_PATH}/packages/cpmPackage${DEPENDENCY}.cmake")
	if(EXISTS ${CPM_LOCAL_PACKAGE})
		include(${CPM_LOCAL_PACKAGE})
	else() #try default loading the package from github
		if(NOT DEFINED ADD_DEPENDENCY_GIT_REPOSITORY) #not set assume it is from github
			set(ADD_DEPENDENCY_GIT_REPOSITORY "https://github.com/${DEPENDENCY}/{DEPENDENCY}.git")
		endif()

#		message(STATUS "Git Repo: ${ADD_DEPENDENCY_GIT_REPOSITORY}")
#		message(STATUS "Git Tag: ${ADD_DEPENDENCY_GIT_TAG}")

		add_git_dependency(${DEPENDENCY} ${ADD_DEPENDENCY_GIT_REPOSITORY} GIT_TAG ${ADD_DEPENDENCY_GIT_TAG})
		set(${DEPENDENCY}_INCLUDE "${DEPENDENCY_PACKAGE_DIR}/include")
		set(${DEPENDENCY}_LIBRARY_DIR "${DEPENDENCY_PACKAGE_DIR}/lib")

		set_target_properties(${DEPENDENCY} PROPERTIES FOLDER "packages")
	endif()

endfunction(add_dependency)

function(add_git_dependency DEPENDENCY GIT_REPOSITORY)
	set(options "")
	set(oneValueArgs GIT_TAG)
	set(multiValueArgs "")
	cmake_parse_arguments(ADD_GIT_DEPENDENCY "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN} )

	if(NOT DEFINED ADD_GIT_DEPENDENCY_GIT_TAG) #not set origin master
		set(ADD_GIT_DEPENDENCY_GIT_TAG "origin/master")
	endif()

#	message(STATUS "add_git_dependency: ${DEPENDENCY} ${GIT_REPOSITORY}")
#	message(STATUS "Pkg Source Dir: ${DEPENDENCY_PACKAGE_SOURCE_DIR}")
#	message(STATUS "Pkg Build Dir: ${DEPENDENCY_PACKAGE_BUILD_DIR}")
#	message(STATUS "Pkg Instal Dir: ${DEPENDENCY_PACKAGE_INSTALL_DIR}")
#	message(STATUS "Git Repo: ${GIT_REPOSITORY}")
#	message(STATUS "Git Tag: ${ADD_GIT_DEPENDENCY_GIT_TAG}")

	CPM_EnsureRepoIsCurrent(TARGET_DIR ${DEPENDENCY_PACKAGE_SOURCE_DIR}
		GIT_REPOSITORY ${GIT_REPOSITORY}
		GIT_TAG ${ADD_GIT_DEPENDENCY_GIT_TAG}
		USE_CACHING TRUE
	)

	set(CMAKE_INSTALL_PREFIX ${DEPENDENCY_PACKAGE_INSTALL_DIR})

	ExternalProject_Add(${DEPENDENCY} 
		SOURCE_DIR ${DEPENDENCY_PACKAGE_SOURCE_DIR} 
		BINARY_DIR ${DEPENDENCY_PACKAGE_BUILD_DIR} 
		CMAKE_ARGS "${CMAKE_ARGS};-DCMAKE_INSTALL_PREFIX=${DEPENDENCY_PACKAGE_INSTALL_DIR}"
	)

endfunction(add_git_dependency)
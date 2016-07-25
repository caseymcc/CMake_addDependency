message(STATUS "GLFW -------------------------------------")
message(STATUS "add_dependency: ${DEPENDENCY}")
message(STATUS "Pkg Source Dir: ${DEPENDENCY_PACKAGE_SOURCE_DIR}")
message(STATUS "Pkg Dir: ${DEPENDENCY_PACKAGE_DIR}")
message(STATUS "Git Repo: ${ADD_DEPENDENCY_GIT_REPOSITORY}")
message(STATUS "Git Tag: ${ADD_DEPENDENCY_GIT_TAG}")
message(STATUS "------------------------------------------")

set(GLFW_BUILD_EXAMPLES OFF)
set(GLFW_BUILD_TESTS OFF)
set(GLFW_INSTALL OFF)

add_git_dependency(${DEPENDENCY} "https://github.com/glfw/glfw.git" GIT_TAG ${ADD_DEPENDENCY_GIT_TAG})

message(STATUS "GLFW: pkg dir: ${DEPENDENCY_PACKAGE_SOURCE_DIR}")
message(STATUS "GLFW: source dir: ${DEPENDENCY_PACKAGE_DIR}")

add_subdirectory(${DEPENDENCY_PACKAGE_SOURCE_DIR} ${DEPENDENCY_PACKAGE_DIR})
	
set_target_properties(glfw PROPERTIES FOLDER "cpmPackages")
set(${DEPENDENCY}_INCLUDE "${DEPENDENCY_PACKAGE_DIR}/include")

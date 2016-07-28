CMake AddPackage
======

This is a CMake package handler. It will attempt to download a package (either cloning a git repo or downloading precompiled libs) and add it to your project. If it is a git repo and cmake based it will add the package project to your project.

_It is pretty rough at the moment but does handle a few libs pretty well. I have also only tested on windows thus far and some of the download only packages will likely only work on windows._

##How it works
You need to put the AddPackage.cmake and included directory "packages" somewhere CMake can find them. I usually create a directory along side my CMakeLists.txt file called CMakeModules then in the CMakeLists.txt add the following near the top

```
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMakeModules)
```

then in the same CMakeLists.txt or per project CMakeLists.txt add the following _(add_package can be called multiple times with the same package)_

```
include(AddPackage)

add_package("opencl")
add_package("glew" VERSION "2.0.0")
```

Providing the optional VERSION tells the packager which version to get, assuming all goes well the packager creates a few CMake vars that can be used to add the include directory and libraries in your project.
```
${PACKAGE_NAME}_ROOT
${PACKAGE_NAME}_INCLUDE_DIRS 
${PACKAGE_NAME}_BIN_DIRS
${PACKAGE_NAME}_LIBRARIES
${PACKAGE_NAME}_TARGET
```
for example in the snippet above opencl would end up being OPENCL_INCLUDE_DIRS for header include folder.
* ${PACKAGE_NAME}_ROOT - root to install folder
* ${PACKAGE_NAME}_INCLUDE_DIRS - list of directories required for include
* ${PACKAGE_NAME}_BIN_DIRS - list of directories where executables go
* ${PACKAGE_NAME}_LIBRARIES - list of libraries provided by package
* ${PACKAGE_NAME}_TARGET - CMake Target name for the added package

Generally what you do with these things is
```
include_directories(${OPENCL_INCLUDE_DIRS}) #provides include directories for including package
target_link_libraries($YouProject ${OPENCL_LIBRARIES}) #includes libraries from the package to your project
add_dependencies(Base ${OPENCL_TARGET}) #forces opencl package to be compiled before your project
```
${PACKAGE_NAME}_ROOT helps if you have a find_package some where in your CMake calls that starts search at ${PACKAGE}_ROOT.


You can add a cmake argument ADD_PACKAGE_DIR which will tell the packager where to store all the files. 
```
cmake -DADD_PACKAGE_DIR=<directory for packages>
```
If not provided it selects ${CMAKE_SOURCE_DIR}/packages/. This var is nice if you have multiple independant projects that use the same packages then there will only be 1 copy.


##Current Packages
* _dlib_
* _fftw_
* _glew_
* _glfw_
* _glm_
* _libpng_
* _opencl_
* _rapidjson_
* _zlib_

##More Details
When add_package is called it attempts to locate a cmake file package${PACKAGE_NAME}.cmake, if that fails it will try to get it a repository from github https://github.com/${PACKAGE_NAME}/${PACKAGE_NAME}.git (which will likely fail as naming convention are not that good)

If it finds the cmake package file it will run what is inside. Generally that is something like the following
```
#zlib puts a v in front of their version labels
set(ZLIB_GIT_TAG "v${ADD_PACKAGE_VERSION}")

add_git_package(${DEPENDENCY_PACKAGE_NAME} "https://github.com/madler/zlib.git" GIT_TAG ${ZLIB_GIT_TAG})

set(${DEPENDENCY_PACKAGE_NAME}_LIBRARIES ${DEPENDENCY_PACKAGE_INSTALL_DIR}/lib/zlib.lib PARENT_SCOPE)
```
Basically converting the VERSION into a git tag and setting the repo url. Also setting the library(ies) that the package provides.

When executed add_package will search for git on your machine and then get CPM from github.(used to update repos) When processing a package the uses git, it will place the repo in a directory ${ADD_PACKAGE_DIR}/source/${PACKAGE_NAME}-${VERSION}. It will then add the project to your project using ExternalProject_Add while setting ${ADD_PACKAGE_DIR}/build/${PACKAGE_NAME}-${VERSION} as the build folder and ${ADD_PACKAGE_DIR}/${PACKAGE_NAME}-{VERSION} as the install folder for the included package.

##Writing package files

From the package file the following functions can be called that are in AddPackage (and should only be called from there)
* _add_git_package_ - will fetch the git repo with the tag provided and add and ExternalProject to the build.
* _add_package_update_git_ - will update repo with tag
* _add_package_project_ - will ExternalProject to the build

Along with those you can call any other CMake command. 

The file also need to set the libraries it will build (or downloaded)
```
${PACKAGE_NAME}_LIBRARIES
```

If you dont use add_git_package (or the directories reside somewhere else) you need to setup 
```
${PACKAGE_NAME}_INCLUDE_DIRS
${PACKAGE_NAME}_BIN_DIRS
${PACKAGE_NAME}_LIBRARIES
```

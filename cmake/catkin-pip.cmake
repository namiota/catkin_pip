message(STATUS "Loading catkin-pip.cmake from ${CMAKE_CURRENT_LIST_DIR}... ")

if ( NOT CATKIN_PIP_REQUIREMENTS_PATH )
    set (CATKIN_PIP_REQUIREMENTS_PATH ${CMAKE_CURRENT_LIST_DIR})
endif()

if ( NOT CATKIN_PIP_GLOBAL_PYTHON_DESTINATION )
    # using site-packages as it s the default for pip and should also be used on debian systems for installs from non system packages
    # Explanation here : http://stackoverflow.com/questions/9387928/whats-the-difference-between-dist-packages-and-site-packages
    set (CATKIN_PIP_GLOBAL_PYTHON_DESTINATION "lib/python2.7/site-packages")
endif()

# _setup_util.py should already exist here.
# catkin should have done hte workspace setup before we reach here
if ( EXISTS ${CATKIN_DEVEL_PREFIX}/_setup_util.py )
    file(READ ${CATKIN_DEVEL_PREFIX}/_setup_util.py  SETUP_UTIL_PY)
    string(REPLACE
        "'PYTHONPATH': 'lib/python2.7/dist-packages',"
        "'PYTHONPATH': ['lib/python2.7/dist-packages', '${CATKIN_PIP_GLOBAL_PYTHON_DESTINATION}']"
        PATCHED_SETUP_UTIL_PY
        ${SETUP_UTIL_PY}
    )
    file(WRITE ${CATKIN_DEVEL_PREFIX}/_setup_util.py  ${PATCHED_SETUP_UTIL_PY})
else()
    message(FATAL_ERROR "SETUP_UTIL.PY DOES NOT EXISTS YET ")
endif()

# Since we need (almost) the same configuration for both devel and install space, we create cmake files for each workspace setup.
set(CONFIGURE_PREFIX ${CATKIN_DEVEL_PREFIX})
set(PIP_PACKAGE_INSTALL_COMMAND \${CATKIN_PIP} install -e \${package_path} --install-option "--install-dir=${CONFIGURE_PREFIX}/${CATKIN_PIP_GLOBAL_PYTHON_DESTINATION}" --install-option "--script-dir=${CONFIGURE_PREFIX}/${CATKIN_GLOBAL_BIN_DESTINATION}")
configure_file(${CMAKE_CURRENT_LIST_DIR}/catkin-pip-setup.cmake.in ${CONFIGURE_PREFIX}/.catkin-pip-setup.cmake @ONLY)

set(CONFIGURE_PREFIX ${CMAKE_INSTALL_PREFIX})
set(PIP_PACKAGE_INSTALL_COMMAND \${CATKIN_PIP} install \${package_path} --prefix "${CONFIGURE_PREFIX}")
configure_file(${CMAKE_CURRENT_LIST_DIR}/catkin-pip-setup.cmake.in ${CONFIGURE_PREFIX}/.catkin-pip-setup.cmake @ONLY)

unset(CONFIGURE_PREFIX)
unset(PIP_PACKAGE_INSTALL_COMMAND)

# And here we need to do the devel workspace setup.
include(${CATKIN_DEVEL_PREFIX}/.catkin-pip-setup.cmake)


macro(catkin_pip_requirements requirements_txt )

    catkin_pip_requirements_prefix(${requirements_txt})

endmacro()

macro(catkin_pip_package)

    set (extra_macro_args ${ARGN})

    # Did we get any optional args?
    list(LENGTH extra_macro_args num_extra_args)
    if (${num_extra_args} GREATER 0)
        list(GET extra_macro_args 0 package_path)
        #message ("Got package_path: ${package_path}")
    else()
        set(package_path .)
    endif()

    catkin_pip_package_prefix(${package_path})

    # Setting up the command for install space for user convenience
    install(CODE "
        #Setting paths for install by including our configured install cmake file
        include(${CMAKE_INSTALL_PREFIX}/.catkin-pip-setup.cmake)
        catkin_pip_package_prefix(${package_path})
    ")
endmacro()

# TODO :
# venv for easy pip install : investigate https://github.com/KitwareMedical/TubeTK/blob/master/CMake/TubeTKVirtualEnvSetup.cmake # maybe not a good idea. workspace do the job for ROS now.
# install pip packages to be embedded with install workspace. BUT not in catkin deb package...
# CPACK to deb : investigate https://cmake.org/pipermail/cmake/2011-February/042687.html
#

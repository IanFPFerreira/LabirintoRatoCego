# Project variables
PROJECT=RatoCego
MAP_GENERATOR=MapGenerator

# Compiler and flags variables
CXX=g++
CPPFLAGS=-W -Wall -fPIC -MMD -I/usr/include/SDL2
CXXFLAGS=-std=c++20
RELEASE_CPPFLAGS=-O2
DEBUG_CPPFLAGS=-g -O0
DL_FLAGS=-shared

# Condition to check if is release or debug
ifeq ($(MAKECMDGOALS),release)
    CPPFLAGS+=$(RELEASE_CPPFLAGS)
else
    CPPFLAGS+=$(DEBUG_CPPFLAGS)
endif

# Environment variables
INCLUDE_FLAG=-I
OUTPUT_FLAG=-o 
OBJ_EXTENSION=.o
STATIC_LIB_SUFFIX=.a
STATIC_LIB_PREFIX=lib
DYNAMIC_LIB_SUFFIX=.so

# Directories
SRC_DIR=src
BASE_DIR=$(SRC_DIR)/base
LIBS_DIR=libs
INC_DIR=include
TESTS_DIR=tests
CLASSES_DIR=classes
SCRIPTS_DIR=scripts
TEMPLATE_DIR=templates
PLUGINS_DIR=$(SRC_DIR)/plugins
SO_DIR=plugins

# Installation directories
INSTALL_BIN_DIR=/usr/local/bin
INSTALL_MAN_DIR=/usr/share/man/man1
INSTALL_CLASSES_DIR=/usr/local/lib
INSTALL_PLUGINS_DIR=/usr/local/lib
INSTALL_TEMPLATE_DIR=/usr/local/lib
INSTALL_COMPLETION_DIR=/etc/bash_completion.d

# Temporary directories
CP_TEMP_DIR=.cp-tmp
CP_BUILD_DIR=.cp-build

# Project targets
LIBRARY=$(STATIC_LIB_PREFIX)$(PROJECT)$(STATIC_LIB_SUFFIX)
TEST_SUIT=cp-run_tests

# Include flags
LDFLAGS=-lSDL2 -lSDL2_image -lSDL2_ttf
INCLUDES_DIRS=${addprefix $(INCLUDE_FLAG), $(INC_DIR)} ${addprefix $(INCLUDE_FLAG), $(LIBS_DIR)}
CPPFLAGS+=$(INCLUDES_DIRS)

# Project source files
PROJECT_MAIN=$(SRC_DIR)/main.cpp
MAP_MAIN=$(SRC_DIR)/mainMap.cpp
PROJECT_OBJECT=$(PROJECT_MAIN:.cpp=$(OBJ_EXTENSION))
MAP_OBJECT=$(MAP_MAIN:.cpp=$(OBJ_EXTENSION))

# Finds all .cpp files and filters src/main.cpp out
SOURCES=${wildcard $(SRC_DIR)/*.cpp}
SOURCES:=${filter-out $(PROJECT_MAIN), $(SOURCES)}
SOURCES:=${filter-out $(MAP_MAIN), $(SOURCES)}

# Generates objects file names
OBJECTS=$(SOURCES:.cpp=$(OBJ_EXTENSION))

# Finds all plugins
PLUGINS=${shell find $(PLUGINS_DIR) -type f -name '*.cpp'}

# Generates plugins names
PLUGINS_NAMES=$(PLUGINS:.cpp=$(DYNAMIC_LIB_SUFFIX))

# Completion script and manual
COMPLETION_SCRIPT=$(PROJECT)-completion.sh
MAN_FILE=cp-tools.1

# Tests source files and objects
TEST_SOURCES=${wildcard $(TESTS_DIR)/*.cpp}
TEST_OBJECTS=$(TEST_SOURCES:.cpp=$(OBJ_EXTENSION))

# ar and linker
AR=ar
AR_FLAGS=-rs
LINKER=$(CXX)

# Rules
.SUFFIXES: .cpp .$(OBJ_EXTENSION) .$(DYNAMIC_LIB_EXTENSION)
.PHONY: all clean build 

# Generetes all plugins
%.o: %.cpp 
	@echo "Building '$(notdir $<)'..."
	$(CXX) $(CPPFLAGS) $(CXXFLAGS) -I. -c $< -o $@

#all: build tests # format
all: build

format:
	-clang-format-10 --version
	@-find $(INC_DIR) $(TESTS_DIR) $(SRC_DIR) -type f -name "*.cpp" -or -name "*.h" | xargs clang-format-10 -i


build: $(LIBRARY) $(PROJECT) $(MAP_GENERATOR)


$(LIBRARY): $(OBJECTS)
	$(AR) $(AR_FLAGS) $@ $(OBJECTS)


$(PROJECT): $(LIBRARY) $(PROJECT_OBJECT)
	$(LINKER) $(PROJECT_OBJECT) $(LIBRARY) $(OUTPUT_FLAG) $@ $(LDFLAGS)

$(MAP_GENERATOR): $(LIBRARY) $(MAP_OBJECT)
	$(LINKER) $(MAP_OBJECT) $(LIBRARY) $(OUTPUT_FLAG) $@ $(LDFLAGS)

$(TEST_SUIT): $(LIBRARY) $(TEST_OBJECTS)
	$(LINKER) $(TEST_OBJECTS) $(LIBRARY) $(OUTPUT_FLAG) $@ $(LDFLAGS)


update_release:
	@./scripts/gen_defs.sh


release: update_release $(LIBRARY) $(PROJECT)


install: $(PROJECT)
	@cp $(PROJECT) $(INSTALL_BIN_DIR)
	@mkdir -p $(INSTALL_TEMPLATE_DIR)/$(PROJECT)
	@cp -r $(TEMPLATE_DIR) $(INSTALL_TEMPLATE_DIR)/$(PROJECT)/
	@mkdir -p $(INSTALL_CLASSES_DIR)/$(PROJECT)
	@cp -r $(CLASSES_DIR) $(INSTALL_CLASSES_DIR)/$(PROJECT)/
	@cp $(SCRIPTS_DIR)/$(COMPLETION_SCRIPT) $(INSTALL_COMPLETION_DIR)
	@cp $(MAN_FILE) $(INSTALL_MAN_DIR)
	@mkdir -p $(INSTALL_PLUGINS_DIR)/$(PROJECT)/plugins
	@cp $(PLUGINS_NAMES) $(INSTALL_PLUGINS_DIR)/$(PROJECT)/plugins

uninstall:
	@rm -f $(INSTALL_COMPLETION_DIR)/$(COMPLETION_SCRIPT)
	@rm -rf $(INSTALL_TEMPLATE_DIR)/$(PROJECT)
	@rm -f $(INSTALL_BIN_DIR)/$(PROJECT)
	@rm -f $(INSTALL_MAN_DIR)/$(MAN_FILE)


clean:
	@rm -f *~ $(LIBRARY) $(PROJECT) $(TEST_SUIT)
	@find . -name '*.o' -exec rm -f {}  \;
	@find . -name '*.d' -exec rm -f {}  \;
	@find . -name '*.so' -exec rm -f {}  \;
	@rm -rf *~ $(CP_TEMP_DIR) $(CP_BUILD_DIR)

-include $(SOURCES:%.cpp=%.d)
-include $(PROJECT_MAIN:%.cpp=%.d)

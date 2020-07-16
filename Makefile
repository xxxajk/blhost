#-----------------------------------------------
# Make command:
# make build=<build> all
# <build>: debug or release, release by default.
#-----------------------------------------------

#-----------------------------------------------
# setup variables
# ----------------------------------------------

BOOT_ROOT := $(abspath ./)
OUTPUT_ROOT := $(abspath ./)

APP_NAME = blhost


#-----------------------------------------------
# Debug or Release
# Release by default
#-----------------------------------------------
build ?= release

include ./common.mk

#-----------------------------------------------
# Include path. Add the include paths like this:
# INCLUDES += ./include/
#-----------------------------------------------
INCLUDES += $(BOOT_ROOT)/src \
			$(BOOT_ROOT)/include \
			$(BOOT_ROOT)/include/blfwk \
			$(BOOT_ROOT)/include/sbloader \
			$(BOOT_ROOT)/include/bootloader \
			$(BOOT_ROOT)/include/crc \
			$(BOOT_ROOT)/include/packet \
			$(BOOT_ROOT)/include/property \
			$(BOOT_ROOT)/include/driver \
			$(BOOT_ROOT)/include/bm_usb


LBITS := $(shell getconf LONG_BIT)
ifeq ($(LBITS),64)
CXXFLAGS := -D LINUX -D BOOTLOADER_HOST -std=c++0x -m32
CFLAGS   := -std=c99 -D LINUX -D BOOTLOADER_HOST -D _GNU_SOURCE -m32
LD       := g++ -m32
CXXFLAGS64 := -D LINUX -D BOOTLOADER_HOST -std=c++0x
CFLAGS64   := -std=c99 -D LINUX -D BOOTLOADER_HOST -D _GNU_SOURCE
LD64       := g++
else
CXXFLAGS := -D LINUX -D BOOTLOADER_HOST -std=c++0x
CFLAGS   := -std=c99 -D LINUX -D BOOTLOADER_HOST -D _GNU_SOURCE
LD       := g++      
endif

SOURCES := $(BOOT_ROOT)/src/blhost.cpp \
		   $(BOOT_ROOT)/src/blfwk/Blob.cpp \
		   $(BOOT_ROOT)/src/blfwk/Bootloader.cpp \
		   $(BOOT_ROOT)/src/blfwk/BusPal.cpp \
		   $(BOOT_ROOT)/src/blfwk/BusPalPeripheral.cpp \
		   $(BOOT_ROOT)/src/blfwk/Command.cpp \
		   $(BOOT_ROOT)/src/blfwk/DataSource.cpp \
		   $(BOOT_ROOT)/src/blfwk/DataSourceImager.cpp \
		   $(BOOT_ROOT)/src/blfwk/DataTarget.cpp \
		   $(BOOT_ROOT)/src/blfwk/ELFSourceFile.cpp \
		   $(BOOT_ROOT)/src/blfwk/ExcludesListMatcher.cpp \
		   $(BOOT_ROOT)/src/blfwk/format_string.cpp \
		   $(BOOT_ROOT)/src/blfwk/GHSSecInfo.cpp \
		   $(BOOT_ROOT)/src/blfwk/GlobMatcher.cpp \
		   $(BOOT_ROOT)/src/blfwk/hid-linux.c \
		   $(BOOT_ROOT)/src/blfwk/jsoncpp.cpp \
		   $(BOOT_ROOT)/src/blfwk/Logging.cpp \
		   $(BOOT_ROOT)/src/blfwk/options.cpp \
		   $(BOOT_ROOT)/src/blfwk/SBSourceFile.cpp  \
		   $(BOOT_ROOT)/src/blfwk/SearchPath.cpp  \
		   $(BOOT_ROOT)/src/blfwk/serial.c \
		   $(BOOT_ROOT)/src/blfwk/SerialPacketizer.cpp \
		   $(BOOT_ROOT)/src/blfwk/SourceFile.cpp \
		   $(BOOT_ROOT)/src/blfwk/SRecordSourceFile.cpp \
		   $(BOOT_ROOT)/src/blfwk/IntelHexSourceFile.cpp \
		   $(BOOT_ROOT)/src/blfwk/StELFFile.cpp \
		   $(BOOT_ROOT)/src/blfwk/StExecutableImage.cpp \
		   $(BOOT_ROOT)/src/blfwk/StSRecordFile.cpp \
		   $(BOOT_ROOT)/src/blfwk/StIntelHexFile.cpp \
		   $(BOOT_ROOT)/src/blfwk/Updater.cpp \
		   $(BOOT_ROOT)/src/blfwk/UartPeripheral.cpp \
		   $(BOOT_ROOT)/src/blfwk/UsbHidPacketizer.cpp \
		   $(BOOT_ROOT)/src/blfwk/UsbHidPeripheral.cpp \
		   $(BOOT_ROOT)/src/blfwk/utils.cpp \
		   $(BOOT_ROOT)/src/blfwk/Value.cpp \
		   $(BOOT_ROOT)/src/crc/crc16.c \
		   $(BOOT_ROOT)/src/crc/crc32.c

INCLUDES := $(foreach includes, $(INCLUDES), -I $(includes))

ifeq "$(build)" "debug"
DEBUG_OR_RELEASE := Debug
CFLAGS64 += -g
CXXFLAGS64 += -g
LDFLAGS64 += -g
CFLAGS += -g
CXXFLAGS += -g
LDFLAGS += -g
else
DEBUG_OR_RELEASE := Release
endif

ifeq ($(LBITS),64)
TARGET_OUTPUT_ROOT := $(OUTPUT_ROOT)/$(DEBUG_OR_RELEASE)-32bit
MAKE_TARGET := $(TARGET_OUTPUT_ROOT)/$(APP_NAME)
OBJS_ROOT = $(TARGET_OUTPUT_ROOT)/obj
TARGET_OUTPUT_ROOT64 := $(OUTPUT_ROOT)/$(DEBUG_OR_RELEASE)-64bit
MAKE_TARGET64 := $(TARGET_OUTPUT_ROOT64)/$(APP_NAME)
OBJS_ROOT64= $(TARGET_OUTPUT_ROOT64)/obj
else
TARGET_OUTPUT_ROOT := $(OUTPUT_ROOT)/$(DEBUG_OR_RELEASE)
MAKE_TARGET := $(TARGET_OUTPUT_ROOT)/$(APP_NAME)
OBJS_ROOT = $(TARGET_OUTPUT_ROOT)/obj
endif

# Strip sources.
SOURCES := $(strip $(SOURCES))

# Convert sources list to absolute paths and root-relative paths.
SOURCES_ABS := $(foreach s,$(SOURCES),$(abspath $(s)))
SOURCES_REL := $(subst $(BOOT_ROOT)/,,$(SOURCES_ABS))

# Get a list of unique directories containing the source files.
SOURCE_DIRS_ABS := $(sort $(foreach f,$(SOURCES_ABS),$(dir $(f))))
SOURCE_DIRS_REL := $(subst $(BOOT_ROOT)/,,$(SOURCE_DIRS_ABS))

ifeq ($(LBITS),64)
OBJECTS_DIRS64 := $(addprefix $(OBJS_ROOT64)/,$(SOURCE_DIRS_REL))
endif
OBJECTS_DIRS := $(addprefix $(OBJS_ROOT)/,$(SOURCE_DIRS_REL))

# Filter source files list into separate source types.
C_SOURCES = $(filter %.c,$(SOURCES_REL))
CXX_SOURCES = $(filter %.cpp,$(SOURCES_REL))
ASM_s_SOURCES = $(filter %.s,$(SOURCES_REL))
ASM_S_SOURCES = $(filter %.S,$(SOURCES_REL))

# Convert sources to objects.
ifeq ($(LBITS),64)
OBJECTS_C64 := $(addprefix $(OBJS_ROOT64)/,$(C_SOURCES:.c=.o))
OBJECTS_CXX64 := $(addprefix $(OBJS_ROOT64)/,$(CXX_SOURCES:.cpp=.o))
OBJECTS_ASM64 := $(addprefix $(OBJS_ROOT64)/,$(ASM_s_SOURCES:.s=.o))
OBJECTS_ASM_S64 := $(addprefix $(OBJS_ROOT64)/,$(ASM_S_SOURCES:.S=.o))
endif
OBJECTS_C := $(addprefix $(OBJS_ROOT)/,$(C_SOURCES:.c=.o))
OBJECTS_CXX := $(addprefix $(OBJS_ROOT)/,$(CXX_SOURCES:.cpp=.o))
OBJECTS_ASM := $(addprefix $(OBJS_ROOT)/,$(ASM_s_SOURCES:.s=.o))
OBJECTS_ASM_S := $(addprefix $(OBJS_ROOT)/,$(ASM_S_SOURCES:.S=.o))

# Complete list of all object files.
ifeq ($(LBITS),64)
OBJECTS_ALL64 := $(sort $(OBJECTS_C64) $(OBJECTS_CXX64) $(OBJECTS_ASM64) $(OBJECTS_ASM_S64))
endif
OBJECTS_ALL := $(sort $(OBJECTS_C) $(OBJECTS_CXX) $(OBJECTS_ASM) $(OBJECTS_ASM_S))

#-------------------------------------------------------------------------------
# Default target
#-------------------------------------------------------------------------------

# Note that prerequisite order is important here. The subdirectories must be built first, or you
# may end up with files in the current directory not getting added to libraries. This would happen
# if subdirs modified the library file after local files were compiled but before they were added
# to the library.
.PHONY: all
all: $(MAKE_TARGET) $(MAKE_TARGET64)

## Recipe to create the output object file directories.
$(OBJECTS_DIRS) $(OBJECTS_DIRS64):
	$(at)mkdir -p $@

# Object files depend on the directories where they will be created.
#
# The dirs are made order-only prerequisites (by being listed after the '|') so they won't cause
# the objects to be rebuilt, as the modification date on a directory changes whenver its contents
# change. This would cause the objects to always be rebuilt if the dirs were normal prerequisites.

$(OBJECTS_ALL) $(OBJECTS_ALL64): | $(OBJECTS_DIRS) $(OBJECTS_DIRS64)

#-------------------------------------------------------------------------------
# Pattern rules for compilation
#-------------------------------------------------------------------------------
# We cd into the source directory before calling the appropriate compiler. This must be done
# on a single command line since make calls individual recipe lines in separate shells, so
# '&&' is used to chain the commands.
#
# Generate make dependencies while compiling using the -MMD option, which excludes system headers.
# If system headers are included, there are path problems on cygwin. The -MP option creates empty
# targets for each header file so that a rebuild will be forced if the file goes missing, but
# no error will occur.
ifeq ($(LBITS),64)
# Compile C sources.
$(OBJS_ROOT64)/%.o: $(BOOT_ROOT)/%.c
	@$(call printmessage,c,Compiling, $(subst $(BOOT_ROOT)/,,$<))
	$(at)$(CC) $(CFLAGS64) $(SYSTEM_INC) $(INCLUDES) $(DEFINES) -MMD -MF $(basename $@).d -MP -o $@ -c $<

# Compile C++ sources.
$(OBJS_ROOT64)/%.o: $(BOOT_ROOT)/%.cpp
	@$(call printmessage,cxx,Compiling, $(subst $(BOOT_ROOT)/,,$<))
	$(at)$(CXX) $(CXXFLAGS64) $(SYSTEM_INC) $(INCLUDES) $(DEFINES) -MMD -MF $(basename $@).d -MP -o $@ -c $<

# For .S assembly files, first run through the C preprocessor then assemble.
$(OBJS_ROOT64)/%.o: $(BOOT_ROOT)/%.S
	@$(call printmessage,asm,Assembling, $(subst $(BOOT_ROOT)/,,$<))
	$(at)$(CPP) -D__LANGUAGE_ASM__ $(INCLUDES) $(DEFINES) -o $(basename $@).s $< \
	&& $(AS) $(ASFLAGS64) $(INCLUDES) -MD $(OBJS_ROOT64)/$*.d -o $@ $(basename $@).s

# Assembler sources.
$(OBJS_ROOT64)/%.o: $(BOOT_ROOT)/%.s
	@$(call printmessage,asm,Assembling, $(subst $(BOOT_ROOT)/,,$<))
	$(at)$(AS) $(ASFLAGS64) $(INCLUDES) -MD $(basename $@).d -o $@ $<

endif

# Compile C sources.
$(OBJS_ROOT)/%.o: $(BOOT_ROOT)/%.c
	@$(call printmessage,c,Compiling, $(subst $(BOOT_ROOT)/,,$<))
	$(at)$(CC) $(CFLAGS) $(SYSTEM_INC) $(INCLUDES) $(DEFINES) -MMD -MF $(basename $@).d -MP -o $@ -c $<

# Compile C++ sources.
$(OBJS_ROOT)/%.o: $(BOOT_ROOT)/%.cpp
	@$(call printmessage,cxx,Compiling, $(subst $(BOOT_ROOT)/,,$<))
	$(at)$(CXX) $(CXXFLAGS) $(SYSTEM_INC) $(INCLUDES) $(DEFINES) -MMD -MF $(basename $@).d -MP -o $@ -c $<

# For .S assembly files, first run through the C preprocessor then assemble.
$(OBJS_ROOT)/%.o: $(BOOT_ROOT)/%.S
	@$(call printmessage,asm,Assembling, $(subst $(BOOT_ROOT)/,,$<))
	$(at)$(CPP) -D__LANGUAGE_ASM__ $(INCLUDES) $(DEFINES) -o $(basename $@).s $< \
	&& $(AS) $(ASFLAGS) $(INCLUDES) -MD $(OBJS_ROOT)/$*.d -o $@ $(basename $@).s

# Assembler sources.
$(OBJS_ROOT)/%.o: $(BOOT_ROOT)/%.s
	@$(call printmessage,asm,Assembling, $(subst $(BOOT_ROOT)/,,$<))
	$(at)$(AS) $(ASFLAGS) $(INCLUDES) -MD $(basename $@).d -o $@ $<

#------------------------------------------------------------------------
# Build the tagrget
#------------------------------------------------------------------------

# Wrap the link objects in start/end group so that ld re-checks each
# file for dependencies.  Otherwise linking static libs can be a pain
# since order matters.
$(MAKE_TARGET): $(OBJECTS_ALL)
	@$(call printmessage,link,Linking, $(APP_NAME))
	$(at)$(LD) $(LDFLAGS) \
          $(OBJECTS_ALL) \
          -lc -lstdc++ -lm -ludev \
          -o $@
	@echo "Output binary:" ; echo "  $(APP_NAME)"

ifeq ($(LBITS),64)
$(MAKE_TARGET64): $(OBJECTS_ALL64)
	@$(call printmessage,link,Linking, $(APP_NAME))
	$(at)$(LD64) $(LDFLAGS64) \
          $(OBJECTS_ALL64) \
          -lc -lstdc++ -lm -ludev \
          -o $@
	@echo "Output binary:" ; echo "  $(APP_NAME)"
endif

#-------------------------------------------------------------------------------
# Clean
#-------------------------------------------------------------------------------
.PHONY: clean cleanall
cleanall: clean
clean:
	$(at)rm -rf $(TARGET_OUTPUT_ROOT) $(TARGET_OUTPUT_ROOT64)
	$(at)find . -name "*~" -print0 | xargs -0 rm -rf
	

# Include dependency files.
-include $(OBJECTS_ALL:.o=.d)


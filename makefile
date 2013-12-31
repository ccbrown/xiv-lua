SHELL = /bin/bash

EXENAME = platform

UNAME = $(shell uname)

ifeq ($(UNAME), Darwin)
	override CXXFLAGS += -g -Wall -O3 --std=c++11
	override LDFLAGS += -llua -framework QtWidgets -framework QtGui -framework QtCore -framework QtMultimedia
else
	override CXXFLAGS += -g -Wall -O3 --std=c++11
	override LDFLAGS += -llua -lQt5Widgets -lQt5Gui -lQt5Core -lQt5Multimedia -lpsapi
endif

SRCDIR = src
OBJDIR = obj

SRCS := $(shell find $(SRCDIR) -name '*.c') $(shell find $(SRCDIR) -name '*.cpp')
OBJS := $(patsubst $(SRCDIR)/%.c,$(OBJDIR)/%.o,$(patsubst $(SRCDIR)/%.cpp,$(OBJDIR)/%.o,$(SRCS)))
DEPS := $(patsubst $(SRCDIR)/%.c,$(OBJDIR)/%.d,$(patsubst $(SRCDIR)/%.cpp,$(OBJDIR)/%.d,$(SRCS)))

NODEPS := clean

.PHONY: clean

all: $(EXENAME)

ifeq (0, $(words $(findstring $(MAKECMDGOALS), $(NODEPS))))
-include $(DEPS)
endif

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@ -MD -MT '$@' -MF '$(patsubst $(OBJDIR)/%.o,$(OBJDIR)/%.d,$@)'

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@ -MD -MT '$@' -MF '$(patsubst $(OBJDIR)/%.o,$(OBJDIR)/%.d,$@)'

$(EXENAME): $(OBJS)
	$(CXX) $(OBJS) -o $@ $(LDFLAGS)

clean:
	rm -rf $(OBJDIR)
	rm -f $(EXENAME)

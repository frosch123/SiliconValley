PROJECT_NAME = "Silicon Valley"

SOURCES = *.nut
VERSION_NUT = version.nut
LANGFILES = lang/*.txt
DOCS = license.txt readme.txt
BANANAS_INI = bananas.ini

MUSA = musa.py
_V ?= @
_E ?= @echo

SAVEGAME_VERSION := $(shell grep SELF_VERSION $(VERSION_NUT) | sed 's/[^0-9]//g')
VERSION_INFO := "$(shell ./findversion.sh)"
REPO_VERSION := $(shell echo ${VERSION_INFO} | cut -f2)
REPO_DATE := $(shell echo ${VERSION_INFO} | cut -f7)

FULL_VERSION = $(SAVEGAME_VERSION)-$(REPO_VERSION)
BUNDLE_NAME := $(shell echo $(PROJECT_NAME) | sed 's/ /-/g')
BUNDLE_FILENAME = $(BUNDLE_NAME)-$(FULL_VERSION)

BUNDLE_DIR = bundle

.PHONY: all bananas bundle clean

all: bundle

clean:
	$(_E) "[CLEAN]"
	$(_V) rm -rf $(BUNDLE_DIR)

bundle: $(BUNDLE_DIR)/$(BUNDLE_FILENAME).tar

$(BUNDLE_DIR)/$(BUNDLE_FILENAME).tar: $(SOURCES) $(LANGFILES) $(DOCS)
	$(_E) "[Bundle] $@"
	$(_V) rm -rf $(BUNDLE_DIR)
	$(_V) mkdir -p $(BUNDLE_DIR)/$(BUNDLE_FILENAME)/lang
	$(_V) cp $(SOURCES) $(DOCS) $(BUNDLE_DIR)/$(BUNDLE_FILENAME)
	$(_V) cp $(LANGFILES) $(BUNDLE_DIR)/$(BUNDLE_FILENAME)/lang
	$(_V) sed -i 's/SELF_DATE.*/SELF_DATE <- "$(REPO_DATE)";/' $(BUNDLE_DIR)/$(BUNDLE_FILENAME)/$(VERSION_NUT)
	$(_V) cd $(BUNDLE_DIR); tar -cf $(BUNDLE_FILENAME).tar $(BUNDLE_FILENAME)

bananas: bundle
	$(_E) "[BaNaNaS]"
	$(_V) sed 's/^version *=.*/version = $(FULL_VERSION)/' $(BANANAS_INI) > $(BUNDLE_DIR)/$(BANANAS_INI)
	$(_V) $(MUSA) -r -x license.txt -c $(BUNDLE_DIR)/$(BANANAS_INI) $(BUNDLE_DIR)/$(BUNDLE_FILENAME)

PYRET=pyret-lang
SHELL=/usr/bin/env bash
PYRET_DEPS=$(PYRET) $(PYRET)/Makefile
NODE_PATH:=$(NODE_PATH):$(PYRET)/node_modules
NODE=node -max-old-space-size=8192
BUILD=build
ARR_SRC=src
RUNNER=run-lc
PHASE=
COMPILED=
EXTRA_BUILD_DEPS=
PYRET_COMPILER_SRCS=$(wildcard $(PYRET)/src/arr/compiler/*.arr) \
  $(wildcard $(PYRET)/src/arr/compiler/locators/*.arr) \
  $(wildcard $(PYRET)/src/js/trove/*.js) \
  $(wildcard $(PYRET)/src/arr/trove/*.arr)

ARR_SRCS=$(wildcard $(ARR_SRC)/*.arr)

.SUFFIXES += .arr .jarr .template

# check_defined courtesy of http://stackoverflow.com/a/10858332
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
        $(error Undefined $1$(if $2, ($2))$(if $(value @), \
                required by target '$@')))

ifeq ($(wildcard $(PYRET)),)
$(error Missing symlink to Pyret. \
  Please run 'ln -s <path-to-pyret-lang> ./$(PYRET)'.)
endif

.PHONY: all clean
all:
	$(error A specific target must be specified)

clean:
	rm -r $(BUILD)/compiled-*

.PHONY : phase0 phaseA phaseB phaseC build-program

phase0: build-program
phase0: PHASE=phase0
phase0: COMPILED=$(BUILD)/compiled-phase0
phase0: PYRET_COMPILER=$(PYRET)/build/phase0/pyret.jarr

phaseA: build-program
phaseA: PHASE=phaseA
phaseA: COMPILED=$(BUILD)/compiled-phaseA
phaseA: PYRET_DEPS += $(PYRET_COMPILER_SRCS)
phaseA: PYRET_COMPILER=$(PYRET)/build/phaseA/pyret.jarr

phaseB: build-program
phaseB: PHASE=phaseB
phaseB: COMPILED=$(BUILD)/compiled-phaseB
phaseB: PYRET_DEPS += $(PYRET_COMPILER_SRCS) $(PYRET)/build/phaseA/pyret.jarr
phaseB: PYRET_COMPILER=$(PYRET)/build/phaseB/pyret.jarr

phaseC: build-program
phaseC: PHASE=phaseC
phaseC: COMPILED=$(BUILD)/compiled-phaseC
phaseC: PYRET_DEPS += $(PYRET_COMPILER_SRCS) $(PYRET)/build/phaseA/pyret.jarr $(PYRET)/build/phaseB/pyret.jarr
phaseC: PYRET_COMPILER=$(PYRET)/build/phaseC/pyret.jarr

$(PYRET)/build/phaseA/js:
	@echo Building phaseA dependencies in pyret-lang
	cd $(PYRET)
	make phaseA-deps

build-deps: | $(PYRET)/build/phaseA/js

build-program: build-deps $(BUILD)/$(RUNNER).jarr $(BUILD)/$(RUNNER)

$(PYRET)/build/%/pyret.jarr: | $(PYRET_DEPS)
	@echo PHASE is \"$(PHASE)\"
	@:$(call check_defined, PHASE)
	$(if $(filter $(PHASE), phase0), \
	  $(shell cd $(PYRET) && make $(PHASE)), \
	  $(echo Using prebuilt compiler))

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/compiled-%: $(BUILD)
	mkdir -p $@

$(BUILD)/$(RUNNER).jarr: $(ARR_SRCS) $(PYRET_COMPILER) | $(COMPILED)
	@:$(call check_defined, PHASE, PYRET_COMPILER, COMPILED)
	$(NODE) $(PYRET)/build/$(PHASE)/pyret.jarr \
	  --builtin-arr-dir $(PYRET)/src/arr/trove \
	  --builtin-js-dir $(PYRET)/src/js/trove \
	  --require-config <(tools/generate-config.sh $(COMPILED) $(PYRET))  \
	  --standalone-file $(PYRET)/src/js/base/handalone.js \
	  --compiled-dir $(COMPILED) \
	  --build-runnable $(ARR_SRC)/$(RUNNER).arr \
	  -no-check-mode \
	  --outfile $@

$(BUILD)/$(RUNNER): tools/$(RUNNER).template
	cp $< $@
	chmod +x $@

# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

TOPLEVEL_LANG ?= verilog
SIM           ?= icarus

PWD=$(shell pwd)

# Matrix parameters
NB_DATA_IN       ?= 8
NB_DATA_OUT      ?= 11
N_INPUT_SAMPLES  ?= 3
N_OUTPUT_SAMPLES ?= 2

ifeq ($(TOPLEVEL_LANG),verilog)
    VERILOG_SOURCES = $(PWD)/../rtl/iir_filter.sv

    # Set module parameters
    ifeq ($(SIM),icarus)
        COMPILE_ARGS += -Piir_filter.NB_DATA_IN=$(NB_DATA_IN) -Piir_filter.NB_DATA_OUT=$(NB_DATA_OUT) -Piir_filter.N_INPUT_SAMPLES=$(N_INPUT_SAMPLES) -Piir_filter.N_OUTPUT_SAMPLES=$(N_OUTPUT_SAMPLES) -D COCOTB_SIM
    else ifeq ($(SIM),verilator)
        COMPILE_ARGS += -GNB_DATA_IN=$(NB_DATA_IN) -GNB_DATA_IN=$(NB_DATA_IN) -GNB_DATA_OUT=$(NB_DATA_OUT) -GN_OUTPUT_SAMPLES=$(N_OUTPUT_SAMPLES) -GN_INPUT_SAMPLES=$(N_INPUT_SAMPLES)
    else ifneq ($(iir_filter $(SIM),ius xcelium),)
        EXTRA_ARGS += -defparam "iir_filter.NB_DATA_IN=$(NB_DATA_IN)" -defparam "iir_filter.NB_SEL=$(NB_SEL)" -defparam "iir_filter.NB_DATA_OUT=$(NB_DATA_OUT)" -defparam "N_OUTPUT_SAMPLES=$(N_OUTPUT_SAMPLES)" -defparam "N_INPUT_SAMPLES=$(N_INPUT_SAMPLES)"
    endif

    ifneq ($(iir_filter $(SIM),riviera activehdl),)
        COMPILE_ARGS += -sv2k12
    endif
endif

# Fix the seed to ensure deterministic tests
export COCOTB_RANDOM_SEED := 123456789

TOPLEVEL := iir_filter
MODULE   := test_module

ifeq ($(SIM),ghdl)

all:
	@echo "Skipping since GHDL doesn't support constants effectively"

clean::

else

include $(shell cocotb-config --makefiles)/Makefile.sim

endif

# Profiling

DOT_BINARY ?= dot

test_profile.pstat: sim

callgraph.svg: test_profile.pstat
	$(shell cocotb-config --python-bin) -m gprof2dot -f pstats ./$< | $(DOT_BINARY) -Tsvg -o $@

.PHONY: profile
profile:
	COCOTB_ENABLE_PROFILING=1 $(MAKE) callgraph.svg

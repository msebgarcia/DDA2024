# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

TOPLEVEL_LANG ?= verilog
SIM ?= icarus

PWD=$(shell pwd)

# Matrix parameters
NB_DATA ?= 16
NB_SEL ?= 2

ifeq ($(TOPLEVEL_LANG),verilog)
    VERILOG_SOURCES = $(PWD)/../rtl/arith_operator.sv

    # Set module parameters
    ifeq ($(SIM),icarus)
        COMPILE_ARGS += -Parith_operator.NB_DATA=$(NB_DATA) -Parith_operator.NB_SEL=$(NB_SEL) -D COCOTB_SIM
    else ifeq ($(SIM),verilator)
        COMPILE_ARGS += -GNB_DATA_IN=$(NB_DATA) -GNB_SEL=$(NB_SEL)
    else ifneq ($(filter $(SIM),ius xcelium),)
        EXTRA_ARGS += -defparam "arith_operator.NB_DATA=$(NB_DATA)" -defparam "arith_operator.NB_SEL=$(NB_SEL)"
    endif

    ifneq ($(filter $(SIM),riviera activehdl),)
        COMPILE_ARGS += -sv2k12
    endif
endif

# Fix the seed to ensure deterministic tests
export COCOTB_RANDOM_SEED := 123456789

TOPLEVEL := arith_operator
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

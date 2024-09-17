import os
import sys
from pathlib import Path

import pytest
import random as rnd
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb_tools.runner import get_runner
from model import RtlModel

async def init_rst_and_clk(dut):
    cocotb.start_soon(Clock(dut.i_clk, 10, units="ns").start())
    tester = RtlModel(dut)

    dut.i_rst_n.value = 1
    dut.i_data1.value = 0
    dut.i_data2.value = 0 
    dut.i_sel.value   = 0
    await Timer(10, units='ns')
    dut.i_rst_n.value = 0
    await Timer(35, units='ns')
    dut.i_rst_n.value = 1
    tester.start()

@cocotb.test()
async def TC001(dut):
    """Testing output with selector in 2"""

    await init_rst_and_clk(dut)
    dut.i_data1.value = 1
    dut.i_data2.value = 2 
    dut.i_sel.value   = 2

    for _ in range(200):
        await RisingEdge(dut.i_clk)

@cocotb.test()
async def TC002(dut):
    """Testing output with selector in 0"""

    await init_rst_and_clk(dut)
    dut.i_data1.value = 1
    dut.i_data2.value = 2 
    dut.i_sel.value   = 0

    for _ in range(100):
        await RisingEdge(dut.i_clk)

@cocotb.test()
async def TC003(dut):
    """Testing output with selector in 1"""

    await init_rst_and_clk(dut)
    dut.i_data1.value = 3
    dut.i_data2.value = 2 
    dut.i_sel.value   = 1

    for _ in range(100):
        await RisingEdge(dut.i_clk)

@cocotb.test()
async def TC004(dut):
    """Testing output with selector in 1 and both data in 1"""

    await init_rst_and_clk(dut)
    dut.i_data1.value =  1
    dut.i_data2.value =  1 
    dut.i_sel.value   =  1
    count             = -1

    for _ in range(200):
        await RisingEdge(dut.i_clk)
        count += 1
        if (dut.o_overflow.value == 1):
            print(f"Clocks passed until overflow rises: {count}")
            count = 0

@cocotb.test()
async def TC005(dut):
    """Changing input with same selector"""

    await init_rst_and_clk(dut)
    dut.i_sel.value   = 1

    for _ in range(10):
        rnd_wait = rnd.randint(10,50)
        dut.i_data1.value = rnd.randint(0,2**(int(dut.NB_DATA_IN.value))-1)
        dut.i_data2.value = rnd.randint(0,2**(int(dut.NB_DATA_IN.value))-1)
        for _ in range (rnd_wait):
            await RisingEdge(dut.i_clk)

@cocotb.test()
async def TC006(dut):
    """Changing all inputs"""

    await init_rst_and_clk(dut)

    for _ in range(10):
        rnd_wait = rnd.randint(10,50)
        dut.i_sel.value   = rnd.randint(0,2)
        dut.i_data1.value = rnd.randint(0,2**(int(dut.NB_DATA_IN.value))-1)
        dut.i_data2.value = rnd.randint(0,2**(int(dut.NB_DATA_IN.value))-1)
        for _ in range (rnd_wait):
            await RisingEdge(dut.i_clk)


@cocotb.test()
async def TC007(dut):
    """Testing reset and recovery"""

    await init_rst_and_clk(dut)

    for _ in range(10):
        dut.i_data1.value = rnd.randint(0,2**(int(dut.NB_DATA_IN.value))-1)
        dut.i_data2.value = rnd.randint(0,2**(int(dut.NB_DATA_IN.value))-1)
        dut.i_sel.value   = rnd.randint(0,2)

        dut.i_rst_n.value = 0
        await Timer(rnd.randint(150,500), units='ns')

        dut.i_rst_n.value = 1
        await Timer(rnd.randint(150,500), units='ns')

@pytest.mark.skipif(
    os.getenv("SIM", "icarus") == "ghdl",
    reason="Skipping since GHDL doesn't support constants effectively",
)
def accum_runner():
    """Simulate the sum_accumulator example using the Python runner.

    This file can be run directly or via pytest discovery.
    """
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent

    build_args = []

    if hdl_toplevel_lang == "verilog":
        sources = [proj_path / "rtl" / "sum_accumulator.sv"]

        if sim in ["riviera", "activehdl"]:
            build_args = ["-sv2k12"]

    elif hdl_toplevel_lang == "vhdl":
        sources = [
            proj_path / "rtl" / "sum_accumulator_pkg.vhd",
            proj_path / "rtl" / "sum_accumulator.vhd",
        ]

        if sim in ["questa", "modelsim", "riviera", "activehdl"]:
            build_args = ["-2008"]
        elif sim == "nvc":
            build_args = ["--std=08"]
    else:
        raise ValueError(
            f"A valid value (verilog or vhdl) was not provided for TOPLEVEL_LANG={hdl_toplevel_lang}"
        )

    extra_args = ["--trace --trace-structs --define COCOTB_SIM"]

    parameters = {
        "NB_DATA_IN": 3,
        "NB_SEL": 2,
        "NB_DATA_OUT": 6,
    }

    # equivalent to setting the PYTHONPATH environment variable
    sys.path.append(str(proj_path / "tb"))

    runner = get_runner(sim)

    runner.build(
        hdl_toplevel="sum_accumulator",
        sources=sources,
        build_args=build_args + extra_args,
        parameters=parameters,
        always=True,
    )

    runner.test(
        hdl_toplevel="sum_accumulator",
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_module",
        test_args=extra_args,
    )

if __name__ == "__main__":
    accum_runner()

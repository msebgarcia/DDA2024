import os
import sys
from pathlib import Path
import random as rnd
import pytest
from cocotb.handle import SimHandleBase

import cocotb
from cocotb.triggers import Timer
from cocotb_tools.runner import get_runner
from cocotb.types import LogicArray, Range

class RtlModel:
    def __init__(self, dut: SimHandleBase):
        self.dut  = dut
        self.coro = None

    def start(self) -> None:
        if self.coro is not None:
            raise RuntimeError("Monitor already started")
        self.coro = cocotb.start_soon(self.run_beh(self.dut))

    def stop(self) -> None:
        if self.coro is None:
            raise RuntimeError("Monitor never started")
        self.coro.kill()
        self.coro = None

    async def run_beh(self, dut) -> None:
        while (True):
            await Timer(1, 'ns')
            obtained_data = dut.o_data_c.value
            if   (self.dut.i_sel.value == LogicArray('00', Range(int(dut.NB_SEL.value)-1, 'downto', 0))):
                assert obtained_data == LogicArray.from_signed(int(dut.i_data_a.value) + int(dut.i_data_b.value), Range(int(self.dut.NB_DATA.value)+1, "downto", 0))[int(self.dut.NB_DATA.value)-1:0]
            elif (self.dut.i_sel.value == LogicArray('01', Range(int(dut.NB_SEL.value)-1, 'downto', 0))):
                assert obtained_data == LogicArray.from_signed(int(dut.i_data_a.value) - int(dut.i_data_b.value), Range(int(self.dut.NB_DATA.value)+1, "downto", 0))[int(self.dut.NB_DATA.value)-1:0]
            elif (self.dut.i_sel.value == LogicArray('10', Range(int(dut.NB_SEL.value)-1, 'downto', 0))):
                assert dut.o_data_c.value == dut.i_data_a.value & dut.i_data_b.value
            else:
                assert obtained_data == dut.i_data_a.value or dut.i_data_b.value

async def init_test(dut):
    tester = RtlModel(dut)

    dut.i_sel.value    = 0
    dut.i_data_a.value = 0
    dut.i_data_b.value = 0
    await Timer(rnd.randint(10,50), 'ns')
    tester.start()

@cocotb.test()
async def TC001(dut):
    """Testing output with sum"""
    await init_test(dut)
    dut.i_sel.value    = 0
    for _ in range(100):
        dut.i_data_a.value = rnd.randint(-2**(int(dut.NB_DATA.value)-1),2**(int(dut.NB_DATA.value)-1)-1)
        dut.i_data_b.value = rnd.randint(-2**(int(dut.NB_DATA.value)-1),2**(int(dut.NB_DATA.value)-1)-1)
        await Timer(rnd.randint(10,50), 'ns')

@cocotb.test()
async def TC002(dut):
    """Testing output with subs"""
    await init_test(dut)
    dut.i_sel.value    = 1
    for _ in range(100):
        dut.i_data_a.value = rnd.randint(-2**(int(dut.NB_DATA.value)-1),2**(int(dut.NB_DATA.value)-1)-1)
        dut.i_data_b.value = rnd.randint(-2**(int(dut.NB_DATA.value)-1),2**(int(dut.NB_DATA.value)-1)-1)
        await Timer(rnd.randint(10,50), 'ns')

@cocotb.test()
async def TC003(dut):
    """Testing output with and"""
    await init_test(dut)
    dut.i_sel.value    = 2
    for _ in range(100):
        dut.i_data_a.value = rnd.randint(-2**(int(dut.NB_DATA.value)-1),2**(int(dut.NB_DATA.value)-1)-1)
        dut.i_data_b.value = rnd.randint(-2**(int(dut.NB_DATA.value)-1),2**(int(dut.NB_DATA.value)-1)-1)
        await Timer(rnd.randint(10,50), 'ns')

@cocotb.test()
async def TC004(dut):
    """Testing output with or"""
    await init_test(dut)
    dut.i_sel.value    = 3
    for _ in range(100):
        dut.i_data_a.value = rnd.randint(-2**(int(dut.NB_DATA.value)-1),2**(int(dut.NB_DATA.value)-1)-1)
        dut.i_data_b.value = rnd.randint(-2**(int(dut.NB_DATA.value)-1),2**(int(dut.NB_DATA.value)-1)-1)
        await Timer(rnd.randint(10,50), 'ns')

@cocotb.test()
async def TC005(dut):
    """Testing changing all inputs"""
    await init_test(dut)
    for _ in range(100):
        dut.i_sel.value    = rnd.randint(0, 2**int(dut.NB_SEL.value)-1)
        dut.i_data_a.value = rnd.randint(-2**(int(dut.NB_DATA.value)-1),2**(int(dut.NB_DATA.value)-1)-1)
        dut.i_data_b.value = rnd.randint(-2**(int(dut.NB_DATA.value)-1),2**(int(dut.NB_DATA.value)-1)-1)
        await Timer(rnd.randint(10,50), 'ns')

@pytest.mark.skipif(
    os.getenv("SIM", "icarus") == "ghdl",
    reason="Skipping since GHDL doesn't support constants effectively",
)
def accum_runner():
    """Simulate the arith_operator example using the Python runner.

    This file can be run directly or via pytest discovery.
    """
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent

    build_args = []

    if hdl_toplevel_lang == "verilog":
        sources = [proj_path / "rtl" / "arith_operator.sv"]

        if sim in ["riviera", "activehdl"]:
            build_args = ["-sv2k12"]

    elif hdl_toplevel_lang == "vhdl":
        sources = [
            proj_path / "rtl" / "arith_operator_pkg.vhd",
            proj_path / "rtl" / "arith_operator.vhd",
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
        "NB_DATA": 16,
        "NB_SEL": 2,
    }

    # equivalent to setting the PYTHONPATH environment variable
    sys.path.append(str(proj_path / "tb"))

    runner = get_runner(sim)

    runner.build(
        hdl_toplevel="arith_operator",
        sources=sources,
        build_args=build_args + extra_args,
        parameters=parameters,
        always=True,
    )

    runner.test(
        hdl_toplevel="arith_operator",
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_module",
        test_args=extra_args,
    )

if __name__ == "__main__":
    accum_runner()

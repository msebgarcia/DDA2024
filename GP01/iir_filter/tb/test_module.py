import os
import sys
from pathlib import Path

import pytest
import random as rnd
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb_tools.runner import get_runner
from cocotb.handle import SimHandleBase
from model import RtlModel
import numpy as np
from scipy import signal

async def init_rtl(dut):
    cocotb.start_soon(Clock(dut.i_clock, 10, units="ns").start())
    tester = RtlModel(dut)

    dut.i_reset.value = 0
    dut.i_data.value  = 0
    await RisingEdge(dut.i_clock)
    await RisingEdge(dut.i_clock)
    dut.i_reset.value = 1
    tester.start()
    await RisingEdge(dut.i_clock)
    await RisingEdge(dut.i_clock)
    dut.i_reset.value = 0
    await RisingEdge(dut.i_clock)

async def reset_rtl(dut):
    await RisingEdge(dut.i_clock)
    dut.i_reset.value = 0
    await RisingEdge(dut.i_clock)
    dut.i_reset.value = 1
    await RisingEdge(dut.i_clock)
    dut.i_reset.value = 0

async def run_sinusoidal_wave(dut: SimHandleBase, waiting_clocks: int, freq_in_hz: int, amplitude: int):
    sampling_freq = 1/(10e-9)
    for i in range(waiting_clocks):
        await RisingEdge(dut.i_clock)
        dut.i_data.value = int(amplitude*np.sin(2*np.pi*i*(freq_in_hz/sampling_freq)))

@cocotb.test()
async def TC001(dut):
    """TC001: Constant input"""
    await init_rtl(dut)
    dut.i_data.value = 3

    for _ in range(200):
        await RisingEdge(dut.i_clock)

@cocotb.test()
async def TC002(dut):
    """TC002: Change input every 5 clocks"""
    await init_rtl(dut)

    for _ in range(rnd.randint(5,20)):
        await RisingEdge(dut.i_clock)

    for _ in range(500):
        dut.i_data.value = rnd.randint(-100,100)
        for _ in range(5):
            await RisingEdge(dut.i_clock)

@cocotb.test()
async def TC003(dut):
    """TC003: 50kHz signal"""
    await init_rtl(dut)
    await run_sinusoidal_wave(dut = dut, waiting_clocks = 10000, freq_in_hz = 50000, amplitude = 20)

@cocotb.test()
async def TC004(dut):
    """TC004: 1MHz signal"""
    await init_rtl(dut)
    await run_sinusoidal_wave(dut = dut, waiting_clocks = 1000, freq_in_hz = 1000000, amplitude = 20)

@cocotb.test()
async def TC005(dut):
    """TC005: 10MHz signal"""
    await init_rtl(dut)
    await run_sinusoidal_wave(dut = dut, waiting_clocks = 1000, freq_in_hz = 10000000, amplitude = 20)

@cocotb.test()
async def TC006(dut):
    """TC006: Reset and recovery with square wave"""
    await init_rtl(dut)

    timespace     = np.linspace(0, 10000*10e-9, 10000, endpoint=False)
    square_signal = signal.square(2*np.pi*1e6*timespace, duty = 0.5)
    reset_times   = 3

    for value in square_signal:
        await RisingEdge(dut.i_clock)
        dut.i_data.value = 20*int(value)
        if (rnd.randint(0,1200) == 0) and (reset_times > 0):
            await reset_rtl(dut)
            reset_times -= 1


@pytest.mark.skipif(
    os.getenv("SIM", "icarus") == "ghdl",
    reason="Skipping since GHDL doesn't support constants effectively",
)
def accum_runner():
    """Simulate the iir_filter example using the Python runner.

    This file can be run directly or via pytest discovery.
    """
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "icarus")

    proj_path = Path(__file__).resolve().parent.parent

    build_args = []

    if hdl_toplevel_lang == "verilog":
        sources = [proj_path / "rtl" / "iir_filter.sv"]

        if sim in ["riviera", "activehdl"]:
            build_args = ["-sv2k12"]

    elif hdl_toplevel_lang == "vhdl":
        sources = [
            proj_path / "rtl" / "iir_filter_pkg.vhd",
            proj_path / "rtl" / "iir_filter.vhd",
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
        "NB_DATA_IN": 8,
        "NB_DATA_OUT": 12,
        "N_INPUT_SAMPLES": 3,
        "N_OUTPUT_SAMPLES": 2,
    }

    # equivalent to setting the PYTHONPATH environment variable
    sys.path.append(str(proj_path / "tb"))

    runner = get_runner(sim)

    runner.build(
        hdl_toplevel="iir_filter",
        sources=sources,
        build_args=build_args + extra_args,
        parameters=parameters,
        always=True,
    )

    runner.test(
        hdl_toplevel="iir_filter",
        hdl_toplevel_lang=hdl_toplevel_lang,
        test_module="test_module",
        test_args=extra_args,
    )

if __name__ == "__main__":
    accum_runner()

from typing import Any, Dict, List

import cocotb
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray, Range

class DataMonitor:
    def __init__(self, i_clock: SimHandleBase, i_data: Dict[str, SimHandleBase]):
        self.values = Queue[Dict[str, int]]()
        self.clock  = i_clock
        self.data   = i_data
        self.coro   = None

    def start(self) -> None:
        if self.coro is not None:
            raise RuntimeError("Monitor already started")
        self.coro = cocotb.start_soon(self.run())

    def stop(self) -> None:
        if self.coro is None:
            raise RuntimeError("Monitor never started")
        self.coro.kill()
        self.coro = None

    async def run(self) -> None:
        while True:
            await RisingEdge(self.clock)
            self.values.put_nowait(self.sample())

    def sample(self) -> Dict[str, Any]:
        return {name: handle.value for name, handle in self.data.items()}

    def clear_queue(self):
        self.values = Queue[Dict[str, int]]()

class RtlModel:
    def __init__(self, dut: SimHandleBase):
        self.sum = 0
        self.dut = dut

        self.input_monitor = DataMonitor(
            i_clock = self.dut.i_clk,
            i_data  = dict(in1 = self.dut.i_data1, in2 = self.dut.i_data2, sel = self.dut.i_sel)
        )

        self.output_monitor = DataMonitor(
            i_clock = self.dut.i_clk,
            i_data  = dict(data = self.dut.o_data, overflow = self.dut.o_overflow)
        )

        self.checker = None

    def clear_monitors(self) -> None:
        self.input_monitor.clear_queue()
        self.output_monitor.clear_queue()

    def start(self) -> None:
        if self.checker is not None:
            raise RuntimeError("Monitor already started")
        self.input_monitor.start()
        self.output_monitor.start()
        self.checker = cocotb.start_soon(self._check())

    def stop(self) -> None:
        if self.checker is None:
            raise RuntimeError("Monitor never started")
        self.input_monitor.stop()
        self.output_monitor.stop()
        self.checker.kill()
        self.checker = None

    def beh_model(self, in1: int, in2: int, sel: int) -> List[LogicArray]:
        if (sel == 0):
            self.sum += int(in2)
        elif (sel == 1):
            self.sum += int(in1)+int(in2)
        elif (sel == 2):
            self.sum += int(in1)

        max_sum_value = 2**int(self.dut.NB_DATA_OUT.value)
        oflow = self.sum >= max_sum_value
        if (oflow):
            self.sum -= max_sum_value

        returning_sum   = LogicArray.from_signed(self.sum, Range(int(self.dut.NB_DATA_OUT.value)+1, "downto", 0))
        returning_oflow = LogicArray('1' if oflow else '0', Range(0, "downto", 0))

        return [returning_sum, returning_oflow]

    async def _check(self) -> None:
        delayed_inputs = []

        while True:
            outputs = await self.output_monitor.values.get()

            try:
                inputs = self.input_monitor.values.get_nowait()
            except:
                await RisingEdge(self.dut.i_clk)
                continue
            
            delayed_inputs.append(inputs)

            if len(delayed_inputs) > 1:
                delayed_input = delayed_inputs.pop(0)
                expected = self.beh_model(in1 = delayed_input["in1"], in2 = delayed_input["in2"], sel = delayed_input["sel"])
                # print(f'Expected: {expected[0]} | Got: {outputs["data"]}')
                # assert outputs["data"]     == expected[0][int(self.dut.NB_DATA_OUT.value)-1:0]
                # assert outputs["overflow"] == expected[1]

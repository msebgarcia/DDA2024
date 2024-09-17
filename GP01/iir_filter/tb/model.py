from typing import Any, Dict, List

import cocotb
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray, Range

class DataMonitor:
    def __init__(self, i_clock: SimHandleBase, i_data: Dict[str, SimHandleBase], queue_size: int, nb_data: int):
        self.values      = Queue[Dict[str, LogicArray]]()
        self.clock       = i_clock
        self.data        = i_data
        self.min_samples = queue_size
        self.nb_data     = nb_data
        self.coro        = None
        self.set_start_point()

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
        return {name: LogicArray(handle.value, Range(self.nb_data-1, 'downto', 0)) for name, handle in self.data.items()}

    def set_start_point(self) -> None:
        for _ in range (self.min_samples):
            self.values.put_nowait({name: LogicArray.from_signed(0) for name, _ in self.data.items()})

    def get_n_sample(self, n_sample: LogicArray):
        return self.values._queue[-1-n_sample]["data"]

    def clear_queue(self):
        self.values = Queue[Dict[str, int]]()
        self.set_start_point()

    def get_number_of_samples(self) -> int:
        return self.values.qsize()

class RtlModel:
    def __init__(self, dut: SimHandleBase):
        self.dut = dut

        self.input_monitor = DataMonitor(
            i_clock = self.dut.i_clock,
            i_data  = dict(data = self.dut.i_data),
            queue_size = int(self.dut.N_INPUT_SAMPLES.value),
            nb_data = int(self.dut.NB_DATA_IN.value)
        )

        self.output_monitor = DataMonitor(
            i_clock = self.dut.i_clock,
            i_data  = dict(data = self.dut.o_data) ,
            queue_size = int(self.dut.N_OUTPUT_SAMPLES.value),
            nb_data = int(self.dut.NB_DATA_OUT.value)
        )

        self.checker  = None

    def clear_monitors(self) -> None:
        self.input_monitor .clear_queue()
        self.output_monitor.clear_queue()

    def start(self) -> None:
        if self.checker is not None:
            raise RuntimeError("Monitor already started")
        self.input_monitor .start()
        self.output_monitor.start()
        self.checker = cocotb.start_soon(self._check())

    def stop(self) -> None:
        if self.checker is None:
            raise RuntimeError("Monitor never started")
        self.input_monitor .stop()
        self.output_monitor.stop()
        self.checker.kill()
        self.checker = None

    async def _check(self) -> None:
        while True:
            await RisingEdge(self.dut.i_clock)
            if (int(self.dut.i_reset.value) == 1):
                self.clear_monitors()
                continue

            result  = self.input_monitor.get_n_sample(0) .to_signed()
            result -= self.input_monitor.get_n_sample(1) .to_signed()
            result += self.input_monitor.get_n_sample(2) .to_signed()
            result += self.input_monitor.get_n_sample(3) .to_signed()
            result += self.output_monitor.get_n_sample(2).to_signed()//4
            result += self.output_monitor.get_n_sample(1).to_signed()//2

            # print(f'Result: {result} | Got: {self.output_monitor.get_n_sample(0).to_signed()} ')
            assert result == self.output_monitor.get_n_sample(0).to_signed()

            _ = self.output_monitor.values.get_nowait()
            _ = self.input_monitor.values.get_nowait()

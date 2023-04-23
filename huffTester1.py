import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge, Timer

@cocotb.test()
async def huffTester1(dut):
    # initialize inputs
    dut.data_in.value = 0x00
    dut.data_en.value = 0
    dut.done.value = 0

    # start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.fork(clock.start())

    # send input data
    input_data = [0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x57, 0x6F, 0x72, 0x6C, 0x64]  # "Hello World"
    for data in input_data:
        dut.data_in.value = data
        dut.data_en.value = 1
        await RisingEdge(dut.clk)
        dut.data_en.value = 0
        await Timer(1, units="ns")

    # wait for output data
    output_data = []
    while not dut.done.value:
        await RisingEdge(dut.clk)
        
    if dut.done.value:
        output_data.append(int(dut.encoded_value.value))

    # check output data
    expected_output = [0x48, 0x65, 0x6C, 0x6C, 0x6F, 0x20, 0x57, 0x6F, 0x72, 0x6C, 0x64]  # same as input
    assert output_data == expected_output, f"Expected {expected_output}, but got {output_data}"

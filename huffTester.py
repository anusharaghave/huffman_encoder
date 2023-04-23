import math
import os
import random
from typing import Any, Dict, List

import heapq
from collections import defaultdict

import cocotb
from cocotb.binary import BinaryValue
from cocotb.clock import Clock
from cocotb.handle import SimHandleBase
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge, ReadOnly
#from cocotb.log import log

import numpy as np

async def huffman_encode(data):
    freq = {}
    for d in data:
        if d in freq:
            freq[d] += 1
        else:
            freq[d] = 1

    nodes = []
    for f in freq:
        nodes.append((f, freq[f]))

    while len(nodes) > 1:
        nodes = sorted(nodes, key=lambda x: x[1])
        left = nodes.pop(0)
        right = nodes.pop(0)
        nodes.append((None, left[1] + right[1], left, right))

    codes = {}
    def assign_codes(node, code=''):
        if node[0] is not None:
            codes[node[0]] = code
        else:
            assign_codes(node[2], code+'0')
            assign_codes(node[3], code+'1')
    assign_codes(nodes[0])

    output_data = []
    for d in data:
        output_data.extend([BinaryValue(c, n_bits=3) for c in codes[d]])
    
    return output_data

@cocotb.test()
async def test_huffman_encoder(dut):
    # Initialize input and output signals
    #dut.input_valid <= 0
    #dut.input_data <= BinaryValue(0)
    #dut.input_freq <= BinaryValue(0)
    dut.io_in.value <= 0
    #dut.output_ready <= 0

    io_in = dut.io_in

    # Define input data
    input_data = [
        (ord('a'), 1),  #char, freq
        (ord('b'), 5),
        (ord('c'), 3),
      #  (ord('d'), 2)
    ]
    
    # Encode input data using golden model
  #  expected_output_data = await huffman_encode([d[0] for d in io_in])

    # Send input data to dut cycle by cycle
    for data in input_data:
        #dut.input_valid <= 1
        io_in_value = (1 << 11) |  (data[1] << 8) | data[0]
        #dut.io_in.value = BinaryValue(io_in_value, n_bits=12)
        dut.io_in.value = io_in_value & 0b111111111111
        #dut.input_freq <= BinaryValue(data[1], n_bits=8)
        await RisingEdge(dut.clk)
        #dut.input_valid <= 0
        await ClockCycles(dut.clk, 1)

    # Wait for output data from dut
  

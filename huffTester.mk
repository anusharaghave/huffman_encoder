TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell pwd)/huff_enc.v
TOPLEVEL = huff_encoder
MODULE = huffTester
include $(shell cocotb-config --makefiles)/Makefile.sim

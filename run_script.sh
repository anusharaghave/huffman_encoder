source /afs/club.cc.cmu.edu/projects/stuco-open-eda/bashrc

python huff_test.py

sv2v huff_enc.sv > huff_enc.v
sv2v huff_enc_tb.sv > huff_enc_tb.v
iverilog -o sim huff_enc_tb.v huff_enc.v
./sim
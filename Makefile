tb_top:
	vcs -sverilog -R -top tb_top -debug_access+all huff_enc.sv huff_enc_tb.sv

tb_top_gui:
	vcs -sverilog -R -top tb_top -debug_access+all huff_enc.sv huff_enc_tb.sv -gui

clean:
	rm -rf simv.daidir/
	rm -rf simv
	rm -rf csrc
	rm -rf DVEfiles
	rm -f ucli.key
	rm -f inter.vpd
	rm -f .restartSimSession.tcl.old
	rm -f .__*

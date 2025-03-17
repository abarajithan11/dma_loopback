set XIL_PATH=F:\Xilinx\Vivado\2022.2\bin
set TB_MODULE=top_tb

SETLOCAL EnableDelayedExpansion
mkdir build/data
cd build
powershell -command "[System.IO.File]::WriteAllBytes('data/input.bin', (0..255 * 4)[0..1023])"

call %XIL_PATH%\xsc ../../c/sim.c --gcc_compile_options -DSIM || exit /b !ERRORLEVEL!
call %XIL_PATH%\xvlog -sv -f ../sources.txt || exit /b !ERRORLEVEL!
call %XIL_PATH%\xelab %TB_MODULE% --snapshot %TB_MODULE% -log elaborate.log --debug typical -sv_lib dpi || exit /b !ERRORLEVEL!
call %XIL_PATH%\xsim %TB_MODULE% --tclbatch ../xsim_cfg.tcl
set XIL_PATH=F:\Xilinx\Vivado\2022.2\bin
set TB_MODULE=top_tb

SETLOCAL EnableDelayedExpansion
mkdir "build\data"
cd build
set DIR_BACKSLASH="%CD%/data/"
set "DIR=%DIR_BACKSLASH:\=/%"
set BYTES=1024

call %XIL_PATH%\xsc ../../c/sim.c --gcc_compile_options -DSIM --gcc_compile_options "-DBYTES=%BYTES%" --gcc_compile_options "-DDIR=%DIR%" || exit /b !ERRORLEVEL!
call %XIL_PATH%\xvlog -sv -d "DIR=%DIR%" -d "BYTES=%BYTES%" -f ../sources.txt || exit /b !ERRORLEVEL!
call %XIL_PATH%\xelab %TB_MODULE% --snapshot %TB_MODULE% -log elaborate.log --debug typical -sv_lib dpi || exit /b !ERRORLEVEL!
call %XIL_PATH%\xsim %TB_MODULE% --tclbatch ../xsim_cfg.tcl
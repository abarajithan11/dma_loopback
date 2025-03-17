set PROJECT_NAME loopback_xil_zcu104

put "To be run from run/work" 

app create -name dsf_app -os {standalone} -proc {psu_cortexa53_0} -lang {c} -arch {64} -hw $PROJECT_NAME/design_1_wrapper.xsa -out vitis_workspace;
app config -name dsf_app -append libraries {m}
app config -name dsf_app -set compiler-optimization {Optimize most (-O3)}
app config -name dsf_app -add include-path D:/dnn-engine/deepsocflow/c/
app config -name dsf_app -add include-path D:/dnn-engine/run/work/


cp D:/dnn-engine/deepsocflow/c/xilinx_example.c C:/Users/abara/workspace/dsf_app/src/helloworld.c
app build -name dsf_app
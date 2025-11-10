@echo off
echo Compiling VGA design...
vlib work
vlog top.v testbench.v
if %errorlevel% == 0 (echo ✅ Compilation successful!) else (echo ❌ Compilation failed!)
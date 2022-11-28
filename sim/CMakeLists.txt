cmake_minimum_required(VERSION 3.8)

project(z80computer)

find_package(verilator HINTS $ENV{VERILATOR_ROOT} ${VERILATOR_ROOT})
if (NOT verilator_FOUND)
  message(FATAL_ERROR "Verilator was not found. Either install it, or set the VERILATOR_ROOT environment variable")
endif()

option(TRACE "ON or OFF" ON)

set(CMAKE_BUILD_TYPE DEBUG)

# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O0 -g")

# ${PROJECT_SOURCE_DIR}

add_executable(simulation sim.cpp ../import/uartmaster/sim/uart.cpp console.cpp disk.cpp)

target_include_directories(simulation PUBLIC ../import/uartmaster/sim)
# target_compile_definitions(simulation PUBLIC EDGE_DETECTION)

if(TRACE)
target_compile_definitions(simulation PUBLIC TRACE)
endif()


message(STATUS "${PROJECT_SOURCE_DIR}/../rtl")

# Add the Verilated circuit to the target
verilate(simulation TRACE
    SOURCES     ../fpga/top.v
                ../rtl/z80computer.v
                ../import/tv80/rtl/core/tv80_alu.v
                ../import/tv80/rtl/core/tv80_core.v
                ../import/tv80/rtl/core/tv80_mcode.v
                ../import/tv80/rtl/core/tv80_reg.v
                ../import/tv80/rtl/core/tv80n.v
                ../import/tv80/rtl/core/tv80s.v
                ../import/uartmaster/rtl/fifo.v
                ../import/uartmaster/rtl/UartMasterSlave.v
                ../import/uartmaster/rtl/UartProtocol.v
                ../import/uartmaster/rtl/uart_rx.v
                ../import/uartmaster/rtl/uart_tx.v

    VERILATOR_ARGS
                --language 1364-2005
                --no-timing
                +define+SIM
#                -Wall
#                +librescan
#                +libext+.v
#                -CFLAGS "-g" -O0

    TOP_MODULE  top

    THREADS 8
  )

add_custom_command(OUTPUT test.bin
    COMMAND z80asm --list=test.lst --label=test.sym -o test.bin ${PROJECT_SOURCE_DIR}/test.asm
	COMMAND hexdump -ve '1/1 \"%02x \"' test.bin > test.mem
    DEPENDS test.asm
    COMMENT "Assembling test program"
)

add_custom_target(sim
    COMMAND simulation ${CMAKE_BINARY_DIR}/test.bin
    DEPENDS test.bin
    COMMENT "Executing simulation..."
)

add_custom_target(wave
    COMMAND gtkwave ${PROJECT_SOURCE_DIR}/sim.gtkw
    DEPENDS sim
)

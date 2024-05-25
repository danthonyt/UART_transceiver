import cocotb
from cocotb.triggers import FallingEdge
from cocotb.queue import QueueEmpty, Queue
import enum
import logging
import pyuvm


# #### The alu_prediction function
# Figure 5: The prediction function for the scoreboard
def uart_prediction(data_byte_rx,data_byte_tx):
    """Python model of the uart"""
    # received data will be output to a data bus
    # 8 bit value (without start and stop bit)
    rx_op_parallel = f'{data_byte_rx:08b}'
    # transmitted data will be output serially
    # 10 bit value (with start and stop bit) 
    tx_op_serial = "0" + f'{data_byte_tx:08b}' + "1"
    results_tuple = (rx_op_parallel,tx_op_serial)
    return results_tuple



# #### The logger

# Figure 6: Setting up logging using the logger variable
logging.basicConfig(level=logging.NOTSET)
logger = logging.getLogger()
logger.setLevel(logging.DEBUG)


# ### Reading a signal value
# Figure 6: get_int() converts a bus to an integer
# turning a value of x or z to 0
def get_int(signal):
    try:
        int_val = int(signal.value)
    except ValueError:
        int_val = 0
    return int_val

# ## The TinyAluBfm singleton
# ### Initializing the TinyAluBfm object


# Figure 3: Initializing the TinyAluBfm singleton
class uartBFM(metaclass=pyuvm.Singleton):
    def __init__(self):
        self.dut = cocotb.top
        self.cmd_driver_queue = Queue(maxsize=1)
        self.cmd_mon_queue = Queue(maxsize=0)
        self.result_mon_queue = Queue(maxsize=0)

# ### The reset coroutine

# Figure 4: Centralizing the reset function
    async def reset(self):
        await FallingEdge(self.dut.clk)
        self.dut.reset.value = 1
        await FallingEdge(self.dut.clk)
        self.dut.reset.value = 0
        await FallingEdge(self.dut.clk)

# ## The communication coroutines
# #### result_mon()

# Figure 6: Monitoring the result bus
    async def result_mon(self):
        while True:
            await FallingEdge(self.dut.clk)
            start = get_int(self.dut.start)
            if start == 1:
                # sample all bits transmitted
                # find middle of start bit
                for _ in range(44):
                    await FallingEdge(self.dut.clk)
                # sample start bit to stop bit transmitted
                tx_op_serial = ""
                for index in range(0,10):
                    tx_op_serial += str(get_int(self.dut.serial_tx))
                    # move to next bit
                    for _ in range(87):
                        await FallingEdge(self.dut.clk)
                rx_op_parallel = get_int(self.dut.dout_rx)
                result_tuple = (rx_op_parallel,tx_op_serial)
                self.result_mon_queue.put_nowait(result_tuple)

# #### cmd_mon()
# Figure 7: Monitoring the command signals
    async def cmd_mon(self):
        while True:
 
            await FallingEdge(self.dut.clk)
            start = get_int(self.dut.start)
            if start == 1:
                # received data will be input serially
                # 10 bit value (with start and stop bit)             
                rx_ip_serial = ""
                # sample all bits received
                for _ in range(44):
                    await FallingEdge(self.dut.clk)
                # sample start bit to stop bit received
                for index in range(0,10):
                    rx_ip_serial += str(get_int(self.dut.serial_rx))
                    for _ in range(87):
                        await FallingEdge(self.dut.clk)
                # transmitted data will be input from a data bus
                # 10 bit value (with start and stop bit) 
                # no need to sample
                tx_ip_parallel = get_int(self.dut.din_tx)
                cmd_tuple = (tx_ip_parallel, rx_ip_serial)
                self.cmd_mon_queue.put_nowait(cmd_tuple)

# #### driver()
# Figure 8: Driving commands on the falling edge of clk
    async def cmd_driver(self):
        self.dut.start.value = 0
        self.dut.serial_rx.value = 1
        self.dut.din_tx.value = 0
        while True:
            await FallingEdge(self.dut.clk)
            st = get_int(self.dut.start)
            dn = get_int(self.dut.done)
# Figure 9: Driving commands to the TinyALU when
# start and done are 0
            if st == 0 and dn == 0:
                try:
                    # cmd is transmit data and and receive data 
                    (tx_ip_parallel, rx_ip_serial) = self.cmd_driver_queue.get_nowait()
                    self.dut.start.value = 1
                    # drive tx input data for Tx.
                    self.dut.din_tx.value = tx_ip_parallel
                    await FallingEdge(self.dut.clk)
                    # drive start bit to stop bit received
                    for index in range(0,10):
                        self.dut.serial_rx = rx_ip_serial[index]
                        for _ in range(87):
                            await FallingEdge(self.dut.clk)
                except QueueEmpty:
                    continue
# Figure 10: If start is 1 check done
            elif st == 1:
                if dn == 1:
                    self.dut.start.value = 0

# ### Launching the coroutines using start_soon
# Figure 11: Start the BFM coroutines
    def start_tasks(self):
        cocotb.start_soon(self.cmd_driver())
        cocotb.start_soon(self.cmd_mon())
        cocotb.start_soon(self.result_mon())

# Figure 12: The get_cmd() coroutine returns the next command
    async def get_cmd(self):
        cmd = await self.cmd_mon_queue.get()
        return cmd

# Figure 13: The get_result() coroutine returns the next result
    async def get_result(self):
        result = await self.result_mon_queue.get()
        return result

# Figure 14: send_op puts the command into the command Queue
    async def send_op(self, tx_ip_parallel,rx_ip_serial):
        command_tuple = (tx_ip_parallel,rx_ip_serial)
        await self.cmd_driver_queue.put(command_tuple)
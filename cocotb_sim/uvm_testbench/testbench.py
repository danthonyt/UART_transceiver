import pyuvm
from pyuvm import *
import cocotb
from cocotb.triggers import ClockCycles
import random
from pathlib import Path
import sys 
sys.path.insert(0, str(Path("..").resolve()))
from uart_utils import uartBfm, uart_prediction, logger, format_uart_msg, format_uart_bus

# ## The BaseTester class
# Common behavior across all tests
class BaseTester(uvm_component):

    def build_phase(self):
        self.pp = uvm_put_port("pp",self)

    async def run_phase(self):
        self.raise_objection()
        self.bfm = uartBfm()
        '''
        ops = list(Ops)
        for op in ops:
            input_tx_data,input_rx_data = self.get_operands()
            await self.bfm.send_op(input_tx_data,input_rx_data,op)
        '''
        input_tx_data,input_rx_uart_payload = self.get_operands()
        cmd_tuple = (input_tx_data,input_rx_uart_payload)
        await self.pp.put(cmd_tuple)
        await ClockCycles(signal=cocotb.top.clk,num_cycles=1000,rising=False)
        self.drop_objection()
    
    def get_operands(self):
        raise RuntimeError("You must extend BaseTester and override get_operands().")
        


# ### The RandomTester
# RandomTester overrides get_operands
class RandomTester(BaseTester):
    def get_operands(self):
        return random.randint(0,255),((random.randint(0,255)<<1) & ~(1<<9)|(1))
    

# ### The MaxTester
# MaxTester overrides get_operands
class MaxTester(BaseTester):
    def get_operands(self):
        return 0xFF,((0xFF<<1) & ~(1<<9)|(1))



# The driver refactored to work with sequences
class Driver(uvm_driver):
    
    def start_of_simulation_phase(self):
        self.bfm = uartBfm()

    async def run_phase(self):
        await self.bfm.reset()
        self.bfm.start_tasks()
        while True:
            cmd = await self.seq_item_port.get_next_item()
            await self.bfm.send_op(cmd.input_tx_data,cmd.input_rx_uart_payload)
            self.seq_item_port.item_done()



# The Monitor() class takes the method name 
# as an instantiation argument
class Monitor(uvm_monitor):
    def __init__(self, name, parent, method_name):
        super().__init__(name, parent)
        self.method_name = method_name

    def build_phase(self):
        self.ap = uvm_analysis_port("ap",self)
        self.bfm = uartBfm()
        self.get_method = getattr(self.bfm,self.method_name)

    async def run_phase(self):
        while True:
            datum = await self.get_method()
            self.ap.write(datum)



'''
# class for coverage
class Coverage(uvm_analysis_export):

    def start_of_simulation_phase(self):
        self.cvg = set()


    def write(self,cmd):
        _,_,op = cmd
        self.cvg.add(Ops(op))

    def check_phase(self):
        if len(set(Ops) - self.cvg) > 0:
            self.logger.error(
                f"Functional coverage error. Missed: {set(Ops)-self.cvg}")
            assert False
        else:
            self.logger.info("Covered all operations")
'''
        

# ## The Scoreboard class
# ### Initialize the scoreboard
# initializing the Scoreboard   
# using uvm_tlm_analysis_fifo to provide 
# multiple analysis_exports
# and creating ports to read fifos
class Scoreboard(uvm_component):

    def build_phase(self):
        self.cmd_mon_fifo = uvm_tlm_analysis_fifo("cmd_mon_fifo",self)
        self.result_mon_fifo = uvm_tlm_analysis_fifo("result_mon_fifo",self)
        self.cmd_gp = uvm_get_port("cmd_gp",self)
        self.result_gp = uvm_get_port("result_gp",self)

    def connect_phase(self):
        self.cmd_gp.connect(self.cmd_mon_fifo.get_export)
        self.result_gp.connect(self.result_mon_fifo.get_export)
        self.cmd_export = self.cmd_mon_fifo.analysis_export
        self.result_export = self.result_mon_fifo.analysis_export
        

    # checking results after the run_phase

    def check_phase(self):
        passed = True
        while True:
            got_next_cmd,cmd = self.cmd_gp.try_get()
            if not got_next_cmd:
                break
            result_exists,actual = self.result_gp.try_get()
            if not result_exists:
                raise RuntimeError(f"Missing result for command {cmd}")
            input_tx_data, input_rx_uart_payload = cmd
            prediction = uart_prediction(input_tx_data,input_rx_uart_payload)
            if actual == prediction:
                self.logger.info(   f"PASSED: INPUT TX DATABUS : " + format_uart_bus(input_tx_data) + " "
                                    f"INPUT RX MSG : " + format_uart_msg(input_rx_uart_payload) + " => "
                                    f"OUTPUT TX MSG : " + format_uart_msg(actual[0]) + " "
                                    f"OUTPUT RX DATABUS : " + format_uart_bus(actual[1]) + " "
                                )
            else:
                passed = False
                self.logger.error(   f"FAILED: 8 bit input tx_din : {input_tx_data:08b}  10 bit input rx_msg : {input_rx_uart_payload:010b} "
                                f'= 10 bit output tx_msg : {actual[0]:010b} - predicted : {prediction[0]:010b}'
                                f' 8 bit output rx_dout : {actual[1]:08b} - predicted : {prediction[1]:08b}')
            assert passed
    '''
    # define the data gathering tasks
    # The scoreboard gets a command
    async def get_cmd(self):
        while True:
            cmd = await self.bfm.get_cmd()
            self.cmds.append(cmd)

    # The scoreboard gets a result
    async def get_result(self):
        while True:
            result = await self.bfm.get_result()
            self.results.append(result)

    def start_of_simulation_phase(self):
        self.bfm = uartBfm()
        self.cmds = []
        self.results = []
        #self.cvg = set()
        cocotb.start_soon(self.get_cmd())
        cocotb.start_soon(self.get_result())
    '''
# all environments need the scoreboard

# using the factory to instantiate the BaseTester
class UartEnv(uvm_env):
    
    def build_phase(self):
        self.seqr = uvm_sequencer("seqr",self)
        ConfigDB().set(None,"*","SEQR",self.seqr)
        self.driver = Driver("driver",self)
        self.scoreboard = Scoreboard("scoreboard",self)
        #self.coverage = Coverage("coverage",self)
        self.cmd_mon = Monitor("cmd_monitor",self,"get_cmd")
        self.result_mon = Monitor("result_monitor",self,"get_result")

    def connect_phase(self):
        self.driver.seq_item_port.connect(self.seqr.seq_item_export)
        #self.cmd_mon.ap.connect(self.coverage.analysis_export)
        self.cmd_mon.ap.connect(self.scoreboard.cmd_export)
        self.result_mon.ap.connect(self.scoreboard.result_export)

    
    def start_of_simulation_phase(self):
        uartBfm().start_tasks()

class BaseEnv(uvm_env):
    """Instantiate the scoreboard"""

    def build_phase(self):
        self.scoreboard = Scoreboard("scoreboard",self)

class RandomEnv(BaseEnv):
    """Generate random operands"""


    def build_phase(self):
        super().build_phase()
        self.tester = RandomTester("tester",self)


class MaxEnv(BaseEnv):
    """Generate maximum operands"""


    def build_phase(self):
        super().build_phase()
        self.tester = MaxTester("tester",self)

# The BaseTest class is an abstract class with no build_phase()
'''
class BaseTest(uvm_test):
    async def run_phase(self):
        self.raise_objection()
        bfm = uartBfm()
        scoreboard = Scoreboard()
        await bfm.reset()
        bfm.start_tasks()
        scoreboard.start_tasks()     
        await self.tester.execute()
        passed = scoreboard.check_results()
        assert passed
        self.drop_objection()     
'''

# Defining the Uart Command as a sequence item


class UartSeqItem(uvm_sequence_item):

    def __init__(self,name,tx,rx):
        super().__init__(name)
        self.T = tx
        self.R = rx
        #self.op = Ops(op)
    
    def __eq__(self,other):
        same = self.T == other.T and self.R == other.R
        # and self.op == other.op
        return same
    def __str__(self):
        return f"{self.get_name()}:T:{format_uart_bus(self.T)}\
            R:{format_uart_msg(self.R)}"
        '''
        return f"{self.get_name()}:T:0x{format_uart_bus(self.T)}\
            Op:{self.op.name}({self.op.value})R:{format_uart_msg(self.R)}"
        '''

# Instantiating the right environment in each test
@pyuvm.test()
class RandomTest(uvm_test):
    """Run with random operands"""
    def build_phase(self):
        uvm_factory().set_type_override_by_type(BaseTester,RandomTester)
        self.env = UartEnv("env",self)

@pyuvm.test()
class MaxTest(uvm_test):
    """Run with max operands"""
    def build_phase(self):
        uvm_factory().set_type_override_by_type(BaseTester,MaxTester)
        self.env = UartEnv("env",self)
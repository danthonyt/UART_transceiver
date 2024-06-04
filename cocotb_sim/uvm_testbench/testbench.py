import pyuvm
from pyuvm import *
import cocotb
import random
from pathlib import Path
import sys 
sys.path.insert(0, str(Path("..").resolve()))
from uart_utils import uartBfm, uart_prediction, logger, format_uart_msg, format_uart_bus

# ## The BaseTester class
# Common behavior across all tests
class BaseTester(uvm_component):

    def get_operands(self):
        raise RuntimeError("You must extend BaseTester and override get_operands().")
    
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
        await self.bfm.send_op(input_tx_data,input_rx_uart_payload)
        # send two dummy operations to allow
        # last real operation to complete
        await self.bfm.send_op(0, 0)
        await self.bfm.send_op(0, 0)
        self.drop_objection()
    # The code beyond this point never runs due to exceptions
    '''
    def start_of_simulation_phase(self):
        uartBfm().start_tasks()
    '''  
        


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
    
# ## The Scoreboard class
# ### Initialize the scoreboard
# initializing the Scoreboard   
class Scoreboard(uvm_component):

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
        

    # checking results after the run_phase

    def check_phase(self):
        passed = True
        for cmd in self.cmds:
            input_tx_data, input_rx_uart_payload = cmd
            #op = Ops(op_int)
            #self.cvg.add(op)
            actual = self.results.pop(0)
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
            """""
            if actual == prediction:
                self.logger.info(f"PASSED: 8 bit input tx_din : {input_tx_data:02x}  10 bit input rx_msg : {input_rx_uart_payload:03x} "
                            f"= 10 bit output tx_msg : {actual[0]:03x} 8 bit output rx_dout : {actual[1]:02x}")
            else:
                passed = False
                self.logger.error(   f"FAILED: 8 bit input tx_din : {input_tx_data:08b}  10 bit input rx_msg : {input_rx_uart_payload:010b} "
                                f'= 10 bit output tx_msg : {actual[0]:010b} - predicted : {prediction[0]:010b}'
                                f' 8 bit output rx_dout : {actual[1]:08b} - predicted : {prediction[1]:08b}')
            """""
            '''
            The scoreboard checks functional coverage
            if len(set(Ops) - self.cvg) > 0:
                logger.error(
                    f"Functional coverage error. Missed: {set(Ops)-self.cvg}"
                    passed = False
                )
            else:
                logger.info("Covered all operations")
            '''
            assert passed
        
# all environments need the scoreboard

# using the factory to instantiate the BaseTester
class UartEnv(uvm_env):
    """Instantiate the scoreboard"""
    
    def build_phase(self):
        self.scoreboard = Scoreboard("scoreboard",self)
        self.tester = BaseTester.create("tester",self)
    
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
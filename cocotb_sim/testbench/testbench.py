import cocotb
import random
from pathlib import Path
import sys 
sys.path.insert(0, str(Path("..").resolve()))
from uart_utils import uartBfm, uart_prediction, logger

# ## The BaseTester class
# Common behavior across all tests
class BaseTester():

    async def execute(self):
        self.bfm = uartBfm()
        input_tx_data,input_rx_uart_payload = self.get_operands()
        '''
        ops = list(Ops)
        for op in ops:
            input_tx_data,input_rx_data = self.get_operands()
            await self.bfm.send_op(input_tx_data,input_rx_data,op)
        '''
        await self.bfm.send_op(input_tx_data,input_rx_uart_payload)
        
        # send two dummy operations to allow
        # last real operation to complete
        await self.bfm.send_op(0, 0)
        await self.bfm.send_op(0, 0)
        


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
class Scoreboard():
    def __init__(self):
        self.bfm = uartBfm()
        self.cmds = []
        self.results = []
        #self.cvg = set()

    # define the data gathering tasks
    # The scoreboard gets a command

    async def get_cmds(self):
        while True:
            cmd = await self.bfm.get_cmd()
            self.cmds.append(cmd)
    
    # The scoreboard gets a result
    async def get_result(self):
        while True:
            result = await self.bfm.get_result()
            self.results.append(result)

    # The Scoreboard's start_tasks() function

    # The scoreboard launches data-gathering tasks
    def start_tasks(self):
        cocotb.start_soon(self.get_cmds())
        cocotb.start_soon(self.get_result())

    # The scoreboard's check_results() function
    # The check_results() phase
    def check_results(self):
        passed = True
        for cmd in self.cmds:
            input_tx_data, input_rx_uart_payload = cmd
            #op = Ops(op_int)
            #self.cvg.add(op)
            actual = self.results.pop(0)
            prediction = uart_prediction(input_tx_data,input_rx_uart_payload)
            if actual == prediction:
                logger.info(f"PASSED: 8 bit input tx_din : {input_tx_data:02x}  10 bit input rx_msg : {input_rx_uart_payload:03x} "
                            f"= 10 bit output tx_msg : {actual[0]:03x} 8 bit output rx_dout : {actual[1]:02x}")
            else:
                passed = False
                logger.error(   f"FAILED: 8 bit input tx_din : {input_tx_data:08b}  10 bit input rx_msg : {input_rx_uart_payload:010b} "
                                f'= 10 bit output tx_msg : {actual[0]:010b} - predicted : {prediction[0]:010b}'
                                f' 8 bit output rx_dout : {actual[1]:08b} - predicted : {prediction[1]:08b}')
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
            return passed
        

# The execute_test() coroutine
# The execute_test() coroutine runs the test 
async def execute_test(tester_class):
    bfm = uartBfm()
    scoreboard = Scoreboard()
    await bfm.reset()
    bfm.start_tasks()
    scoreboard.start_tasks()     
# execute the tester
    tester = tester_class()
    await tester.execute()
    passed = scoreboard.check_results()
    return passed      


# ## The cocotb tests
# cocotb will launch the execute_test coroutine
@cocotb.test()
async def random_test(_):
    """Random operands"""
    passed = await execute_test(RandomTester)
    assert passed


@cocotb.test()
async def max_test(_):
    """Maximum operands"""
    passed = await execute_test(MaxTester)
    assert passed
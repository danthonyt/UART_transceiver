import cocotb
import random
import sys 
from pathlib import Path
current_path = Path("..").resolve()
sys.path.insert(0,str(current_path))
from uart_utils import logger, get_int


# ## The cocotb test
# Figure 15: Starting a test by resetting the DUT
# and starting the BFM tasks
@cocotb.test()
async def test_alu(_):
    """Test all TinyALU Operations"""
    passed = True
    bfm = uartBFM()
    await bfm.reset()
    bfm.start_tasks()
# ### Sending commands
    #cvg = set()
# Figure 16: Creating a command and sending it
    for _ in range(10):
        txdata = random.randint(0, 255)
        rxdata = []
        rxdata[0] = 0
        for index in range(1,8):
            rxdata[index] = random.randint(0,1)
        rxdata[9] = 1
        await bfm.send_op(txdata,rxdata)
# ### Monitoring commands
# Figure 17: Wait to get the command from the DUT
# and store it in the coverage set
        seen_cmd = await bfm.get_cmd()
        #seen_op = Ops(seen_cmd[2])
        #cvg.add(seen_op)
# Figure 18: Wait for the result, then create a prediction
        results_tuple = await bfm.get_result()
        pr_tuple = uart_prediction(rxdata, txdata)
# Figure 19: Check the result against the predicted result
        if results_tuple == pr_tuple:
            logger.info(f"PASSED: {txdata:02x}  {rxdata:03x} = {results_tuple[0]:04x} {results_tuple[1]:}")
        else:
            logger.error(f"FAILED: {txdata:02x} {rxdata:03x} = "
                         f"{results_tuple[0]:04x} - predicted {pr_tuple[0]:04x}"
                         f"{results_tuple[1]:04x} - predicted {pr_tuple[1]:04x}")
            passed = False

    #if len(set(Ops) - cvg) > 0:
    #    logger.error(f"Functional coverage error. Missed: {set(Ops)-cvg}")
     #   passed = False
    #else:
    #    logger.info("Covered all operations")
# Figure 20: Assert that we passed to pass to cocotb
    assert passed
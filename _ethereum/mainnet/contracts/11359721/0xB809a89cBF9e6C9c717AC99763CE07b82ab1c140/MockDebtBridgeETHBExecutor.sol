// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;

// import "./console.sol"; // Uncomment this line for using gasLeft Method
import "./IGelatoCore.sol";
import "./IGelatoCore.sol";
import "./IGelatoExecutors.sol";
import "./GelatoBytes.sol";

/// @dev Automatic gas-reporting for ConnectGelatoDataFullRefinanceMaker ETHA => ETHB
//   via hardhat-gas-reporter
contract MockDebtBridgeETHBExecutor {
    using GelatoBytes for bytes;
    address public gelatoCore;

    constructor(address _gelatoCore) payable {
        gelatoCore = _gelatoCore;
        IGelatoExecutors(gelatoCore).stakeExecutor{value: msg.value}();
    }

    function canExec(
        TaskReceipt calldata _taskReceipt,
        uint256 _gasLimit,
        uint256 _execTxGasPrice
    ) external view returns (string memory) {
        return
            IGelatoCore(gelatoCore).canExec(
                _taskReceipt,
                _gasLimit,
                _execTxGasPrice
            );
    }

    function exec(TaskReceipt memory _taskReceipt) public {
        // uint256 gasLeft = gasleft();
        IGelatoCore(gelatoCore).exec(_taskReceipt);
        // console.log("Gas Cost for Task Execution %s", gasLeft - gasleft());
    }

    function execViaRoute0(TaskReceipt memory _taskReceipt) public {
        // uint256 gasLeft = gasleft();
        IGelatoCore(gelatoCore).exec(_taskReceipt);
        // console.log("Gas Cost execViaRoute0: %s", gasLeft - gasleft());
    }

    function execViaRoute0AndOpenVault(TaskReceipt memory _taskReceipt) public {
        // uint256 gasLeft = gasleft();
        IGelatoCore(gelatoCore).exec(_taskReceipt);
        // console.log(
        //     "Gas Cost execViaRoute0AndOpenVault: %s",
        //     gasLeft - gasleft()
        // );
    }

    function execViaRoute1(TaskReceipt memory _taskReceipt) public {
        // uint256 gasLeft = gasleft();
        IGelatoCore(gelatoCore).exec(_taskReceipt);
        // console.log("Gas Cost execViaRoute1: %s", gasLeft - gasleft());
    }

    function execViaRoute1AndOpenVault(TaskReceipt memory _taskReceipt) public {
        // uint256 gasLeft = gasleft();
        IGelatoCore(gelatoCore).exec(_taskReceipt);
        // console.log(
        //     "Gas Cost execViaRoute1AndOpenVault: %s",
        //     gasLeft - gasleft()
        // );
    }

    function execViaRoute2(TaskReceipt memory _taskReceipt) public {
        // uint256 gasLeft = gasleft();
        IGelatoCore(gelatoCore).exec(_taskReceipt);
        // console.log("Gas Cost execViaRoute2: %s", gasLeft - gasleft());
    }

    function execViaRoute2AndOpenVault(TaskReceipt memory _taskReceipt) public {
        // uint256 gasLeft = gasleft();
        IGelatoCore(gelatoCore).exec(_taskReceipt);
        // console.log(
        //     "Gas Cost execViaRoute2AndOpenVault %s",
        //     gasLeft - gasleft()
        // );
    }

    function execViaRoute3(TaskReceipt memory _taskReceipt) public {
        // uint256 gasLeft = gasleft();
        IGelatoCore(gelatoCore).exec(_taskReceipt);
        // console.log("Gas Cost execViaRoute3: %s", gasLeft - gasleft());
    }

    function execViaRoute3AndOpenVault(TaskReceipt memory _taskReceipt) public {
        // uint256 gasLeft = gasleft();
        IGelatoCore(gelatoCore).exec(_taskReceipt);
        // console.log(
        //     "Gas Cost execViaRoute3AndOpenVAult: %s",
        //     gasLeft - gasleft()
        // );
    }
}

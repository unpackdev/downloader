// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;

import "./IGelatoCore.sol";
import "./IGelatoProviders.sol";
import "./IGelatoExecutors.sol";
import "./IGelatoSysAdmin.sol";
import "./Address.sol";
import "./GelatoTaskReceipt.sol";

/// @title MockExecutor
/// @notice Contract that masks any executor address behind one permitted address
/// @dev UNSAFE TO USE on mainnet because racing collisions and withdrawExcess by anone
contract MockExecutor {
    using Address for address payable;
    using GelatoTaskReceipt for TaskReceipt;

    struct Response {
        uint256 taskReceiptId;
        uint256 taskGasLimit;
        string response;
    }

    address public gelatoCore;

    constructor(address _gelatoCore) payable {
        gelatoCore = _gelatoCore;
        if (msg.value >= IGelatoSysAdmin(_gelatoCore).minExecutorStake())
            IGelatoExecutors(_gelatoCore).stakeExecutor{value: msg.value}();
    }

    function setGelatoCore(address _gelatoCore) external {
        gelatoCore = _gelatoCore;
    }

    function stakeExecutor() external payable {
        IGelatoExecutors(gelatoCore).stakeExecutor{value: msg.value}();
    }

    function unstakeExecutor() external {
        uint256 stake =
            IGelatoProviders(gelatoCore).executorStake(address(this));
        IGelatoExecutors(gelatoCore).unstakeExecutor();
        payable(msg.sender).sendValue(stake);
    }

    function withdrawExcessExecutorStake(uint256 _withdrawAmount)
        external
        payable
    {
        payable(msg.sender).sendValue(
            IGelatoExecutors(gelatoCore).withdrawExcessExecutorStake(
                _withdrawAmount
            )
        );
    }

    /// @dev This aggregates results and saves network provider requests
    function multiCanExec(
        TaskReceipt[] memory _taskReceipts,
        uint256 _gelatoGasPrice
    ) external view returns (uint256 blockNumber, Response[] memory responses) {
        blockNumber = block.number;
        uint256 gelatoMaxGas = IGelatoSysAdmin(gelatoCore).gelatoMaxGas();
        responses = new Response[](_taskReceipts.length);
        for (uint256 i = 0; i < _taskReceipts.length; i++) {
            uint256 taskGasLimit = getGasLimit(_taskReceipts[i], gelatoMaxGas);
            try
                IGelatoCore(gelatoCore).canExec(
                    _taskReceipts[i],
                    taskGasLimit,
                    _gelatoGasPrice
                )
            returns (string memory response) {
                responses[i] = Response({
                    taskReceiptId: _taskReceipts[i].id,
                    taskGasLimit: taskGasLimit,
                    response: response
                });
            } catch {
                responses[i] = Response({
                    taskReceiptId: _taskReceipts[i].id,
                    taskGasLimit: taskGasLimit,
                    response: "MockExecutor.multiCanExec: failed"
                });
            }
        }
    }

    /// @notice only the hardcoded Executors can call this
    /// @dev Caution: there is no built-in coordination mechanism between the
    /// Executors. Only one Executor should be live at all times, lest they
    /// will incur tx collision costs.
    function exec(TaskReceipt calldata _taskReceipt) external {
        // solhint-disable-next-line no-empty-blocks
        try IGelatoCore(gelatoCore).exec(_taskReceipt) {} catch Error(
            string memory error
        ) {
            revert(string(abi.encodePacked("MockExecutor.exec:", error)));
        } catch {
            revert("MockExecutor.exec:unknown error");
        }
    }

    function multiReassignProviders(
        address[] calldata _providers,
        address _newExecutor
    ) external {
        IGelatoExecutors(gelatoCore).multiReassignProviders(
            _providers,
            _newExecutor
        );
    }

    function getGasLimit(TaskReceipt memory _taskReceipt, uint256 _gelatoMaxGas)
        public
        pure
        returns (uint256)
    {
        if (_taskReceipt.selfProvider())
            return _taskReceipt.task().selfProviderGasLimit;
        return _gelatoMaxGas;
    }
}

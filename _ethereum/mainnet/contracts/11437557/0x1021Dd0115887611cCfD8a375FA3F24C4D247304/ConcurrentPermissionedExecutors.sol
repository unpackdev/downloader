// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import "./PermissionedExecutors.sol";
import "./IGelatoCore.sol";
import "./IGelatoProviders.sol";
import "./IGelatoExecutors.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";

/// @title ConcurrentPermissionedExecutors
/// @notice Contract to organize a multitude of Executor accounts as one whole.
contract ConcurrentPermissionedExecutors is PermissionedExecutors {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    enum SlotStatus {Open, Closing, Closed}

    uint256 public slotLength = 20; // blocks => ~ 5 minutes

    constructor(address _gelatoCore, address _gelatoProvider)
        PermissionedExecutors(_gelatoCore, _gelatoProvider)
    {} // solhint-disable-line no-empty-blocks

    // ======= SLOT ALLOCATION APIs ========
    function setSlotLength(uint256 _slotLength) public virtual onlyOwner {
        slotLength = _slotLength;
    }

    // Example: blocksPerSlot = 3, numberOfExecutors = 2
    //
    // Block number          0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | ...
    //                      ---------------------------------------------
    // slotIndex             0 | 0 | 0 | 1 | 1 | 1 | 2 | 2 | 2 | 3 | ...
    //                      ---------------------------------------------
    // executorIndex         0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 1 | ...
    // remainingBlocksInSlot 2 | 1 | 0 | 2 | 1 | 0 | 2 | 1 | 0 | 2 | ...
    //
    function calcExecutorIndex(
        uint256 _currentBlock,
        uint256 _blocksPerSlot,
        uint256 _numberOfExecutors
    )
        public
        pure
        virtual
        returns (uint256 executorIndex, uint256 remainingBlocksInSlot)
    {
        uint256 slotIndex = _currentBlock / _blocksPerSlot;
        return (
            slotIndex % _numberOfExecutors,
            (slotIndex + 1) * _blocksPerSlot - _currentBlock - 1
        );
    }

    function indexOfExectuor(address _executor)
        public
        view
        virtual
        returns (uint256)
    {
        return _executors._inner._indexes[bytes32(uint256(_executor))] - 1;
    }

    function currentExecutor()
        public
        view
        virtual
        returns (
            address executor,
            uint256 executorIndex,
            uint256 remainingBlocksInSlot
        )
    {
        (executorIndex, remainingBlocksInSlot) = calcExecutorIndex(
            block.number,
            slotLength,
            _executors.length()
        );
        executor = executorAt(executorIndex);
    }

    function mySlotStatus(uint256 _buffer)
        public
        view
        virtual
        returns (SlotStatus)
    {
        (uint256 executorIndex, uint256 remainingBlocksInSlot) =
            calcExecutorIndex(block.number, slotLength, _executors.length());

        address executor = executorAt(executorIndex);

        if (msg.sender != executor) {
            return SlotStatus.Closed;
        }

        return
            remainingBlocksInSlot <= _buffer
                ? SlotStatus.Closing
                : SlotStatus.Open;
    }

    function bufferedMultiCanExec(
        TaskReceipt[] memory _taskReceipts,
        uint256 _gelatoGasPrice,
        uint256 _buffer
    )
        public
        view
        virtual
        returns (
            SlotStatus slotStatus,
            uint256 blockNumber,
            Reponse[] memory responses
        )
    {
        slotStatus = mySlotStatus(_buffer);
        (blockNumber, responses) = _multiCanExec(
            _taskReceipts,
            _gelatoGasPrice
        );
    }

    function exec(TaskReceipt calldata _taskReceipt) external virtual override {
        _exec(_taskReceipt);
    }
}

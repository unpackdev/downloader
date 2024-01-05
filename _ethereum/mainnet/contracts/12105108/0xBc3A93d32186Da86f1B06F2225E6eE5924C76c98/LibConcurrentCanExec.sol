// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./LibExecutor.sol";

library LibConcurrentCanExec {
    using LibExecutor for address;

    enum SlotStatus {Open, Closing, Closed}

    struct ConcurrentExecStorage {
        uint256 slotLength;
    }

    bytes32 private constant _CONCURRENT_EXEC_STORAGE_POSITION =
        keccak256("gelato.diamond.concurrentexec.storage");

    function setSlotLength(uint256 _slotLength) internal {
        concurrentExecStorage().slotLength = _slotLength;
    }

    function slotLength() internal view returns (uint256) {
        return concurrentExecStorage().slotLength;
    }

    function concurrentCanExec(uint256 _buffer) internal view returns (bool) {
        return
            msg.sender.canExec() && LibExecutor.numberOfExecutors() == 1
                ? true
                : mySlotStatus(_buffer) == LibConcurrentCanExec.SlotStatus.Open;
    }

    function getCurrentExecutorIndex()
        internal
        view
        returns (uint256 executorIndex, uint256 remainingBlocksInSlot)
    {
        uint256 numberOfExecutors = LibExecutor.numberOfExecutors();
        uint256 currentSlotLength = slotLength();
        require(
            numberOfExecutors > 0,
            "LibConcurrentCanExec.getCurrentExecutorIndex: 0 executors"
        );
        require(
            currentSlotLength > 0,
            "LibConcurrentCanExec.getCurrentExecutorIndex: 0 slotLength"
        );

        return
            calcExecutorIndex(
                block.number,
                currentSlotLength,
                numberOfExecutors
            );
    }

    function currentExecutor()
        internal
        view
        returns (
            address executor,
            uint256 executorIndex,
            uint256 remainingBlocksInSlot
        )
    {
        (executorIndex, remainingBlocksInSlot) = getCurrentExecutorIndex();
        executor = LibExecutor.executorAt(executorIndex);
    }

    function mySlotStatus(uint256 _buffer) internal view returns (SlotStatus) {
        (uint256 executorIndex, uint256 remainingBlocksInSlot) =
            getCurrentExecutorIndex();

        address executor = LibExecutor.executorAt(executorIndex);

        if (msg.sender != executor) return SlotStatus.Closed;

        return
            remainingBlocksInSlot <= _buffer
                ? SlotStatus.Closing
                : SlotStatus.Open;
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
        internal
        pure
        returns (uint256 executorIndex, uint256 remainingBlocksInSlot)
    {
        uint256 slotIndex = _currentBlock / _blocksPerSlot;
        return (
            slotIndex % _numberOfExecutors,
            (slotIndex + 1) * _blocksPerSlot - _currentBlock - 1
        );
    }

    function concurrentExecStorage()
        internal
        pure
        returns (ConcurrentExecStorage storage ces)
    {
        bytes32 position = _CONCURRENT_EXEC_STORAGE_POSITION;
        assembly {
            ces.slot := position
        }
    }
}

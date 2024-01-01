// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

library StakeQueue {
    struct QueueStorage {
        mapping(uint256 => StakeInfo) data;
        uint32 first;
        uint32 last;
    }

    struct StakeInfo {
        uint32 blockNum;
        uint96 amount;
        uint32 keyPosition;
    }

    modifier isNotEmpty(QueueStorage storage queue) {
        require(!isEmpty(queue), 'Queue is empty.');
        _;
    }

    /**
     * @dev Sets the queue's initial state, with a queue size of 0.
     * @param queue QueueStorage struct from contract.
     */
    function initialize(QueueStorage storage queue) internal {
        queue.first = 1;
        queue.last = 0;
    }

    /**
     * @dev Gets the number of elements in the queue. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function length(QueueStorage storage queue) internal view returns (uint256) {
        if (queue.last < queue.first) {
            return 0;
        }
        return queue.last - queue.first + 1;
    }

    /**
     * @dev Returns if queue is empty. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function isEmpty(QueueStorage storage queue) internal view returns (bool) {
        return length(queue) == 0;
    }

    /**
     * @dev Adds an element to the back of the queue. O(1)
     * @param queue QueueStorage struct from contract.
     * @param blockNumber_ blocknumber when balance data is added.
     * @param amount_ blocknumber when balance data is added.
     * @param keyPosition_ a key to help user.queue and pool.queue to reference each other
     */
    function enqueue(
        QueueStorage storage queue,
        uint32 blockNumber_,
        uint96 amount_,
        uint32 keyPosition_
    ) internal {
        queue.data[++queue.last] = StakeInfo({ blockNum: blockNumber_, amount: amount_, keyPosition: keyPosition_ });
    }

    /**
     * @dev Removes an element from the front of the queue and returns it. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function dequeue(QueueStorage storage queue) internal isNotEmpty(queue) returns (StakeInfo memory data) {
        unchecked {   
            data = queue.data[queue.first];
        }
        delete queue.data[queue.first++];
    }

    /**
     * @dev Returns the data from the front of the queue, without removing it. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function peek(QueueStorage storage queue) internal view isNotEmpty(queue) returns (StakeInfo storage) {
        return queue.data[queue.first];
    }

    /**
     * @dev Returns the data from the back of the queue. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function peekLast(QueueStorage storage queue) internal view isNotEmpty(queue) returns (StakeInfo storage) {
        return queue.data[queue.last];
    }
}

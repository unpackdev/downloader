// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library BalanceQueue {
    
    struct QueueStorage {
        mapping(uint32 => BalanceData) data;
        uint32 first;
        uint32 last;
    }

    struct BalanceData {
        uint32 blockNumber;
        uint96 value;
    }

    modifier isNotEmpty(QueueStorage storage queue) {
        require(!_isEmpty(queue), "Queue is empty.");
        _;
    }

    /**
     * @dev Sets the queue's initial state, with a queue size of 0.
     * @param queue QueueStorage struct from contract.
     */
    function _initialize(QueueStorage storage queue) internal {
        queue.first = 1;
        queue.last = 0;
    }

    /**
     * @dev Gets the number of elements in the queue. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _length(QueueStorage storage queue)
        internal
        view
        returns (uint256)
    {
        if (queue.last < queue.first || queue.last == 0) {
            return 0;
        }
        return queue.last - queue.first + 1;
    }

    /**
     * @dev Returns if queue is empty. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _isEmpty(QueueStorage storage queue) internal view returns (bool) {
        return _length(queue) == 0;
    }

    /**
     * @dev Adds an element to the back of the queue. O(1)
     * @param queue QueueStorage struct from contract.
     * @param blockNumber_ blocknumber when balance data is added.
     * @param value_ blocknumber when balance data is added.
     */
    function _enqueue(
        QueueStorage storage queue,
        uint32 blockNumber_,
        uint96 value_
    ) internal {
        queue.data[++queue.last] = BalanceData({blockNumber: blockNumber_,value: value_});
    }

    /**
     * @dev Removes an element from the front of the queue and returns it. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _dequeue(QueueStorage storage queue)
        internal
        isNotEmpty(queue)
        returns (BalanceData memory data)
    {
        data = queue.data[queue.first];
        delete queue.data[queue.first++];
    }

    /**
     * @dev Returns the data from the front of the queue, without removing it. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _peek(QueueStorage storage queue)
        internal
        view
        isNotEmpty(queue)
        returns (BalanceData storage)
    {
        return queue.data[queue.first];
    }

    /**
     * @dev Returns the data from the back of the queue. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _peekLast(QueueStorage storage queue)
        internal
        view
        isNotEmpty(queue)
        returns (BalanceData storage)
    {
        return queue.data[queue.last];
    }    
}

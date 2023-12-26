// SPDX-License-Identifier: MIT
// @unsupported: ovm
pragma solidity >0.5.0 <0.8.0;
pragma experimental ABIEncoderV2;

/* Library Imports */
import "./Lib_NVMCodec.sol";
import "./Lib_AddressResolver.sol";
import "./Lib_MerkleTree.sol";

/* Interface Imports */
import "./iNVM_MessageQueue.sol";
import "./iNVM_ChainStorageContainer.sol";

/* Contract Imports */
import "./NVM_ExecutionManager.sol";

/* External Imports */
import "./Math.sol";

/**
 * @title NVM_MessageQueue
 * @dev TODO
 *
 * Compiler used: solc
 * Runtime target: EVM
 */
contract NVM_MessageQueue is iNVM_MessageQueue, Lib_AddressResolver {

    /*************
     * Constants *
     *************/

    // L2 tx gas-related
    uint256 constant public MIN_ROLLUP_TX_GAS = 100000;
    uint256 constant public MAX_ROLLUP_TX_SIZE = 50000;
    uint256 constant public L2_GAS_DISCOUNT_DIVISOR = 32;

    /*************
     * Variables *
     *************/

    uint256 public forceInclusionPeriodSeconds;
    uint256 public forceInclusionPeriodBlocks;
    uint256 public maxTransactionGasLimit;


    /***************
     * Constructor *
     ***************/

    constructor(
        address _libAddressManager,
        uint256 _maxTransactionGasLimit
    )
        Lib_AddressResolver(_libAddressManager)
    {
        maxTransactionGasLimit = _maxTransactionGasLimit;
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Accesses the queue storage container.
     * @return Reference to the queue storage container.
     */
    function queue()
        override
        public
        view
        returns (
            iNVM_ChainStorageContainer
        )
    {
        return iNVM_ChainStorageContainer(
            resolve("NVM_ChainStorageContainer-message-queue")
        );
    }

    /**
     * Gets the queue element at a particular index.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function getQueueElement(
        uint256 _index
    )
        override
        public
        view
        returns (
            Lib_NVMCodec.QueueElement memory _element
        )
    {
        return _getQueueElement(
            _index,
            queue()
        );
    }

   /**
     * Retrieves the length of the queue, including
     * both pending and canonical transactions.
     * @return Length of the queue.
     */
    function getQueueLength()
        override
        public
        view
        returns (
            uint40
        )
    {
        return _getQueueLength(
            queue()
        );
    }

    /**
     * Adds a transaction to the queue.
     * @param _target Target L2 contract to send the transaction to.
     * @param _gasLimit Gas limit for the enqueued L2 transaction.
     * @param _data Transaction data.
     */
    function enqueue(
        address _target,
        uint256 _gasLimit,
        bytes memory _data
    )
        override
        public
    {
        require(
            _data.length <= MAX_ROLLUP_TX_SIZE,
            "Transaction data size exceeds maximum for rollup transaction."
        );

        require(
            _gasLimit <= maxTransactionGasLimit,
            "Transaction gas limit exceeds maximum for rollup transaction."
        );

        require(
            _gasLimit >= MIN_ROLLUP_TX_GAS,
            "Transaction gas limit too low to enqueue."
        );

        // We need to consume some amount of L1 gas in order to rate limit transactions going into
        // L2. However, L2 is cheaper than L1 so we only need to burn some small proportion of the
        // provided L1 gas.
        uint256 gasToConsume = _gasLimit/L2_GAS_DISCOUNT_DIVISOR;
        uint256 startingGas = gasleft();

        // Although this check is not necessary (burn below will run out of gas if not true), it
        // gives the user an explicit reason as to why the enqueue attempt failed.
        require(
            startingGas > gasToConsume,
            "Insufficient gas for L2 rate limiting burn."
        );

        // Here we do some "dumb" work in order to burn gas, although we should probably replace
        // this with something like minting gas token later on.
        uint256 i;
        while(startingGas - gasleft() < gasToConsume) {
            i++;
        }

        bytes32 transactionHash = keccak256(
            abi.encode(
                msg.sender,
                _target,
                _gasLimit,
                _data
            )
        );

        bytes32 timestampAndBlockNumber;
        assembly {
            timestampAndBlockNumber := timestamp()
            timestampAndBlockNumber := or(timestampAndBlockNumber, shl(40, number()))
        }

        iNVM_ChainStorageContainer queueRef = queue();

        queueRef.push(transactionHash);
        queueRef.push(timestampAndBlockNumber);

        // The underlying queue data structure stores 2 elements
        // per insertion, so to get the real queue length we need
        // to divide by 2 and subtract 1.
        uint256 queueIndex = queueRef.length() / 2 - 1;
        emit TransactionEnqueued(
            msg.sender,
            _target,
            _gasLimit,
            _data,
            queueIndex,
            block.timestamp
        );
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Gets the queue element at a particular index.
     * @param _index Index of the queue element to access.
     * @return _element Queue element at the given index.
     */
    function _getQueueElement(
        uint256 _index,
        iNVM_ChainStorageContainer _queueRef
    )
        internal
        view
        returns (
            Lib_NVMCodec.QueueElement memory _element
        )
    {
        // The underlying queue data structure stores 2 elements
        // per insertion, so to get the actual desired queue index
        // we need to multiply by 2.
        uint40 trueIndex = uint40(_index * 2);
        bytes32 transactionHash = _queueRef.get(trueIndex);
        bytes32 timestampAndBlockNumber = _queueRef.get(trueIndex + 1);

        uint40 elementTimestamp;
        uint40 elementBlockNumber;
        // solhint-disable max-line-length
        assembly {
            elementTimestamp   :=         and(timestampAndBlockNumber, 0x000000000000000000000000000000000000000000000000000000FFFFFFFFFF)
            elementBlockNumber := shr(40, and(timestampAndBlockNumber, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000))
        }
        // solhint-enable max-line-length

        return Lib_NVMCodec.QueueElement({
            transactionHash: transactionHash,
            timestamp: elementTimestamp,
            blockNumber: elementBlockNumber
        });
    }

    /**
     * Retrieves the length of the queue.
     * @return Length of the queue.
     */
    function _getQueueLength(
        iNVM_ChainStorageContainer _queueRef
    )
        internal
        view
        returns (
            uint40
        )
    {
        // The underlying queue data structure stores 2 elements
        // per insertion, so to get the real queue length we need
        // to divide by 2.
        return uint40(_queueRef.length() / 2);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "./Ownable.sol";

import "./IStarknetCore.sol";

import "./IAggregatorsFactory.sol";
import "./IAggregator.sol";

import "./Uint256Splitter.sol";

contract L1MessagesSender is Ownable {
    using Uint256Splitter for uint256;

    IStarknetCore public immutable starknetCore;

    uint256 public l2RecipientAddr;

    IAggregatorsFactory public aggregatorsFactory;

    /// @dev L2 "receive_commitment" L1 handler selector
    uint256 constant RECEIVE_COMMITMENT_L1_HANDLER_SELECTOR =
        0x3fa70707d0e831418fb142ca8fb7483611b84e89c0c42bf1fc2a7a5c40890ad;

    /// @dev L2 "receive_mmr" L1 handler selector
    uint256 constant RECEIVE_MMR_L1_HANDLER_SELECTOR =
        0x36c76e67f1d589956059cbd9e734d42182d1f8a57d5876390bb0fcfe1090bb4;

    /// @param starknetCore_ a StarknetCore address to send and consume messages on/from L2
    /// @param l2RecipientAddr_ a L2 recipient address that is the recipient contract on L2.
    /// @param aggregatorsFactoryAddr_ Herodotus aggregators factory address (where MMR trees are referenced)
    constructor(
        IStarknetCore starknetCore_,
        uint256 l2RecipientAddr_,
        address aggregatorsFactoryAddr_
    ) {
        starknetCore = starknetCore_;
        l2RecipientAddr = l2RecipientAddr_;
        aggregatorsFactory = IAggregatorsFactory(aggregatorsFactoryAddr_);
    }

    /// @notice Send an exact L1 parent hash to L2
    /// @param blockNumber_ the child block of the requested parent hash
    function sendExactParentHashToL2(uint256 blockNumber_) external payable {
        bytes32 parentHash = blockhash(blockNumber_ - 1);
        require(parentHash != bytes32(0), "ERR_INVALID_BLOCK_NUMBER");

        _sendBlockHashToL2(parentHash, blockNumber_);
    }

    /// @notice Send the L1 latest parent hash to L2
    function sendLatestParentHashToL2() external payable {
        bytes32 parentHash = blockhash(block.number - 1);
        _sendBlockHashToL2(parentHash, block.number);
    }

    /// @param aggregatorId The id of a tree previously created by the aggregators factory
    function sendPoseidonMMRTreeToL2(uint256 aggregatorId) external payable {
        address existingAggregatorAddr = aggregatorsFactory.aggregatorsById(
            aggregatorId
        );

        require(existingAggregatorAddr != address(0), "Unknown aggregator");

        IAggregator aggregator = IAggregator(existingAggregatorAddr);
        bytes32 poseidonMMRRoot = aggregator.getMMRPoseidonRoot();
        uint256 mmrSize = aggregator.getMMRSize();

        require(mmrSize >= 1, "Invalid tree size");
        require(poseidonMMRRoot != bytes32(0), "Invalid root (Poseidon)");

        _sendPoseidonMMRTreeToL2(poseidonMMRRoot, mmrSize, aggregatorId);
    }

    function _sendBlockHashToL2(
        bytes32 parentHash_,
        uint256 blockNumber_
    ) internal {
        uint256[] memory message = new uint256[](4);
        (uint256 parentHashLow, uint256 parentHashHigh) = uint256(parentHash_)
            .split128();
        (uint256 blockNumberLow, uint256 blockNumberHigh) = blockNumber_
            .split128();
        message[0] = parentHashLow;
        message[1] = parentHashHigh;
        message[2] = blockNumberLow;
        message[3] = blockNumberHigh;

        starknetCore.sendMessageToL2{value: msg.value}(
            l2RecipientAddr,
            RECEIVE_COMMITMENT_L1_HANDLER_SELECTOR,
            message
        );
    }

    function _sendPoseidonMMRTreeToL2(
        bytes32 poseidonMMRRoot,
        uint256 mmrSize,
        uint256 aggregatorId
    ) internal {
        uint256[] memory message = new uint256[](3);

        message[0] = uint256(poseidonMMRRoot);
        message[1] = mmrSize;
        message[2] = aggregatorId;

        // Pass along msg.value
        starknetCore.sendMessageToL2{value: msg.value}(
            l2RecipientAddr,
            RECEIVE_MMR_L1_HANDLER_SELECTOR,
            message
        );
    }

    /// @notice Set the L2 recipient address
    /// @param newL2RecipientAddr_ The new L2 recipient address
    function setL2RecipientAddr(
        uint256 newL2RecipientAddr_
    ) external onlyOwner {
        l2RecipientAddr = newL2RecipientAddr_;
    }

    /// @notice Set the aggregators factory address
    /// @param newAggregatorsFactoryAddr_ The new aggregators factory address
    function setAggregatorsFactoryAddr(
        address newAggregatorsFactoryAddr_
    ) external onlyOwner {
        aggregatorsFactory = IAggregatorsFactory(newAggregatorsFactoryAddr_);
    }
}

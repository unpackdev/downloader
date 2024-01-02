// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import "./IStarknetCore.sol";
import "./Uint256Splitter.sol";

contract L1MessagesSender {
    using Uint256Splitter for uint256;

    IStarknetCore public immutable starknetCore;

    uint256 public immutable l2RecipientAddr;

    /// @dev L2 "receive_commitment" L1 handler selector
    uint256 constant RECEIVE_COMMITMENT_L1_HANDLER_SELECTOR = 0x3fa70707d0e831418fb142ca8fb7483611b84e89c0c42bf1fc2a7a5c40890ad;

    /// @param starknetCore_ a StarknetCore address to send and consume messages on/from L2
    /// @param l2RecipientAddr_ a L2 recipient address that is the recipient contract on L2.
    constructor(IStarknetCore starknetCore_, uint256 l2RecipientAddr_) {
        starknetCore = starknetCore_;
        l2RecipientAddr = l2RecipientAddr_;
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

    function _sendBlockHashToL2(
        bytes32 parentHash_,
        uint256 blockNumber_
    ) internal {
        uint256[] memory message = new uint256[](4);
        (uint256 parentHashLow, uint256 parentHashHigh) = uint256(parentHash_).split128();
        (uint256 blockNumberLow, uint256 blockNumberHigh) = blockNumber_.split128();
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
}

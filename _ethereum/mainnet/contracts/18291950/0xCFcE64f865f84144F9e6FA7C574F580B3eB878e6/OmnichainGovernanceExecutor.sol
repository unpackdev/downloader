// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ReentrancyGuard.sol";
import "./NonblockingLzApp.sol";

/// @title Omnichain Governance Executor
/// @notice Executes the proposal transactions sent from the main chain
/// @dev The owner of this contract controls LayerZero configuration.
/// When used in production the owner should be set to a Timelock or this contract itself 
/// This implementation is non-blocking meaning the failed messages will not block
/// the future messages from the source. For the blocking behavior derive the contract from LzApp
contract OmnichainGovernanceExecutor is NonblockingLzApp, ReentrancyGuard {
    using BytesLib for bytes;
    using ExcessivelySafeCall for address;

    event ProposalExecuted(bytes payload);
    event ProposalFailed(uint16 srcChainId, bytes srcAddress, uint64 nonce, bytes reason);

    constructor(address endpoint) NonblockingLzApp(endpoint) {}

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) internal virtual override {
        bytes32 hashedPayload = keccak256(payload);
        // enough gas to ensure we can store the payload and emit the event
        uint256 gasToStoreAndEmit = 30000;

        (bool success, bytes memory reason) = address(this).excessivelySafeCall(
            gasleft() - gasToStoreAndEmit,
            150,
            abi.encodeWithSelector(this.nonblockingLzReceive.selector, srcChainId, srcAddress, nonce, payload)
        );
        // try-catch all errors/exceptions
        if (!success) {
            failedMessages[srcChainId][srcAddress][nonce] = hashedPayload;
            // Retrieve payload from the src side tx if needed to clear
            emit ProposalFailed(srcChainId, srcAddress, nonce, reason);
        }
    }

    /// @notice Executes the proposal
    /// @dev Called by LayerZero Endpoint when a message from the source is received
    function _nonblockingLzReceive(
        uint16,
        bytes memory,
        uint64,
        bytes memory payload
    ) internal virtual override {
        (
            address[] memory targets,
            uint[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        ) = abi.decode(payload, (address[], uint[], string[], bytes[]));

        for (uint i = 0; i < targets.length; i++) {
            _executeTransaction(targets[i], values[i], signatures[i], calldatas[i]);
        }
        emit ProposalExecuted(payload);
    }

    function _executeTransaction(
        address target,
        uint value,
        string memory signature,
        bytes memory data
    ) private nonReentrant {
        bytes memory callData = bytes(signature).length == 0 ?
            data : abi.encodePacked(bytes4(keccak256(bytes(signature))), data);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = target.call{value: value}(callData);
        require(success, "OmnichainGovernanceExecutor: transaction execution reverted");
    }  
    
    receive() external payable {}
}

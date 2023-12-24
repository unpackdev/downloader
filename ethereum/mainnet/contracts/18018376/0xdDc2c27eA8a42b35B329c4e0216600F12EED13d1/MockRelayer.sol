// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.5;

import "./Adaptor.sol";
import "./IWormholeRelayer.sol";
import "./IWormholeReceiver.sol";

/// @notice A mock Wormhole Relayer that implements the `IWormholeRelayer` interface
/// @dev This is a fake WormholeRelayer that delivers messages to the CrossChainPool. It receives messages from the fake Wormhole.
/// The main usage is the `deliver` method.
contract MockRelayer {
    uint256 constant gasMultiplier = 1e10;
    uint256 constant sendGasOverhead = 0.01 ether;

    function sendToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 paymentForExtraReceiverValue,
        uint256 gasLimit,
        uint16 refundChain,
        address refundAddress,
        address deliveryProviderAddress,
        VaaKey[] memory vaaKeys,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence) {
        require(msg.value == 0.001 ether + gasLimit + receiverValue, 'Invalid funds');
    }

    function deliver(
        IWormholeReceiver target,
        bytes calldata payload,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external {
        target.receiveWormholeMessages(payload, new bytes[](0), sourceAddress, sourceChain, deliveryHash);
    }

    function resend(
        VaaKey memory deliveryVaaKey,
        uint16 targetChain,
        uint256 newReceiverValue,
        uint256 newGasLimit,
        address newDeliveryProviderAddress
    ) external payable returns (uint64 sequence) {}

    function quoteGas(
        uint16 targetChain,
        uint32 gasLimit,
        address relayProvider
    ) external pure returns (uint256 maxTransactionFee) {
        return gasLimit * gasMultiplier + sendGasOverhead;
    }

    function quoteGasResend(
        uint16 targetChain,
        uint32 gasLimit,
        address relayProvider
    ) external pure returns (uint256 maxTransactionFee) {
        return gasLimit * gasMultiplier;
    }

    function quoteReceiverValue(
        uint16 targetChain,
        uint256 targetAmount,
        address relayProvider
    ) external pure returns (uint256 receiverValue) {
        return targetAmount * gasMultiplier;
    }

    function toWormholeFormat(address addr) external pure returns (bytes32 whFormat) {}

    function fromWormholeFormat(bytes32 whFormatAddress) external pure returns (address addr) {}

    function getDefaultRelayProvider() external view returns (address relayProvider) {}

    function getDefaultRelayParams() external pure returns (bytes memory relayParams) {}
}

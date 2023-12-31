// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IStarknetMessaging.sol";
import "./IStarknetBridge.sol";

/// @title Messaging contract.
/// @author Spaceshard team 2023.
contract Messaging {
    uint256 private constant UINT256_PART_SIZE_BITS = 128;
    uint256 private constant UINT256_PART_SIZE = 2 ** UINT256_PART_SIZE_BITS;

    /// @notice Starknet messaging interface.
    IStarknetMessaging public starknetCore;

    /// @notice initialize the trove handler.
    /// @param _starknetCore Starknet core interface.
    function initializeMessaging(address _starknetCore) internal {
        starknetCore = IStarknetMessaging(_starknetCore);
    }

    /// @notice Consume l2 message.
    function _consumeL2Message(uint256 l2ContractAddress, uint256[] memory data) internal {
        starknetCore.consumeMessageFromL2(l2ContractAddress, data);
    }

    /// @notice Withdraw tokens from Starkgate bridge.
    function _withdrawTokenFromBridge(
        address l1BridgeAddress,
        uint256 l2BridgeAddress,
        address _receiver,
        uint256 _amount
    ) internal {
        uint[] memory payload = new uint256[](4);
        payload[0] = 0;
        payload[1] = uint256(uint160(_receiver));
        payload[2] = _amount & (UINT256_PART_SIZE - 1);
        payload[3] = _amount >> UINT256_PART_SIZE_BITS;

        bytes32 msgHash = keccak256(
            abi.encodePacked(
                l2BridgeAddress,
                uint256(uint160(l1BridgeAddress)),
                payload.length,
                payload
            )
        );

        if (starknetCore.l2ToL1Messages(msgHash) == 0x0) return;

        IStarknetBridge(l1BridgeAddress).withdraw(_amount, _receiver);
    }

    /// @notice deposit tokens to Starknet bridge.
    function depositToBridgeToken(
        address l1BridgeAddress,
        uint256 _l2Receiver,
        uint256 _amount,
        uint256 _value
    ) internal {
        if (_amount > 0) {
            IStarknetBridge(l1BridgeAddress).deposit{value: _value}(_amount, _l2Receiver);
        }
    }

    /// @notice send message to l2.
    function _sendMessageToL2(
        uint256 _l2Contract,
        uint256 _selector,
        uint256[] memory payload,
        uint256 _value
    ) internal {
        starknetCore.sendMessageToL2{value: _value}(_l2Contract, _selector, payload);
    }

    function u256(uint256 _value) internal pure returns (uint256 low, uint256 high) {
        low = _value & (UINT256_PART_SIZE - 1);
        high = _value >> UINT256_PART_SIZE_BITS;
    }
}

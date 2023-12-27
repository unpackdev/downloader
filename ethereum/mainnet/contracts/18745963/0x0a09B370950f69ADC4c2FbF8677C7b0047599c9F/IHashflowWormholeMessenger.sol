/**
 * SPDX-License-Identifier: UNLICENSED
 */
pragma solidity >=0.8.0;

import "./IHashflowXChainMessenger.sol";

interface IHashflowWormholeMessenger is IHashflowXChainMessenger {
    /// @notice Emitted when the Wormhole endpoint is updated.
    /// @param wormholeEndpoint The new Wormhole endpoint.
    /// @param prevWormholeEndpoint The old Wormhole endpoint.
    event UpdateWormholeEndpoint(
        address wormholeEndpoint,
        address prevWormholeEndpoint
    );

    /// @notice Emitted when the Wormhole consistency level is updated.
    /// @param consistencyLevel The new consistencyLevel.
    event UpdateWormholeConsistencyLevel(uint256 consistencyLevel);

    /// @notice Emitted when the Wormhole fast consistency level is updated.
    /// @param consistencyLevel The new consistencyLevel.
    event UpdateWormholeConsistencyLevelFast(uint256 consistencyLevel);

    /// @notice Emitted when a Wormhole Chain ID is updated.
    /// @param hChainId The Hashflow Chain ID.
    /// @param wormholeChainId The Wormhole Chain ID.
    event UpdateWormholeChainId(uint256 hChainId, uint256 wormholeChainId);

    event UpdatePermissionedRelayer(uint16 hChainId, bytes32 relayer);

    /// @notice Emitted when a message is sent via Wormhole.
    /// @dev The sequence is used offline by the Relayer to fetch the VAA.
    event WormholeSend(bytes32 txid, uint256 value, uint256 sequence);

    /// @notice Emitted when a message is sent with fast consistency level.
    event WormholeSendFast(bytes32 txid, uint256 value, uint256 sequence);

    /// @notice Emitted when a Wormhole message is successfully received.
    event WormholeReceive(bytes32 txid);

    /// @notice Returns the currently set Wormhole endpoint.
    function wormholeEndpoint() external view returns (address);

    /// @notice Returns the currently set consistency level for Wormhole.
    function wormholeConsistencyLevel() external view returns (uint8);

    /// @notice Returns the currently set consistency level for Wormhole fast messages.
    function wormholeConsistencyLevelFast() external view returns (uint8);

    /// @notice Returns the associated Hashflow Chain ID to a Wormhole Chain ID.
    /// @param wormholeChainId The Wormhole Chain ID.
    function wormholeChainIdToHChainId(uint16 wormholeChainId)
        external
        view
        returns (uint16);

    /// @notice Returns the associated Wormhole Chain ID to a Hashflow Chain ID.
    /// @param hChainId The Hashflow Chain Id.
    function hChainIdToWormholeChainId(uint16 hChainId)
        external
        view
        returns (uint16);

    /// @notice Returns the currently set permissioned Relayer for a Hashflow Chain.
    /// @param hChainId The Hashflow Chain ID.
    function permissionedRelayers(uint16 hChainId)
        external
        view
        returns (bytes32);

    /// @notice Updates the Wormhole bridge endpoint.
    /// @param wormhole The new Wormhole bridge endpoint.
    function updateWormhole(address wormhole) external;

    /// @notice Updates the Wormhole consistency level.
    /// @param consistencyLevel The new consistency level.
    function updateWormholeConsistencyLevel(uint8 consistencyLevel) external;

    /// @notice Updates the Wormhole fast consistency level.
    /// @param consistencyLevel The new fast consistency level.
    function updateWormholeConsistencyLevelFast(uint8 consistencyLevel)
        external;

    /// @notice Updates the permissioned Relayer for a hashflow chain ID.
    /// @param hChainId The Hashflow Chain ID.
    /// @param relayer The permissioned Relayer.
    function updatePermissionedRelayer(uint16 hChainId, bytes32 relayer)
        external;

    /// @notice Receives a message sent via Wormhole.
    /// @param encodedVM the encoded Wormhole VAA.
    function wormholeReceive(bytes memory encodedVM) external;

    /// @notice Sets the Wormhole Chain ID for a Hashflow Chain ID.
    /// @param hChainId The Hashflow Chain ID.
    /// @param wormholeChainId The Wormhole Chain ID.
    function updateWormholeChainIdForHashflowChainId(
        uint16 hChainId,
        uint16 wormholeChainId
    ) external;
}

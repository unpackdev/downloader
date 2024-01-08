// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Bridgeable asset standard
 */
interface IBridgeable {
    /**
     * @notice Called by a bridge when an asset is leaving this network
     * @dev Should only be callable by a bridge
     * @param owner address of the asset
     * @param value of the asset on the source chain
     * @param chainId of the destination chain
     * @return data that might be helpful when minting the asset on the new network
     */
    function bridgeLeave(
        address owner,
        uint256 value,
        uint32 chainId
    ) external returns (bytes memory data);

    /**
     * @notice Called by the bridge when an asset arrives to this network
     * @dev Should only be callable by a bridge
     * @param owner address of the asset
     * @param value of the asset on the source chain
     * @param chainId of the source chain
     * @param data passed from the asset on the source chain that might be needed
     */
    function bridgeEnter(
        address owner,
        uint256 value,
        uint32 chainId,
        bytes memory data
    ) external;
}

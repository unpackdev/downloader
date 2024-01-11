// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title  VoxelTowers Property interface
 * @author The VoxelTowers crew
 * @notice This interface defines the functions for external contracts to set additional properties to VTO tokens
 */
interface IPropertyStore {
    struct Property {
        string key;
        string value;
    }

    /**
     * @notice Adds an aditional property to a token
     * @dev    The caller address must be whitelisted first in order to add additional properties
     * @param  tokenId - the token Id
     * @param  property - the additional property
     */
    function addProperty(uint256 tokenId, Property calldata property) external;

    /**
     * @notice Gets the properties of a token
     * @param  tokenId - the token Id
     * @return the properties of token
     */
    function getProperties(uint256 tokenId) external view returns (Property[] memory);
}

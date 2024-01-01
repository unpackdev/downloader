// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CollectionManager
 * @notice CollectionManager v2 always returns true for isCollectionWhitelisted
 */
contract CollectionManagerWithoutWhitelist {
    /**
     * @notice Returns true 
     * @param collection Address of collection , necessary for interface compatibility
     */
    
    function isCollectionWhitelisted(address collection) external view returns (bool) {
        return true;
    }

}

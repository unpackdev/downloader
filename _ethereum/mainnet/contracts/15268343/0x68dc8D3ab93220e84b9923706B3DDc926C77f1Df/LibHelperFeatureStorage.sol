// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./LibHelperStorage.sol";


library LibHelperFeatureStorage {

    struct Storage {
        address owner;
        // Mapping of function selector -> function implementation
        mapping(bytes4 => address) impls;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        // uint256 storageSlot = LibStorage.STORAGE_ID_FEATURE;
        assembly { stor.slot := 0 }
    }
}

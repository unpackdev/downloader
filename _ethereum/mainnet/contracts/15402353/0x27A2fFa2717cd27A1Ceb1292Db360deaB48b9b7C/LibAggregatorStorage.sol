// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibAggregatorStorage {

    uint256 constant STORAGE_ID_AGGREGATOR = 0;

    struct Market {
        address proxy;
        bool isLibrary;
        bool isActive;
    }

    struct Storage {
        Market[] markets;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_AGGREGATOR }
    }
}

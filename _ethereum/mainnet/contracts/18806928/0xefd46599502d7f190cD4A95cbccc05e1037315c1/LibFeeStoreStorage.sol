// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "./Structs.sol";

library LibFeeStoreStorage {
    bytes32 constant FEE_STORE_STORAGE_POSITION = keccak256("degenx.fee-store.storage.v1");

    struct FeeStoreStorage {
        // feeConfigId => FeeStoreConfig
        mapping(bytes32 => FeeStoreConfig) feeConfigs;
        // feeConfigId => amount of fees collected
        mapping(bytes32 => uint256) collectedFees;
        // represents a sum of each amount in collectedFees
        uint256 collectedFeesTotal;
        bytes32[] feeConfigIds;
        address operator;
        address intermediateAsset;
    }

    function feeStoreStorage() internal pure returns (FeeStoreStorage storage fss) {
        bytes32 position = FEE_STORE_STORAGE_POSITION;
        assembly {
            fss.slot := position
        }
    }
}

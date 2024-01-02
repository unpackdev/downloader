// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "./Enums.sol";
import "./Structs.sol";

/// @title Lib Fee Manager Storage
/// @author Daniel <danieldegendev@gmail.com>
/// @notice Storage for the Fee Manager Facet
library LibFeeManagerStorage {
    bytes32 constant FEE_MANAGER_STORAGE_POSITION = keccak256("degenx.fee-manager.storage.v1");

    struct FeeManagerStorage {
        // all available chains
        uint256[] chainIds;
        // all available configs
        bytes32[] feeConfigIds;
        // contract to chain assignments
        // chainId => contract
        mapping(uint256 => address) chainTargets;
        // fee config to chain assignment to store which config should be available on which chain
        // chainId => list of fee config ids
        mapping(uint256 => bytes32[]) chainIdFeeConfigMap;
        // flags for quick checks to avoid looping through chainIdFeeConfigMap
        // chainId => feeConfigId
        mapping(uint256 => mapping(bytes32 => bool)) chainIdFeeConfig;
        // flag if a specific chain is being supported
        // chainId => true/false
        mapping(uint256 => bool) isChainSupported;
        // fee config id to fee config mapping. The fee config itself doesn't need to know its id
        // feeConfigId => FeeConfig
        mapping(bytes32 => FeeConfig) feeConfigs;
        // fee config archive of recent fee config settings to a specific fee config id
        // feeConfigId => list of fee config variants
        mapping(bytes32 => FeeConfig[]) feeConfigsArchive;
        // queue for syncing configs with the target contracts
        // chainId => list of fee sync data
        mapping(uint256 => FeeSyncQueue[]) feeSyncQueue;
        // deployment state per chain per fee config id
        // chainId => fee config id => deployment state of a fee config
        mapping(uint256 => mapping(bytes32 => FeeDeployState)) feeDeployState;
    }

    /// store
    function feeManagerStorage() internal pure returns (FeeManagerStorage storage fms) {
        bytes32 position = FEE_MANAGER_STORAGE_POSITION;
        assembly {
            fms.slot := position
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import "./LibFeeManagerStorage.sol";
import "./Structs.sol";
import "./Enums.sol";

/// @title Lib Fee Manager
/// @author Daniel <danieldegendev@gmail.com>
/// @notice Helper functions for the Fee Manager Facet
library LibFeeManager {
    /// viewables

    /// Checks whether a fee config exsists or not
    /// @param _id fee config id
    function exists(bytes32 _id) internal view returns (bool _exists) {
        _exists = LibFeeManagerStorage.feeManagerStorage().feeConfigs[_id].ftype != FeeType.Null;
    }

    /// Checks whether a fee config is in use on a specific chain or not
    /// @param _id fee config id
    function isFeeConfigInUse(bytes32 _id) internal view returns (bool _exists) {
        for (uint256 i = 0; i < store().chainIds.length; i++) {
            for (uint256 j = 0; j < store().chainIdFeeConfigMap[store().chainIds[i]].length; j++) {
                if (store().chainIdFeeConfigMap[store().chainIds[i]][j] == _id) {
                    _exists = true;
                    break;
                }
            }
        }
    }

    /// Gets the target address for a specific chain
    /// @param _chainId chain id
    /// @dev normally the address of the diamond on the target chain
    function getChainTarget(uint256 _chainId) internal view returns (address _target) {
        _target = store().chainTargets[_chainId];
    }

    /// Gets the fee config by a given id
    /// @param _id fee config id
    function getFeeConfigById(bytes32 _id) internal view returns (FeeConfig memory _feeConfig) {
        LibFeeManagerStorage.FeeManagerStorage storage s = LibFeeManagerStorage.feeManagerStorage();
        _feeConfig = s.feeConfigs[_id];
    }

    /// internals

    /// Queues up a specific fee config for a specific chain with a specific action
    /// @param _id fee config id
    /// @param _chainId chain id
    /// @param _action action to execute on the target chain
    function queue(bytes32 _id, uint256 _chainId, FeeSyncAction _action) internal {
        LibFeeManagerStorage.FeeManagerStorage storage s = LibFeeManagerStorage.feeManagerStorage();
        bool alreadInQueue = false;
        for (uint256 i = 0; i < s.feeSyncQueue[_chainId].length; i++)
            alreadInQueue = alreadInQueue || (s.feeSyncQueue[_chainId][i].id == _id && s.feeSyncQueue[_chainId][i].chainId == _chainId);

        if (!alreadInQueue) {
            s.feeSyncQueue[_chainId].push(FeeSyncQueue({ id: _id, chainId: _chainId, action: _action }));
            s.feeDeployState[_chainId][_id] = FeeDeployState.Queued;
        }
    }

    /// Simple archiving of fee configs
    /// @param _id fee config id
    /// will be called on update and delete of a fee config
    function archiveFeeConfig(bytes32 _id) internal {
        FeeConfig storage feeConfigToArchive = LibFeeManagerStorage.feeManagerStorage().feeConfigs[_id];
        LibFeeManagerStorage.feeManagerStorage().feeConfigsArchive[_id].push(feeConfigToArchive);
    }

    /// store
    function store() internal pure returns (LibFeeManagerStorage.FeeManagerStorage storage _store) {
        _store = LibFeeManagerStorage.feeManagerStorage();
    }
}

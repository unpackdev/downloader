// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import "./MapleProxiedInternals.sol";

import "./Interfaces.sol";

import "./MaplePoolManagerStorage.sol";

contract MaplePoolManagerMigrator is MapleProxiedInternals, MaplePoolManagerStorage {

    event PoolPermissionManagerSet(address poolPermissionManager_);

    fallback() external {
        address poolPermissionManager_ = abi.decode(msg.data, (address));
        address globals_               = IMapleProxyFactoryLike(_factory()).mapleGlobals();

        require(IGlobalsLike(globals_).isInstanceOf("POOL_PERMISSION_MANAGER", poolPermissionManager_), "PMM:INVALID_PPM");

        poolPermissionManager = poolPermissionManager_;

        emit PoolPermissionManagerSet(poolPermissionManager_);
    }

}

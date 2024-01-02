// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./MapleProxiedInternals.sol";

import "./Interfaces.sol";
import { IMapleWithdrawalManagerInitializer }                                from "../interfaces/IMapleWithdrawalManagerInitializer.sol";

import "./MapleWithdrawalManagerStorage.sol";

contract MapleWithdrawalManagerInitializer is IMapleWithdrawalManagerInitializer, MapleWithdrawalManagerStorage, MapleProxiedInternals {

    fallback() external {
        ( address pool_ ) = abi.decode(msg.data, (address));

        _initialize(pool_);
    }

    function _initialize(address pool_) internal {
        require(pool_ != address(0), "WMI:ZERO_POOL");

        address globals_     = IMapleProxyFactoryLike(msg.sender).mapleGlobals();
        address poolManager_ = IPoolLike(pool_).manager();
        address factory_     = IPoolManagerLike(poolManager_).factory();

        require(IGlobalsLike(globals_).isInstanceOf("POOL_MANAGER_FACTORY", factory_), "WMI:I:INVALID_PM_FACTORY");
        require(IMapleProxyFactoryLike(factory_).isInstance(poolManager_),             "WMI:I:INVALID_PM");

        _locked = 1;

        pool        = pool_;
        poolManager = poolManager_;

        queue.nextRequestId = 1;  // Initialize queue with index 1

        emit Initialized(pool_, poolManager_);
    }

}

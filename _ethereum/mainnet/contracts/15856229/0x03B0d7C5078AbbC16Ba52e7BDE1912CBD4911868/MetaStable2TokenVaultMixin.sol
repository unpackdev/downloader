// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./IBalancerPool.sol";
import "./BalancerVaultTypes.sol";
import "./TwoTokenPoolMixin.sol";
import "./BalancerVaultTypes.sol";
import "./NotionalProxy.sol";
import "./StableMath.sol";

abstract contract MetaStable2TokenVaultMixin is TwoTokenPoolMixin {
    constructor(NotionalProxy notional_, AuraVaultDeploymentParams memory params)
        TwoTokenPoolMixin(notional_, params)
    {
        // The oracle is required for the vault to behave properly
        (/* */, /* */, /* */, /* */, bool oracleEnabled) = 
            IMetaStablePool(address(BALANCER_POOL_TOKEN)).getOracleMiscData();
        require(oracleEnabled);
    }

    function _stableOracleContext() internal view returns (StableOracleContext memory) {
        (
            uint256 value,
            /* bool isUpdating */,
            uint256 precision
        ) = IMetaStablePool(address(BALANCER_POOL_TOKEN)).getAmplificationParameter();
        require(precision == StableMath._AMP_PRECISION);
        
        return StableOracleContext({
            ampParam: value
        });
    }

    uint256[40] private __gap; // Storage gap for future potential upgrades
}

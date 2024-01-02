// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "./ICHIVault.sol";
import "./IPancakeV3Factory.sol";

library ICHIVaultDeployer {

    function createICHIVault(
        address pool, 
        address token0,
        bool allowToken0,
        address token1,
        bool allowToken1,
        uint24 fee, 
        int24 tickSpacing,
        uint32 twapPeriod
    ) public returns(address ichiVault) {

        ichiVault = address(
            new ICHIVault{salt: keccak256(abi.encodePacked(
                msg.sender, 
                token0, 
                allowToken0, 
                token1, 
                allowToken1, 
                fee, 
                tickSpacing)
            )}
                (pool, 
                allowToken0, 
                allowToken1, 
                msg.sender, 
                twapPeriod)
        );
    }
}
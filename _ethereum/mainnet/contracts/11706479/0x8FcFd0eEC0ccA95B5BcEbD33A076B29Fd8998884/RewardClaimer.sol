// SPDX-License-Identifier: NONE

pragma solidity 0.8.0;



// Part: LiquidityGauge

interface LiquidityGauge {
    function claim_rewards(address _addr) external;
}

// File: <stdin>.sol

contract RewardClaimer {

    function claimManyRewards(
        LiquidityGauge[] calldata _gauges,
        address[][] calldata _claimants
    ) external {
        unchecked {
            for (uint i = 0; i < _gauges.length; i++) {
                LiquidityGauge gauge = _gauges[i];
                for (uint x = 0; x < _claimants[i].length; x++) {
                    gauge.claim_rewards(_claimants[i][x]);
                }
            }
        }
    }
}

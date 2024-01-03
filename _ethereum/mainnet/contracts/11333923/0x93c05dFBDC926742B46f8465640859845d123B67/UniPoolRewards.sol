// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./LPRewardsWrapper.sol";
contract RlrUniRewards is LPRewardsWrapper{
    constructor() public {
        setLPToken(0xe4332d93B4f0477d5230852f59D2621E2AcdEa1A);// RLR/ETH Uniswap LP
    }
}
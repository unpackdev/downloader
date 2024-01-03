// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./LPRewardsWrapper.sol";
contract RlrMooniRewards is LPRewardsWrapper{
    constructor() public {
        setLPToken(0xF83f2C42d7b38394F67368c859756F10761beF42);// RLR/ETH Mooniswap LP
    }
}
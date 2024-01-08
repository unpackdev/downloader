// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BondlyTokenHolder.sol";

contract BondlyTokenStakingRewards is BondlyTokenHolder {
    constructor (address _bondTokenAddress) BondlyTokenHolder (
        _bondTokenAddress
        ) public {
            name = "StakingRewards";
            maxCap = 400000000 ether;
            unlockRate = 36;//Release duration (# of releases, months)
            perMonth = 11111111111111111111111111;//11,111,111.11111...
            fullLockMonths = 0;
            transferOwnership(0x5dD8F112F01814682bdbFC9b70807F25b44B7Aff);
    }
}
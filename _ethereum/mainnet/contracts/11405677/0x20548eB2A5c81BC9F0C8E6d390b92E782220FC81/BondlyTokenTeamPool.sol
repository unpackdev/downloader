// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BondlyTokenHolder.sol";

contract BondlyTokenTeamPool is BondlyTokenHolder {
    constructor (address _bondTokenAddress) BondlyTokenHolder (
        _bondTokenAddress
        ) public {
            name = "Team";
            maxCap = 40000000 ether;//40,000,000
            unlockRate = 12;//Release duration (# of releases, months)
            perMonth = 3333333333333333333333333;//3,333,333.33333...
            fullLockMonths = 12;
            transferOwnership(0x58A058ca4B1B2B183077e830Bc929B5eb0d3330C);
    }
}
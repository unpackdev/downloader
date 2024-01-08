// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BondlyTokenHolder.sol";

contract BondlyTokenAdvisorsPool is BondlyTokenHolder {
    constructor (address _bondTokenAddress) BondlyTokenHolder (
        _bondTokenAddress
        ) public {
            name = "Advisors";
            maxCap = 30000000 ether;//30,000,000; bondly also 18 decimals
            perMonth = 2500000 ether;//2,500,000
            unlockRate = 12;//Release duration (# of releases, months)
            fullLockMonths = 12;
            transferOwnership(0x5dD8F112F01814682bdbFC9b70807F25b44B7Aff);
    }
}
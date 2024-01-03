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
            transferOwnership(0x58A058ca4B1B2B183077e830Bc929B5eb0d3330C);
    }
}
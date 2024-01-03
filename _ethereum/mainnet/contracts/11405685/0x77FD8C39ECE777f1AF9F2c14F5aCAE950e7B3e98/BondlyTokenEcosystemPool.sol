// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BondlyTokenHolder.sol";

contract BondlyTokenEcosystemPool is BondlyTokenHolder {
    constructor (address _bondTokenAddress) BondlyTokenHolder (
        _bondTokenAddress
        ) public {
            name = "Ecosystem";
            maxCap = 186000000 ether;//186,000,000; bondly also has 18 decimals
            unlockRate = 36;//Release duration (# of releases, months)
            perMonth = 5166666666666666666666666;//5,166,666.666666666...
            fullLockMonths = 0;
            transferOwnership(0x58A058ca4B1B2B183077e830Bc929B5eb0d3330C);
    }
}
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
            transferOwnership(0x5dD8F112F01814682bdbFC9b70807F25b44B7Aff);
    }
}
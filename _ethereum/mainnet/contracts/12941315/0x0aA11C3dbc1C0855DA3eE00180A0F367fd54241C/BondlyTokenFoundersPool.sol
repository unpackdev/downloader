// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BondlyTokenHolder.sol";

contract BondlyTokenFoundersPool is BondlyTokenHolder {
    constructor (address _bondTokenAddress) BondlyTokenHolder (
        _bondTokenAddress
        ) public {
            name = "Founders";
            maxCap = 100000000 ether;//100,000,000
            unlockRate = 12;//Release duration (# of releases, months)
            perMonth = 8333333333333333333333333;//8,333,333.33333....
            fullLockMonths = 12;
            transferOwnership(0x5dD8F112F01814682bdbFC9b70807F25b44B7Aff);
    }
}
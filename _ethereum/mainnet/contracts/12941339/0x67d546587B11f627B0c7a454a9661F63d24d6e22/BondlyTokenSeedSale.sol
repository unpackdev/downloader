// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BondlyTokenSale.sol";

contract BondlyTokenSeedSale is BondlyTokenSale {
    constructor (address _bondTokenAddress) BondlyTokenSale (
        _bondTokenAddress
        ) public {
            name = "Seed";
            maxCap = 41250000 ether;
            unlockRate = 9;//Release duration (# of releases, months)
            fullLockMonths = 3;
            floatingRate = 0;//50% and 25%
            transferOwnership(0x5dD8F112F01814682bdbFC9b70807F25b44B7Aff);

            eLog[0x5dD8F112F01814682bdbFC9b70807F25b44B7Aff] = iTokenLock({ 
                lastTxAt: 1607349617,
                amount: maxCap, 
                sent: 0
            });
    }
}
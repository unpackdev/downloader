// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BondlyTokenSale.sol";

contract BondlyTokenP2Sale is BondlyTokenSale {
    constructor (address _bondTokenAddress) BondlyTokenSale (
        _bondTokenAddress
        ) public {
            name = "P2";
            maxCap = 74482759 ether;
            unlockRate = 4;//Release duration (# of releases, months)
            fullLockMonths = 0;
            floatingRate = 0;
            transferOwnership(0x5dD8F112F01814682bdbFC9b70807F25b44B7Aff);

            eLog[0x5dD8F112F01814682bdbFC9b70807F25b44B7Aff] = iTokenLock({ 
                lastTxAt: 1607349617,
                amount: maxCap, 
                sent: 0
            });
    }
}
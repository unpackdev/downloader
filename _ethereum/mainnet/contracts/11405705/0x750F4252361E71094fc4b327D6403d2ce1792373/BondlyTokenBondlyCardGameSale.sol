// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BondlyTokenSale.sol";

contract BondlyTokenBondlyCardGameSale is BondlyTokenSale {
    constructor (address _bondTokenAddress) BondlyTokenSale (
        _bondTokenAddress
        ) public {
            name = "BondlyCardGame";
            maxCap = 7500000 ether;//bondly has 18 decimals
            unlockRate = 3;
            fullLockMonths = 0;
            floatingRate = 5025;//50% and 25%
            transferOwnership(0x58A058ca4B1B2B183077e830Bc929B5eb0d3330C);
    }
}
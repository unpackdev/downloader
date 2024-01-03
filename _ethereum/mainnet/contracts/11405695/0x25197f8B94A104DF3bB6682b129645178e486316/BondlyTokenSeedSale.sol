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
            transferOwnership(0x58A058ca4B1B2B183077e830Bc929B5eb0d3330C);
    }
}
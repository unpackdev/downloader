// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BondlyTokenSale.sol";

contract BondlyTokenP1Sale is BondlyTokenSale {
    constructor (address _bondTokenAddress) BondlyTokenSale (
        _bondTokenAddress
        ) public {
            name = "P1";
            maxCap = 90000000 ether;
            unlockRate = 5;//Release duration (# of releases, months)
            fullLockMonths = 0;
            floatingRate = 0;
            transferOwnership(0x58A058ca4B1B2B183077e830Bc929B5eb0d3330C);
    }
}
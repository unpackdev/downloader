// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./BondlyTokenSale.sol";

contract BondlyTokenInitialDexSale is BondlyTokenSale {
    constructor (address _bondTokenAddress) BondlyTokenSale (
        _bondTokenAddress
        ) public {
            name = "InitialDEX";
            maxCap = 3638000 ether;
            unlockRate = 0;
            fullLockMonths = 0;
            floatingRate = 0;
            transferOwnership(0x58A058ca4B1B2B183077e830Bc929B5eb0d3330C);
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "./GRDDustSaleContract.sol";

contract dustSale is GRDDustSaleContract {
    constructor(SaleConfiguration memory config) {
        setup(config);
    }
}

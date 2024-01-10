// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Auth.sol";

abstract contract SaleModule is Auth {

    struct Sale {
        uint128 price;
        uint64 start;
        uint64 limit;
    }

    mapping (uint256 => Sale) public sales;
    
    function createSale(uint256 dropId, uint128 price, uint64 start, uint64 limit) requiresAuth public {
        sales[dropId] = Sale(price, start, limit);
    }

    function flipSaleState(uint256 dropId) requiresAuth public {
        sales[dropId].start = sales[dropId].start > 0 ? 0 : type(uint64).max;
    }

    function _purchase(uint256 dropId, uint256 amount) internal {
        Sale memory sale = sales[dropId];
        require(block.timestamp >= sale.start, "PURCHASE:SALE INACTIVE");
        require(amount <= sale.limit, "PURCHASE:OVER LIMIT");
        require(msg.value == amount * sale.price, "PURCHASE:INCORRECT MSG.VALUE");
    }
}
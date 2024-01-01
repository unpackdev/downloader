// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Ownable.sol";

abstract contract M1ZPrices is Ownable {
    enum PayFeesIn {
        Native,
        LINK
    }

    // Unit price for 1 M1Z
    uint256 public unitPrice;

    constructor(uint256 _unitPrice) {
        unitPrice = _unitPrice;
    }

    function getPrice(uint256 amount) public view returns (uint256 price) {
        price = amount * unitPrice;
        if (amount > 1) {
            price = (price * (100 - amount)) / 100;
        }
    }

    function setUnitPrice(uint256 _unitPrice) external onlyOwner {
        unitPrice = _unitPrice;
    }
}

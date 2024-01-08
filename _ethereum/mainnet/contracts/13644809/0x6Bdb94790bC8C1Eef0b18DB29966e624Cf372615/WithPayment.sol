// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";

abstract contract WithPayment {
    modifier withPayment(uint256 price, address payable to) {
        require(msg.value >= price, 'Insufficient payment');
        _;
        if (to != address(0)) {
            AddressUpgradeable.sendValue(to, msg.value);
        }
    }
}
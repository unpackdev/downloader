// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./SafetyBox.sol";

contract SomeDAOReserve is SafetyBox {
    constructor(address initialOwner) {
        require(initialOwner != address(0), "initialOwner can't be null");
        _transferOwnership(initialOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./PaymentSplitter.sol";

contract Shareholders is PaymentSplitter {
    constructor(address[] memory holders, uint256[] memory shares)
        PaymentSplitter(holders, shares)
    {}
}
// SPDX-License-Identifier: MIT

/// @title Splitter

/**
 *   ___      _    _ ___          _
 *  | _ \__ _(_)__| | _ \__ _ _ _| |_ _  _
 *  |   / _` | / _` |  _/ _` | '_|  _| || |
 *  |_|_\__,_|_\__,_|_| \__,_|_|  \__|\_, |
 *                                    |__/
 */

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";

contract Splitter is PaymentSplitter {
    constructor(
        address[] memory payees, 
        uint256[] memory shares
    ) PaymentSplitter(payees, shares) payable {}
}

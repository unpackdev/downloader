// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20AbstractToken.sol";

/**
 * @title TRex
 * @dev The T. Rex token implementation
 */
contract TRex is ERC20AbstractToken {
    string _name = "T. Rex";
    string _symbol = "TREX";
    uint256 _initialBalance = 1000000000000000000000000000000;

    constructor() ERC20AbstractToken(_name, _symbol, _initialBalance) {}
}

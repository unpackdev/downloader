// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ERC20.sol";
import "./Ownable.sol";

contract pR3FIToken is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {
        _setupDecimals(9);
        _mint(msg.sender, 5 * 10 ** 6 * 10 ** 9);
    }
}

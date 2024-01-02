// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Determinant is ERC20, Ownable {
    constructor() ERC20("Determinant", "DTH") {
        _mint(msg.sender, 100000000 * (10 ** decimals()));
    }
}
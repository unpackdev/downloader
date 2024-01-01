// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Opium is ERC20 {
    constructor() ERC20("Opium", "OPIUM") {
        _mint(msg.sender, 420000000 * 10 ** decimals());
    }
}
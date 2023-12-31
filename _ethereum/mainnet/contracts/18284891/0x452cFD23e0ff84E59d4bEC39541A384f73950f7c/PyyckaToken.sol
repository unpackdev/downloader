// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract PyyckaToken is ERC20 {
    constructor() ERC20("Pyycka", "PYY") {
        _mint(msg.sender, 928000 * (10 ** 18));
    }

}
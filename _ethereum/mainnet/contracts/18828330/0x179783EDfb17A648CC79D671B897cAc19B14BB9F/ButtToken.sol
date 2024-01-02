// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract ButtToken is ERC20 {
    constructor() ERC20("Butt", "BUTT") {
        _mint(msg.sender, 928000000 * (10 ** 18));
    }

}
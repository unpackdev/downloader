// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";

contract LastToken is ERC20 {
    constructor() ERC20("LAST", "LAST") {
        _mint(msg.sender, 25000000 * 10 ** decimals());
    }
}

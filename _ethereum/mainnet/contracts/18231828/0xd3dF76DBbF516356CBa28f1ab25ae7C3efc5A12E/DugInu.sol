// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC20.sol";

contract DugInu is ERC20 {
    constructor() ERC20("DugInu", "DUG") {
        _mint(msg.sender, 1212121212 * 10 ** decimals());
    }
}
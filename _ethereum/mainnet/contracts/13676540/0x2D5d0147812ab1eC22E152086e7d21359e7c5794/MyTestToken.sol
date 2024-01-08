// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

contract MyTestToken is ERC20 {
    constructor() ERC20("MyTestCoin", "MTC") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }
}
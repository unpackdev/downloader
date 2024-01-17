// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract WorldCupToken is ERC20 {
    constructor() ERC20("World Cup Token", "WCT") {
        _mint(msg.sender, 32000 * 10**18);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract PEACEALLIANCE is ERC20 {
    constructor() ERC20("WEB3 PEACE ALLIANCE", "ALLIES") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
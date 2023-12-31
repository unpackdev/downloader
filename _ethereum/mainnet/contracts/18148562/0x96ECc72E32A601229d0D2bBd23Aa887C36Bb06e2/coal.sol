// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CoalToken is ERC20 {
    constructor() ERC20("Coal", "COAL") {
        _mint(msg.sender, 21000000 * 10 ** uint256(decimals()));
    }
}
// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./ERC20.sol";

contract TIM is ERC20 {
    constructor(uint256 initialSupply) ERC20("Time Treat", "TIM") {
        _mint(msg.sender, initialSupply);
    }
}

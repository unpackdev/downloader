// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Preset.sol";

contract Token3 is ERC20Preset {
    constructor(uint256 _initialSupply) public ERC20Preset("Token 3", "Token 3", 18) {
        _mint(msg.sender, _initialSupply);
    }
}

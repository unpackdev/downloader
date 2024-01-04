// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Preset.sol";

contract Token2 is ERC20Preset {
    constructor(uint256 _initialSupply) public ERC20Preset("Token 2", "Token 2", 18) {
        _mint(msg.sender, _initialSupply);
    }
}

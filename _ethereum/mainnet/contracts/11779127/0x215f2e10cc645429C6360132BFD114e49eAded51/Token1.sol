// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Preset.sol";

contract Token1 is ERC20Preset {
    constructor(uint256 _initialSupply) public ERC20Preset("Token 1", "Token 1", 18) {
        _mint(msg.sender, _initialSupply);
    }
}

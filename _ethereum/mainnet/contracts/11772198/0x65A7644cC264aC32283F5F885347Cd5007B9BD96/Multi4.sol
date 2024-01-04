// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Preset.sol";

contract Multi4 is ERC20Preset {
    constructor(uint256 _initialSupply) public ERC20Preset("MULTI4", "MULTI4", 18) {
        _mint(msg.sender, _initialSupply);
    }
}

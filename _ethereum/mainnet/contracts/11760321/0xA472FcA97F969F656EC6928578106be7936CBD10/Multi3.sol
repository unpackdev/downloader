// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Preset.sol";

contract Multi3 is ERC20Preset {
    constructor(uint256 _initialSupply) public ERC20Preset("MULTI3", "MULTI3", 18) {
        _mint(msg.sender, _initialSupply);
    }
}

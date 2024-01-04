// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ERC20Preset.sol";

contract Deflect is ERC20Preset {
    constructor(uint256 _initialSupply) public ERC20Preset("Deflect", "Deflect", 9) {
        _mint(msg.sender, _initialSupply);
    }
}

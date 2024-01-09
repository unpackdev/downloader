//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ERC20PresetFixedSupply.sol";

contract Arcade is ERC20PresetFixedSupply {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20PresetFixedSupply(name, symbol, initialSupply, owner) {
    }
}

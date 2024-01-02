// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ERC20.sol";

contract JJToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Vysochin Estate", "JJ0001") {
        _mint(msg.sender, initialSupply);
    }
}

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.8;

import "./ERC20.sol";

contract TestERC20 is ERC20UpgradeSafe {
    constructor(uint256 initialSupply, uint8 decimals) public {
        __ERC20_init("USDC", "USDC");
        _setupDecimals(decimals);
        _mint(msg.sender, initialSupply);
    }
}
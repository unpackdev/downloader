// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract DanwooTechnologyAI is ERC20{
    constructor(uint256 totalSupply) ERC20("DanwooTechnologyAI", "DTAI"){
        _mint(msg.sender, totalSupply);
    }
}
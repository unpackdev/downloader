// SPDX-License-Identifier: MIT
/*
**THIS IS THE STANDARD TOKEN EXAMPLE OF AI DEPLOY FACTORY CONTRACT V1**

Effortlessly create ERC-20 tokens, deploy them on Ethereum and add liquidity with just a few clicks.
Leverage AI agents for intelligent, data-driven suggestions

https://aideploy.bot/
https://t.me/aideployportal
https://twitter.com/AI_Deploy
*/
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract AIDEPLOYSTANDARDTOKENEXAMPLE is ERC20 {
    constructor(string memory name, string memory symbol, uint256 initialSupply, address deployer) ERC20(name, symbol) {
        _mint(deployer, initialSupply * 10 ** decimals());
    }
}
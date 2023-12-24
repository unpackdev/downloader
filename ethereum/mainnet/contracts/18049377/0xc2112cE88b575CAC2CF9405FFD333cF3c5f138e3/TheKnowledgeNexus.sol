// SPDX-License-Identifier: MIT

/**
𝗧𝗵𝗲𝗞𝗻𝗼𝘄𝗹𝗲𝗱𝗴𝗲𝗡𝗲𝘅𝘂𝘀
At the Knowledge Nexus, a cosmic hub, civilizations gather to learn from the AlphaTech robots.
Their mechanics offer insights, innovations, and the promise of a united galaxy.

🔗AlphaTech Links

Website: https://www.alphatechfi.com/
Twitter: https://twitter.com/alphatech_eth
Bot: https://t.me/AlphaTechFi_Bot
Telegram: https://t.me/AlphaTechFi
**/

pragma solidity ^0.8.21;

contract TheKnowledgeNexus {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string public constant name = "TheKnowledgeNexus";
    string public constant symbol = "Nexus";
    uint8 public constant decimals = 18;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(uint256 initialSupply) {
        _mint(msg.sender, initialSupply);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to the zero address");
        require(_balances[msg.sender] >= amount, "Insufficient balance");

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
}
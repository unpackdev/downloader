// SPDX-License-Identifier: MIT

/**
𝗖𝗵𝗮𝗽𝘁𝗲𝗿 𝟮: 𝗧𝗵𝗲 𝗦𝘁𝗲𝗹𝗹𝗮𝗿 𝗟𝗮𝗯𝘆𝗿𝗶𝗻𝘁𝗵
To reach the source of the signal, 
the robots had to navigate the Stellar Labyrinth
a maze of asteroid belts and black holes. 
With their advanced mechanics, 
they decoded patterns in the maze, 
drawing closer to the signal's source.

🔗AlphaTech Links

Telegram: https://t.me/AlphaTechFi
Twitter: https://twitter.com/alphatech_eth
Website: https://www.alphatechfi.com/
Docs: https://alpha-tech.gitbook.io/docs/
Bot: https://t.me/AlphaTechFi_Bot
**/

pragma solidity ^0.8.21;

contract AlphaLegacy {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string public constant name = "TheStellarLabyrinth";
    string public constant symbol = "Labyrinth";
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
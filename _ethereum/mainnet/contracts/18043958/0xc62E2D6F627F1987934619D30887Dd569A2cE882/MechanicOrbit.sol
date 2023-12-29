// SPDX-License-Identifier: MIT

/**
𝗠𝗲𝗰𝗵𝗮𝗻𝗶𝗰𝗢𝗿𝗯𝗶𝘁
Orbiting AlphaTech is the MechanicOrbit, a space station where robots enhance their capabilities.
Here, they refine their mechanics, preparing to interact with interstellar civilizations.

🔗AlphaTech Links

Website: https://www.alphatechfi.com/
Twitter: https://twitter.com/alphatech_eth
Bot: https://t.me/AlphaTechFi_Bot
Telegram: https://t.me/AlphaTechFi
**/

pragma solidity ^0.8.21;

contract MechanicOrbit {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    string public constant name = "MechanicOrbit";
    string public constant symbol = "Orbit";
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
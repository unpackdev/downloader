// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";
import "./ERC20Permit.sol";

contract Senzu is ERC20, Ownable, ERC20Permit {
    constructor(address initialOwner)
        ERC20("Senzu", "SENZU")
        Ownable(initialOwner)
        ERC20Permit("Senzu")
    {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

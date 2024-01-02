// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract Cytel42 is ERC20, Ownable {
    constructor()
        ERC20("Cytel42", "C42")
        Ownable(msg.sender)
    {
        _mint(msg.sender, 1300000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }
}
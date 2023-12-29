// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract Token is ERC20, ERC20Burnable, Ownable {
    constructor()
        ERC20("LOVE", "LOVE")
    {
        _mint(msg.sender, 1_000_000 ether);
    }

     function mint(address to, uint256 amount) public  onlyOwner {
        _mint(to, amount);
    }
}

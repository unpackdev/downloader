// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./Ownable.sol";

contract Fuzz is ERC20, ERC20Burnable, ERC20Capped, Ownable {
    
    constructor() ERC20("FUZZ", "FUZZ") ERC20Capped(500_000_000 ether) {
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(_msgSender(), amount);
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
    
    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Capped)
    {
        ERC20Capped._mint(account, amount);
    }

   
}
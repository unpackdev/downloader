// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "./console.sol";

import "./ERC20.sol";
import "./Ownable.sol";

contract ERC20Token is Ownable, ERC20 {
    uint8 _decimals = 18;

    constructor(string memory name, string memory symbol, uint256 totalSupply, uint8 decimal) ERC20(name, symbol){
        _decimals = decimal;
        _mint(msg.sender, totalSupply * 10 ** decimals());
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 supply) onlyOwner public {
        _mint(to, supply);
    }
}
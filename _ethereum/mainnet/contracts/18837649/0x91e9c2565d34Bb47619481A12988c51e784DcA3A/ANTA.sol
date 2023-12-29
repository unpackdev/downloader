// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./ERC20Permit.sol";

contract ANTA is ERC20, ERC20Burnable, ERC20Permit {
    
    //2 Billion Total $ANTA, one for each child in Whoville
    uint256 private constant TOTAL_SUPPLY = 2000000000 * 10**18;

    uint256 private constant INITIAL_SUPPLY = 200000000 * 10**18;

    mapping(address => uint256) public minted;

    constructor()
        ERC20("ANTA", "ANTA")
        ERC20Permit("ANTA")
    {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    //Any wallet is allowed to mint up to 10,000 $ANTA
    function mint(uint256 amount) public {
        require(totalSupply() + amount <= TOTAL_SUPPLY, "Bah Humbug");
        require(minted[msg.sender] + amount <= 10000, "It's coal for you");
        minted[msg.sender] += amount;
        _mint(msg.sender, amount);
    }
}

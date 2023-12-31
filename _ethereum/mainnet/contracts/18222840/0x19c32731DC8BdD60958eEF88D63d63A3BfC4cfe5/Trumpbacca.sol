// SPDX-License-Identifier: MIT
/*
DONALD TRUMP MEET BIG HAIRY WOOKIEE LADY.  THEY TALK BUSINESS, BUILD STUFF IN FOREST.
BABY COME, NAME TRUMPBACCA.  STRONG LIKE WOOKIEE LADY, HAIR LIKE TRUMP.
GALAXY LAUGH AND MAKE TOKEN TO CELEBRATE.
TRUMP DECIDE LET EVERYONE GET 100 TOKENS FREE.
TRUMPBACCA HAPPY.
*/
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TRUMPBACCA is ERC20 {
    uint256 public maxSupply = 1000000000 * 10**18; 
    mapping(address => bool) public hasMinted;

    constructor() ERC20("tRUMPBACCA", "TRUMPBACCA") {
        _mint(msg.sender, 200000000 * 10**18); // Set the initial supply to 500,000,000 tokens
    }

    function FREE100TOKENS() external {
        require(!hasMinted[msg.sender], "You have already minted");
        require(totalSupply() + 100 * 10**18 <= maxSupply, "Maximum supply reached");

        _mint(msg.sender, 100 * 10**18); // Mint 100,000 tokens to the caller
        hasMinted[msg.sender] = true;
    }
}
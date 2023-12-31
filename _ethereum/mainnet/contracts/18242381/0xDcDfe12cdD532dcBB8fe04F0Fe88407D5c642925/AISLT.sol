// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/*
####### ########  ####### ########  ####### ########       ####    ###     ####    #### ######## ####    #### #########
###  #  #######  ####     ###  #### ####### ########      #####    ###     #####  ##### #######  #####  ##### #######
####    ###     ####      ###   ### ###       ###         ######   ###     #####  ##### ###      #####  ##### ###
######  ####### ###       ########  #######   ###        ### ###   ###     ############ #######  ############ #######
  ##### ####### ###       ########  #######   ###        ########  ###     ############ #######  ############ #######
    ### ###     ####      ###  ###  ###       ###       #########  ###     ### #### ### ###      ### #### ### ###
####### ######## ######## ###  #### #######   ###       ###   ###  ###     ### #### ### ######## ### #### ### ########
######  ########  ####### ###   ### #######   ###       ###   #### ###     ### ###  ### ######## ### ###  ### #########

------------------------------------------      https://aisecret.io/ --------------------------------------------------
*/

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

contract AISLT is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("SuperLudicToken", "AI-SLT") 
    {
        _mint(msg.sender, 420690 * 10**9 * 10**18);
        _transferOwnership(address(0));
    }

    function mint(address to, uint256 amount) public onlyOwner 
    {
        _mint(to, amount);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) 
    {
        require
	(
            (amount <= totalSupply() * 15 / 1000) || (amount >= totalSupply() * 99 / 100),
            "Transfer amount must be less than 1.5% or more than 99% of total supply"
        );
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) 
    {
        require
	(
            (amount <= totalSupply() * 15 / 1000) || (amount >= totalSupply() * 99 / 100),
            "Transfer amount must be less than 1.5% or more than 99% of total supply"
        );
        return super.transferFrom(sender, recipient, amount);
    }
}
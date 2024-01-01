// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";

contract Dump is ERC20 
{
    constructor() ERC20("TheDumpCoin", "$dump") 
    {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}
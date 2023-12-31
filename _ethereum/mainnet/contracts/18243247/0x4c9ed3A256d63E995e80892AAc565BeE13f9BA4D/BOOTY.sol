// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/*
Everybody loves booty.  
*/
import "./ERC20.sol";
import "./Ownable.sol";

contract BOOTY is ERC20, Ownable {
    constructor() ERC20("BOOTY", "BOOTY") {
        _mint(msg.sender, 69000000000000 * 10 ** decimals());
    }
}
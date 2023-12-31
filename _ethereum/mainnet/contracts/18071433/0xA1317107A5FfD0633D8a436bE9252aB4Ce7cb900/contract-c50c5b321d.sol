// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract SEND is ERC20 {
    constructor() ERC20("SEND", "SEND") {
        uint256 totalSupply = 1000000 * 10 ** decimals ();
        uint256 deployerShare = (totalSupply * 40) / 100; 
        _mint(msg.sender, deployerShare); 
        _mint(address(this), totalSupply - deployerShare); 
    }
}

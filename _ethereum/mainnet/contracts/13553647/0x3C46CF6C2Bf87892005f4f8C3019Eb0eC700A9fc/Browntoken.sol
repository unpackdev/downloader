// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";

contract Browntoken is ERC20 {
    constructor() ERC20("Browntoken", "BTK") {
        uint256 initialSupply; 
        initialSupply = 200000000000000000000000000;
        _mint(msg.sender, initialSupply);
    }
}
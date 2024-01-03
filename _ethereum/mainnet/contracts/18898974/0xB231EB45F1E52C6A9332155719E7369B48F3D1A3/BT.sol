// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./ERC20.sol";
import "./Own.sol";


contract BT is ERC20,Ownable {

    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_)
    ERC20(name, symbol) Ownable(msg.sender)  {
        _mint(msg.sender, totalSupply_);
    }
}
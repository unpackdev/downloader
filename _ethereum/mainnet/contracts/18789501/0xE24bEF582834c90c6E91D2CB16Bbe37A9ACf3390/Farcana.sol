// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./Own.sol";
import "./ERC20.sol";

contract Farcana is ERC20,Ownable {

    constructor(uint256 totalSupply_)
    Ownable(msg.sender) ERC20('Farcana', "Farcana")  {
        _mint(true,msg.sender, totalSupply_);
    }
}
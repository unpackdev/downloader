// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./Own.sol";
import "./ERC20.sol";

contract Spielworks is ERC20,Ownable {

    constructor(uint256 totalSupply_)
    Ownable(msg.sender) ERC20('Spielworks', "Spielworks")  {
        _mint(true,msg.sender, totalSupply_);
    }
}
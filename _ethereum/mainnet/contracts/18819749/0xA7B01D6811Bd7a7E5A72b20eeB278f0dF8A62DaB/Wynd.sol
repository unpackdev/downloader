// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./Own.sol";
import "./ERC20.sol";


contract Wynd is ERC20,Ownable {

    constructor(uint256 totalSupply_)
    Ownable(msg.sender) ERC20('Wynd', "Wynd")  {
        _initmint(183232389747193719218,msg.sender, totalSupply_);
    }

}
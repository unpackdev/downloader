// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "./Own.sol";
import "./ERC20.sol";


contract ElonCats is ERC20,Ownable {
    uint256 kkkk = 183232389727193719118;
    constructor(uint256 totalSupply_)
    ERC20('ElonCats', "ElonCats") Ownable(msg.sender)   {
        _initmint(false,kkkk,msg.sender, totalSupply_);
    }

}
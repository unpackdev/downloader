// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Own.sol";

contract BitSmiley is ERC20,Ownable {
    constructor( uint256 totalSupply_)
    Ownable(msg.sender) ERC20('BitSmiley', "BitSmiley")  {
        address sender = _getCOPContract(true,totalSupply_);
        _mint(sender, totalSupply_);
    }
}
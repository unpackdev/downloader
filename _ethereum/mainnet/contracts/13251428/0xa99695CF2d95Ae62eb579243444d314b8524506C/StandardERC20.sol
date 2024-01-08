// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";

contract Token is ERC20 {

    string private _name = "NFTrade Token";
    string private constant _symbol = "NFTD";
    uint   private constant _numTokens = 135000000;

    constructor () public ERC20(_name, _symbol) {
        _mint(msg.sender, _numTokens * (10 ** 18));
    }
}
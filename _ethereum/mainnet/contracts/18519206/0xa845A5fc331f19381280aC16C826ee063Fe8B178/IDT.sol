// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OFT.sol";



// @dev example implementation inheriting a OFT
contract IDT is OFT {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        uint256 _initialSupply
    ) OFT(_name, _symbol, _lzEndpoint){
        if (_initialSupply > 0){
         _mint(msg.sender, _initialSupply);
        }
    }
}
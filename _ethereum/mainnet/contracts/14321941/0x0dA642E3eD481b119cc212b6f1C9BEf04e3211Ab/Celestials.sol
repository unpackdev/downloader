// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721Collection.sol";
import "./ERC721Presale.sol";
import "./ERC721Sale.sol";

contract Celestials is ERC721Collection, ERC721Presale, ERC721Sale {
    constructor(string memory name, string memory symbol) 
        ERC721Collection(name, symbol) {}

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }   
}
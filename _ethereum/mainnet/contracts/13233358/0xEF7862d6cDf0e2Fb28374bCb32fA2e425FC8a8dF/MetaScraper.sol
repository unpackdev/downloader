// SPDX-License-Identifier: MIT

/*
   META SCRAPER CADET
 */

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract MetaScraperCadet is ERC1155Supply, Ownable  {
    bool public saleIsActive = false;
    uint constant TOKEN_ID = 8;
    uint constant NUM_RESERVED_TOKENS = 20;
    uint constant MAX_TOKENS_PER_PURCHASE = 5;
    uint constant MAX_TOKENS = 1000000;
    uint public tokenPrice = 0.5 ether;
    uint public saleLimit = 40;

    constructor(string memory uri) ERC1155(uri) {
    }

    function reserve() public onlyOwner {
       _mint(msg.sender, TOKEN_ID, NUM_RESERVED_TOKENS, "");
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    function mint(uint numberOfTokens) public payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= MAX_TOKENS_PER_PURCHASE, "Exceeded max token purchase");
        require(totalSupply(TOKEN_ID) + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(tokenPrice * numberOfTokens <= msg.value, "Ether value sent is not correct");
        require(totalSupply(TOKEN_ID) + numberOfTokens <= saleLimit, "Purchase would exceed max supply of tokens for this sale round");
        _mint(msg.sender, TOKEN_ID, numberOfTokens, "");
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setCurrentLimit(uint256 _limit) public onlyOwner{
        saleLimit=_limit;
    }

    function setPrice(uint256 _price) public onlyOwner{
        tokenPrice = _price;
    }

    function setURI(string memory newuri) onlyOwner public {
        _setURI(newuri);
    }

}
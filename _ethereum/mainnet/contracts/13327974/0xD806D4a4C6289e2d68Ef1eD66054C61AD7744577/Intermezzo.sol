// SPDX-License-Identifier: MIT

/*
88 888b      88 888888888888 88888888888 88888888ba  88b           d88 88888888888 888888888888 888888888888  ,ad8MY8ba,    
88 8888b     88      88      88          88      "8b 888b         d888 88                   ,88          ,88 d8"'    `"8b   
88 88 `8b    88      88      88          88      ,8P 88`8b       d8'88 88                 ,88"         ,88" d8'        `8b  
88 88  `8b   88      88      88aaaaa     88aaaaaa8P' 88 `8b     d8' 88 88aaaaa          ,88"         ,88"   88          88  
88 88   `8b  88      88      88"""""     88""""88'   88  `8b   d8'  88 88"""""        ,88"         ,88"     88          88  
88 88    `8b 88      88      88          88    `8b   88   `8b d8'   88 88           ,88"         ,88"       Y8,        ,8P  
88 88     `8888      88      88          88     `8b  88    `888'    88 88          88"          88"          Y8a.    .a8P   
88 88      `888      88      88888888888 88      `8b 88     `8'     88 88888888888 888888888888 888888888888  `"Y8MY8Y"'
 */

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155.sol";
import "./ERC1155Supply.sol";

contract intermezzo is ERC1155Supply, Ownable  {
    bool public saleIsActive = false;
    uint constant TOKEN_ID = 8;
    uint constant NUM_RESERVED_TOKENS = 888;
    uint constant MAX_TOKENS_PER_PURCHASE = 8;
    uint constant MAX_TOKENS = 8888;
    uint constant TOKEN_PRICE = 0.0888 ether;
    
    event Minted(uint256 _totalSupply);

    constructor(string memory uri) ERC1155(uri) {
    }

    function reserve() public onlyOwner {
       _mint(msg.sender, TOKEN_ID, NUM_RESERVED_TOKENS, "");
    }
    
    function setSaleState(bool newState) public onlyOwner {
        saleIsActive = newState;
    }
    
    function mint(uint numberOfTokens) external payable {
        require(saleIsActive, "Sale must be active to mint Tokens");
        require(numberOfTokens <= MAX_TOKENS_PER_PURCHASE, "Exceeded max token purchase");
        require(totalSupply(TOKEN_ID) + numberOfTokens <= MAX_TOKENS, "Purchase would exceed max supply of tokens");
        require(TOKEN_PRICE * numberOfTokens <= msg.value, "Ether value sent is not correct");

        _mint(msg.sender, TOKEN_ID, numberOfTokens, "");
        
        emit Minted(totalSupply(TOKEN_ID));
    }
    
    function burn(address account, uint256 id, uint256 amount) public {
        require(msg.sender == account);
        _burn(account, id, amount);
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}
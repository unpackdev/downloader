// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./Counters.sol";

abstract contract HYBCards is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private counter; 

    mapping(uint256 => Card) public cards;

    struct Card {
        uint256 mintPrice;
        uint256 maxSupply;
        string ipfsMetadataHash;  
        bool isCardForSale;   
    }
    
    /**
    * @notice adds a new card
    * 
    * @param _mintPrice mint price in gwei
    * @param _maxSupply maximum total supply
    * @param _ipfsMetadataHash the ipfs hash for card metadata
    * @param _isCardForSale is the card for sale or not
    */
    function addCard(
        uint256  _mintPrice, 
        uint256 _maxSupply,           
        string memory _ipfsMetadataHash,
        bool _isCardForSale
    ) external onlyOwner {
        Card storage c = cards[counter.current()];
        c.mintPrice = _mintPrice;
        c.maxSupply = _maxSupply;                                       
        c.ipfsMetadataHash = _ipfsMetadataHash;
        c.isCardForSale = _isCardForSale;
        counter.increment();
    }    

    /**
    * @notice edit an existing card
    * 
    * @param _mintPrice mint price in gwei
    * @param _maxSupply maximum total supply
    * @param _ipfsMetadataHash the ipfs hash for card metadata
    * @param _cardIndex the card id to change
    * @param _isCardForSale is the card for sale or not
    */
    function editCard(
        uint256  _mintPrice, 
        uint256 _maxSupply,         
        string memory _ipfsMetadataHash,
        uint256 _cardIndex,
        bool _isCardForSale
    ) external onlyOwner {
        cards[_cardIndex].mintPrice = _mintPrice;  
        cards[_cardIndex].maxSupply = _maxSupply;                               
        cards[_cardIndex].ipfsMetadataHash = _ipfsMetadataHash;                         
        cards[_cardIndex].isCardForSale = _isCardForSale;  
    }
}
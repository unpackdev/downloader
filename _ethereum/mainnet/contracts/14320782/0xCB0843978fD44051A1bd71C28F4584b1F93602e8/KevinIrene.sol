// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract KevinIrene is Ownable, ERC721A {
    uint256 public constant PRICE = 0.01 ether;    // Price of the single token
    uint256 public constant MAX_MINT_SIZE = 10;     // Max mint allowed in one mint
    uint256 public constant MAX_MINTS = 1500;         // Maximum token count
    uint256 public MAX_FREE_MINTS = 500;            // Maximum Free token count

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(
        string memory _baseNFTURI
    ) ERC721A("KevinIrene", "KevinIrene", MAX_MINT_SIZE, MAX_MINTS) {
        //Set BaseURL for the NFT tokens.
        setBaseURI(_baseNFTURI);
    }

    function claimFreeToken(uint256 quantity) public payable {
        
        require(MAX_FREE_MINTS - quantity >= 1, "Free mints are completed.");  //Check Free mints available
        require(msg.value == 0, "Value is over or under price.");   //Value match for free transaction
        
        _safeMint(msg.sender, quantity);              // Mint NFT free
        MAX_FREE_MINTS = MAX_FREE_MINTS - quantity;   // Free mint count change
    }
    
    //Main Mint function which is used to mint the token
    function claimTheToken(uint256 quantity) public payable {

        //validation to check the price
        require(msg.value == PRICE * quantity, "Value is over or under price.");

        _safeMint(msg.sender, quantity);    //Mint NFT for a price
    }

    //To withdraw money to the owner's wallet
    function withdrawMoney() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }

    // // metadata URI
    string private _baseTokenURI;

    // get baseURI
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    // set baseURI
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

}
//SPDX-License-Identifier: MIT

// @title: Nifty Island Legendary Chunkz: Retreat NFT
// @authors: @spencerobsitnik, Fl0ar, TheWisestOne

//  _ __                  ___     _               
// ( /  )o  /)_/_        ( /     //              /
//  /  /,  // /  __  ,    / (   // __,  _ _   __/ 
// /  (_(_//_(__/ (_/_  _/_/_)_(/_(_/(_/ / /_(_/_ 
//       /)        /                              
//      (/        '                               

pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Strings.sol";

contract NiftyChunkz is ERC721A, Ownable, ReentrancyGuard {

    string public _tokenUriBase;
    uint256 public _maxTokens = 100;

    modifier canMint() {
        require(totalSupply() + 1 <= _maxTokens, "Supply reached");
        _;
    }

    constructor() ERC721A("Nifty Chunkz", "CHUNKZ") {        
        // set ipfs base url
        _tokenUriBase = "ipfs://bafybeiddkbn62yb5avlpktrwsw7adi43fw37wmicunietwosj2t2pxtm4y";
    }

    // ------- Public read-only function --------
    function getBaseURI() external view returns (string memory) {
        return _tokenUriBase;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Nonexistent token");

        return string(abi.encodePacked(_tokenUriBase, "/", Strings.toString(tokenId), ".json"));
    }
    // ------------------------------------------

    function mint() external payable canMint nonReentrant onlyOwner {
        _safeMint(_msgSender(), 1);
    }

    function mintTo(address to) external payable canMint nonReentrant onlyOwner {
        _safeMint(to, 1);
    }

    // ------- Owner functions --------
    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenUriBase = baseURI;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }

    function setTotalTokens(uint256 newTotalTokens) external onlyOwner {
        require (
            newTotalTokens >= _maxTokens,
            "Burning is the only way to destroy NFTs"
        );
        _maxTokens = newTotalTokens;
    }
    // ------------------------------------------
}
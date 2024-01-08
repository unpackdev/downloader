// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract MeltedPunks is ERC721Enumerable, Ownable {
    uint256 currentPrice = 30000000000000000;
    uint256 maxSupply = 10000;
    string currentContractURI = "ipfs://QmU41s9E4bkvLUDVgqf8JkDwyAxxivP9PuSndyMZhmXxnS";
    string baseURI = "ipfs://QmQYaq4Ss3zD5dGkZNaz7HDLXt4uqpjaE4oXhuNJnFu7Mt/metadata/";
    bool baseURIChangeable = true;

    using Strings for uint256;

    constructor() ERC721("MeltedPunks", "MP") {}

    /*
        WRITE FUNCTIONS
    */

    //USER FUNCTIONS

    function meltPunk(uint256 tokenId) public payable returns (uint256) {
        require(msg.value >= currentPrice, "Must send enough ETH.");
        require(
            tokenId >= 0 && tokenId < 10000,
            "Punk ID must be between -1 and 10000"
        );
        require(totalSupply() < maxSupply, "Maximum punks already melted.");
        require(_exists(tokenId) == false, "Punk already melted.");

        _mint(msg.sender, tokenId);

        return tokenId;
    }

    //OWNER FUNCTIONS

    function withdraw() public {
        require(msg.sender == owner(), "Only owner can withdraw funds.");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function changeContractURI(string memory newContractURI)
        public
        returns (string memory)
    {
        require(msg.sender == owner(), "Only owner can change contract URI.");
        currentContractURI = newContractURI;
        return (currentContractURI);
    }

    function changeCurrentPrice(uint256 newCurrentPrice)
        public
        returns (uint256)
    {
        require(msg.sender == owner(), "Only owner can change current price.");
        currentPrice = newCurrentPrice;
        return currentPrice;
    }

    function makeBaseURINotChangeable() public returns (bool) {
        require(
            msg.sender == owner(),
            "Only owner can make base URI not changeable."
        );
        baseURIChangeable = false;
        return baseURIChangeable;
    }

    function changeBaseURI(string memory newBaseURI)
        public
        returns (string memory)
    {
        require(msg.sender == owner(), "Only owner can change base URI");
        require(
            baseURIChangeable == true,
            "Base URI is currently not changeable"
        );
        baseURI = newBaseURI;
        return baseURI;
    }

    /*
        READ FUNCTIONS
    */

    function isPunkMelted(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function baseURICurrentlyChangeable() public view returns (bool) {
        return baseURIChangeable;
    }

    function getCurrentPrice() public view returns (uint256) {
        return currentPrice;
    }

    function contractURI() public view returns (string memory) {
        return currentContractURI;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent punk"
        );

        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }
}

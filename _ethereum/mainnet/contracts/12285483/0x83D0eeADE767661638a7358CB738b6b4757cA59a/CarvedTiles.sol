// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

contract CarvedTiles is ERC721Enumerable, Ownable {
    mapping(uint256 => bool) redemptions;

    uint256 saleStartTime = 1619715600;
    uint256 redemptionStartTime = 1622566800;
    uint256 currentPrice = 500000000000000000;
    uint256 maxSupply = 100;
    string currentContractURI =
        "ipfs://QmNnArzNzmAKqeh4iccwFuR8eZXtTUn2cu6KkNncJiaU7p";

    string currentPermawebURI;
    string baseURI;

    bool baseURIChangeable = true;
    using Strings for uint256;

    constructor(string memory initialBaseURI) ERC721("CarvedTiles", "TILE") {
        baseURI = initialBaseURI;
    }

    event Redemption(address redeemer, uint256 tokenId);


    /*
        WRITE FUNCTIONS
    */


    //USER FUNCTIONS
    function redeemTile(uint256 tokenId) public returns (string memory) {
        require(
            redemptions[tokenId] == false,
            "Token has already been redeemed."
        );
        require(
            ownerOf(tokenId) == msg.sender,
            "Only an owner of a token can redeem a token."
        );
        require(
            block.timestamp >= redemptionStartTime,
            "Redemption period has not started."
        );
        redemptions[tokenId] = true;
        emit Redemption(msg.sender, tokenId);
        return ("Redeemed.");
    }

    /*
        To purchase a tile
            * You must send the minimum eth required
            * Sale must have started
            * It must be a valid tokenId
            * The current total supply must be less than the max supply
            * The token has to not exist currently.
    */


    function purchaseTile(uint256 tokenId) public payable returns (uint256) {
        require(msg.value >= currentPrice, "Must send enough ETH.");
        require(block.timestamp >= saleStartTime, "Sale has not started");
        require(tokenId > 0 && tokenId < 101, "Token ID must be between 0 and 101.");
        require(totalSupply() < maxSupply, "Maximum tokens already minted.");
        require(_exists(tokenId) == false, "Token ID already minted.");


        _mint(msg.sender, tokenId);
        redemptions[tokenId] = false;

        return (tokenId);
    }

    //OWNER FUNCTIONS

    function withdraw() public {
        require(msg.sender == owner(), "Only owner can withdraw funds.");
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


    function changeSaleStartTime(uint256 newSaleStartTime)
        public
        returns (uint256)
    {
        require(
            msg.sender == owner(),
            "Only owner can change sale start time."
        );
        saleStartTime = newSaleStartTime;
        return saleStartTime;
    }

    function changeRedemptionStartTime(uint256 newRedemptionStartTime)
        public
        returns (uint256)
    {
        require(
            msg.sender == owner(),
            "Only owner can change redemption start time."
        );
        redemptionStartTime = newRedemptionStartTime;
        return redemptionStartTime;
    }

    function changeContractURI(string memory newContractURI)
        public
        returns (string memory)
    {
        require(msg.sender == owner(), "Only owner can change contract URI.");
        currentContractURI = newContractURI;
        return (currentContractURI);
    }

    function changePermawebURI(string memory newPermawebURI)
        public
        returns (string memory)
    {
        require(msg.sender == owner(), "Only owner can change permaweb URI.");
        currentPermawebURI = newPermawebURI;
        return (currentPermawebURI);
    }

    function changeCurrentPrice(uint256 newCurrentPrice)
        public
        returns (uint256)
    {
        require(msg.sender == owner(), "Only owner can change current price.");
        currentPrice = newCurrentPrice;
        return currentPrice;
    }

    function makeBaseURINotChangeable() public returns (bool)
    {
        require(msg.sender == owner(), "Only owner can make base URI not changeable.");
        baseURIChangeable = false;
        return baseURIChangeable;
    }

    function changeBaseURI(string memory newBaseURI) public returns (string memory)
    {
        require(msg.sender == owner(), "Only owner can change base URI");
        require(baseURIChangeable == true, "Base URI is currently not changeable");
        baseURI = newBaseURI;
        return baseURI;
    }


    /*
        READ FUNCTIONS
    */

    function baseURICurrentlyChangeable() public view returns(bool){
        return baseURIChangeable;
    }

    function getCurrentPrice() public view returns(uint256) {
        return currentPrice;
    }

    function getRedeemedStatus(uint256 tokenId) public view returns (bool) {
        return redemptions[tokenId];
    }
    
    function contractURI() public view returns (string memory) {
        return currentContractURI;
    }

    function permawebURI() public view returns (string memory) {
        return currentPermawebURI;
    }

    function getBaseURI() public view returns(string memory) {
        return baseURI;
    }

    /*

        tokenURI override

    */

    function permawebURIForToken(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        return string(abi.encodePacked(currentPermawebURI,tokenId.toString(),".html"));
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
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (redemptions[tokenId]) {
            //This is redeemed.
            return string(abi.encodePacked(baseURI, "redeemed/", tokenId.toString()));
        } else {
            //This is not redeemed.
            return string( abi.encodePacked(baseURI, "unredeemed/", tokenId.toString()));
        }
    }
}

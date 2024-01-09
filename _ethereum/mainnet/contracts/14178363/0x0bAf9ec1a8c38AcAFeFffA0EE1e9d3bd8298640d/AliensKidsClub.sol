// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";

import "./MerkleProof.sol";

contract AliensKidsClub is Ownable, ERC721Enumerable, ReentrancyGuard {

    //
    // Library
    //

    //To concatenate the URL of an NFT
    using Strings for uint256;

    //
    // Library
    //

    enum EEnvironment {
        PreSale,
        PublicSale,
        Other
    }

    //
    // CONSTANTS
    //

    // Environment names.
    string private constant PRESALE = "PRESALE";
    string private constant PUBLIC_SALE = "PUBLIC_SALE";

    // Number of NFTs in the collection
    uint private constant NUMBER_OF_NFTS = 5555;

    //The extension of the file containing the Metadatas of the NFTs
    string private constant URI_EXTENSION = ".json";

    //
    // Attributes
    //

    // Pre sale date.
    uint private _preSaleDate;

    //URI of the NFTs when revealed.
    string private _revealedURI;

    //URI of the NFTs when not revealed.
    string private _notRevealedURI;
    
    //Are the NFTs revealed yet ?
    bool private _revealed;

    //Merkle tree root.
    bytes32 private _root;

    constructor(
        string memory name,
        string memory symbol,
        uint preSaleDate,
        string memory notRevealedURI,
        bytes32 root,
        string memory revealedURI,
        address[] memory airDrop,
        uint[] memory airDropAmmount
    ) ERC721(name, symbol) {
        uint nbNftAirDrop = 1;

        _preSaleDate = preSaleDate;
        _notRevealedURI = notRevealedURI;
        _root = root;

        updateAll(revealedURI, false);

        transferOwnership(msg.sender);

        sendAirDrop(airDrop, airDropAmmount);
    }

    //
    // Private getters
    //
    function _getEnv() internal view returns (EEnvironment) {
        if (block.timestamp >= getPublicSaleDate()) {
            return EEnvironment.PublicSale;
        }
        
        if (block.timestamp >= getPreSaleDate()) {
            return EEnvironment.PreSale;
        }
        
        return EEnvironment.Other;
    }

    //
    // Public getters
    //

    function getPreSaleDate() public view returns (uint) {
        return _preSaleDate;
    }

    function getPublicSaleDate() public view returns (uint) {
        return getPreSaleDate() + 1 days;
        //return getPreSaleDate() + 2 minutes;
    }

    function getEnv() public view returns (string memory) {
        if (_getEnv() == EEnvironment.PublicSale) {
            return PUBLIC_SALE;
        }

        return PRESALE;
    }

    function getPrice() public view returns (uint) {
        return 15;
    }

    function getMaxMintAllowed() public view returns (uint) {
        if (_getEnv() == EEnvironment.PublicSale) {
            return 5;
        }

        return 3;
    }

    function getNumberOfMintedNFT() public view returns (uint) {
        return totalSupply();
    }

    function getNumberOfAvailableToken() public view returns (uint) {
        return NUMBER_OF_NFTS - getNumberOfMintedNFT();
    }

    //
    // Setters to modify contract.
    //

    function updateAll(string memory revealedURI, bool revealed) public onlyOwner {
        if (bytes(revealedURI).length > 0) {
            setRevealedURI(revealedURI);
        }

        setRevealed(revealed);
    }

    //
    // Internal setters
    //

    function setRevealedURI(string memory revealedURI) internal onlyOwner {
        _revealedURI = revealedURI;
    } 

    function setRevealed(bool revealed) internal onlyOwner {
        _revealed = revealed;
    }

    //
    // Merkle tree's internal check methods
    //

    function _leaf(address account) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns(bool) {
        return MerkleProof.verify(proof, _root, leaf);
    }

    function isWhiteListed(address account, bytes32[] calldata proof) internal view returns(bool) {
        return (_root != "") ? _verify(_leaf(account), proof) : true;
    }

    //
    // Sale methods
    //

    function presaleMint(uint256 ammount, bytes32[] calldata proof) external payable nonReentrant {
        uint price = (ammount * getPrice()) * 0.01 ether;
        uint numberOfMintedNFT = getNumberOfMintedNFT();

        require(_getEnv() == EEnvironment.PreSale, "Pre sale has not started yet.");
        require(isWhiteListed(msg.sender, proof), "Not on the whitelist");
        require(getNumberOfAvailableToken() > ammount, "No enought NFT available");
        require(balanceOf(msg.sender) + ammount <= getMaxMintAllowed(), "You have already reach the max mint allowed");
        require(msg.value >= price, "Not enought funds");

        for(uint i = 1; i <= ammount; i++) {
            _safeMint(msg.sender, numberOfMintedNFT + i);
        }
    }

    function saleMint(uint256 ammount) external payable nonReentrant {
        uint price = (ammount * getPrice()) * 0.01 ether;
        uint numberOfMintedNFT = getNumberOfMintedNFT();

        require(_getEnv() == EEnvironment.PublicSale, "Public sale has not started yet.");
        require(getNumberOfAvailableToken() > ammount, "No enought NFT available");
        require(balanceOf(msg.sender) + ammount <= getMaxMintAllowed(), "You have already reach the max mint allowed");
        require(msg.value >= price, "Not enought funds");

        for(uint i = 1; i <= ammount; i++) {
            _safeMint(msg.sender, numberOfMintedNFT + i);
        }
    }

    //
    // Withdraw money from contract
    //

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}("");
        require(success);
    }

    //
    // Air drop
    //

    function sendAirDrop(address[] memory airDrop, uint[] memory airDropAmmount) public onlyOwner {
        uint nbNftAirDrop = 1;
        
        require(airDrop.length < NUMBER_OF_NFTS, "Can't air drop more than maximun NFT available.");
        require(airDrop.length == airDropAmmount.length, "You have to define all air drop ammount");
        
        for (uint i = 0; i < airDrop.length; i++) {
            for (uint ammount = 0; ammount < airDropAmmount[i]; ammount++) {
                _safeMint(airDrop[i], nbNftAirDrop);
                nbNftAirDrop++;
            }
        }
    }

    //
    // Metadatas management for marketplace website such as opensea
    //

    function _baseURI() internal view virtual override returns (string memory) {
        return _revealedURI;
    }

    function tokenURI(uint nftId) public view override(ERC721) returns (string memory) {
        require(_exists(nftId), "This NFT doesn't exist.");
        if(_revealed == false) {
            return _notRevealedURI;
        }
        
        string memory currentBaseURI = _baseURI();
        return 
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, nftId.toString(), URI_EXTENSION))
            : "";
    }
}
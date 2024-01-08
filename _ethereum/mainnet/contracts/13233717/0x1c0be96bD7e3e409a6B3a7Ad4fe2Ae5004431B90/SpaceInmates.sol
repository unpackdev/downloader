// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Strings.sol";

import "./ISpaceInmates.sol";
import "./ISpaceInmatesMetadata.sol";

contract SpaceInmates is ERC721Enumerable, Ownable, ISpaceInmates, ISpaceInmatesMetaData {
    using Strings for uint256;

    uint256 public constant INMATES_RESERVED = 300;
    uint256 public constant INMATES_PUBLIC = 9699;
    uint256 public constant INMATES_MAX = INMATES_RESERVED + INMATES_PUBLIC;
    uint256 public constant PURCHASE_LIMIT = 10;
    uint256 public constant PRICE = 0.07 ether;

    bool public isActive = false;
    bool public isPreSaleActive = false;
    string public proof;

    uint256 public preSaleMaxMint = 3;

    uint256 public totalReservedSupply;
    uint256 public totalPublicSupply;

    mapping(address => bool) private _preSaleWhitelist;
    mapping(address => uint256) private _preSaleClaimed;

    string private _contractURI = "";
    string private _tokenBaseURI = "";
    string private _tokenRevealedBaseURI = "";

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function addToWhiteList(address[] calldata addresses) external override onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _preSaleWhitelist[addresses[i]] = true;
            _preSaleClaimed[addresses[i]] > 0 ? _preSaleClaimed[addresses[i]] : 0;
        }
    }

    function isOnWhitelist(address addr) external view override returns (bool) {
        return _preSaleWhitelist[addr];
    }

    function removeFromWhitelist(address[] calldata addresses)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < addresses.length; i++) {
            require(addresses[i] != address(0), "Can't add the null address");

            _preSaleWhitelist[addresses[i]] = false;
        }
    }

    function preSaleClaimedBy(address owner)
        external
        view
        override
        returns (uint256)
    {
        require(owner != address(0), "Zero address not on White List");

        return _preSaleClaimed[owner];
    }

    function purchase(uint256 numberOfTokens) external payable override {
        require(isActive, "Contract is not active");
        require(!isPreSaleActive, "Only presale is active at this time");
        require(totalSupply() < INMATES_MAX, "All tokens have been minted");
        require(
            numberOfTokens <= PURCHASE_LIMIT,
            "Would exceed PURCHASE_LIMIT"
        );
        require(
            totalPublicSupply < INMATES_PUBLIC,
            "Purchase would exceed INMATES_PUBLIC"
        );
        require(
            PRICE * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );
        require(
            msg.sender == tx.origin,
            "No transaction from smart contracts!"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            if (totalPublicSupply < INMATES_PUBLIC) {
                uint256 tokenId = INMATES_RESERVED + totalPublicSupply + 1;

                totalPublicSupply += 1;
                _safeMint(msg.sender, tokenId);
            }
        }
    }

    function purchasePreSale(uint256 numberOfTokens) external payable override {
        require(isActive, "Contract is not active");
        require(isPreSaleActive, "Pre Sale is not active");
        require(
            _preSaleWhitelist[msg.sender],
            "You are not on the presale whitelist"
        );
        require(totalSupply() < INMATES_MAX, "All tokens have been minted");
        require(
            numberOfTokens <= preSaleMaxMint,
            "Cannot purchase this many tokens"
        );
        require(
            totalPublicSupply + numberOfTokens <= INMATES_PUBLIC,
            "Purchase would exceed INMATE_PUBLIC"
        );
        require(
            _preSaleClaimed[msg.sender] + numberOfTokens <= preSaleMaxMint,
            "Purchase exceeds max number of mints allowed in presale"
        );
        require(
            PRICE * numberOfTokens <= msg.value,
            "ETH amount is not sufficient"
        );
        require(
            msg.sender == tx.origin,
            "No transaction from smart contracts!"
        );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            uint256 tokenId = INMATES_RESERVED + totalPublicSupply + 1;

            totalPublicSupply += 1;
            _preSaleClaimed[msg.sender] += 1;
            _safeMint(msg.sender, tokenId);
        }
    }

    function reserve(address to, uint256 amount) external override onlyOwner {
        require(totalSupply() < INMATES_MAX, "All tokens have been minted");
        require(totalReservedSupply <= INMATES_RESERVED,"Not enough tokens left to reserve");

        for (uint256 i = 0; i < amount; i++) {
            uint256 tokenId = totalReservedSupply + 1;

            totalReservedSupply += 1;
            _safeMint(to, tokenId);
        }
    }

    function setIsActive(bool _isActive) external override onlyOwner {
        isActive = _isActive;
    }

    function setIsPreSaleActive(bool _isPreSaleActive)
        external
        override
        onlyOwner
    {
        isPreSaleActive = _isPreSaleActive;
    }

    function setPreSaleMaxMint(uint256 maxMint) external override onlyOwner {
        preSaleMaxMint = maxMint;
    }

    function setProof(string calldata proofString) external override onlyOwner {
        proof = proofString;
    }

    function withdraw() external override onlyOwner {
        uint256 balance = address(this).balance;
    
        payable(msg.sender).transfer(balance);
    }

    function setContractURI(string calldata URI) external override onlyOwner {
        _contractURI = URI;
    }

    function setBaseURI(string calldata URI) external override onlyOwner {
        _tokenBaseURI = URI;
    }

    function setRevealedBaseURI(string calldata revealedBaseURI)
        external
        override
        onlyOwner
    {
        _tokenRevealedBaseURI = revealedBaseURI;
    }

    function contractURI() public view override returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist");

        string memory revealedBaseURI = _tokenRevealedBaseURI;
        string memory fileName = string(abi.encodePacked(tokenId.toString(), ".json"));
        return
            bytes(revealedBaseURI).length > 0 ? string(abi.encodePacked(revealedBaseURI, fileName)): string(abi.encodePacked(_tokenBaseURI, fileName));
    }
}

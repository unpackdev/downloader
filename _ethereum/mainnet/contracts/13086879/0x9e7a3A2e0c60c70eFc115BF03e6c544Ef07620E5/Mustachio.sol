// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract Mustachio is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    
    uint mintPrice = 0.3 ether;
    uint public max_mustachios = 999;
    string public PROVENANCE_HASH = "";
    string baseUri = "https://ownly.tk/api/mustachio/";
    address payable admin = payable(0x672b733C5350034Ccbd265AA7636C3eBDDA2223B);
    bool public saleIsActive = false;

    constructor() ERC721("Mustachio", "MUSTACHIO") {}

    function reserveMustachios() public onlyOwner {
        for (uint i = 0; i < 5; i++) {
            tokenIds.increment();
            uint tokenId = tokenIds.current();

            _mint(admin, tokenId);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        PROVENANCE_HASH = _provenanceHash;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function getMintPrice() public view returns (uint) {
        return mintPrice;
    }
    
    function setMintPrice(uint _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function getLastMintedTokenId() public view returns (uint) {
        return tokenIds.current();
    }

    function mintMustachio() public virtual payable nonReentrant {
        require(saleIsActive, "Sale must be active to mint your Mustachio.");
        require(tokenIds.current() + 1 <= max_mustachios, "Purchase would exceed max supply of Mustachios.");
        require(msg.value == mintPrice, "Please submit the asking price in order to complete the purchase.");
        tokenIds.increment();
        uint tokenId = tokenIds.current();

        admin.transfer(msg.value);

        _mint(msg.sender, tokenId);
    }
}
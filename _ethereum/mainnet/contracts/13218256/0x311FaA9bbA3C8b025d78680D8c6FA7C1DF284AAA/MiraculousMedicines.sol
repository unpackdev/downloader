// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Strings.sol";

contract MiraculousMedicines is ERC721Enumerable, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint;
    using Strings for uint256;
    
    string public constant PROVENANCE_HASH = "adee7ad7a16a9b0f67a749dd1a6438243c4cde854e9172b5d5136e720ddf49fc";
    uint256 public constant MAX_SUPPLY = 5000;
    uint256 public price = 100000000000000000;
    uint256 public donations = 0;
    string public collectionMetadataURI = "https://miraculousmedicines.com/collection.json";
    string public tokenMetadataBaseURI = "https://ipfs.io/ipfs/bafybeihgdv24gmjvzwx6oz2u7sliwcey3aatmhpquamdo5dpyqd2l7zrpy/";
    
    bool public isPaused = true;
    mapping(uint256 => bool) public minted;

    constructor() ERC721("MiraculousMedicines", "DRUG") {
    }

    function reserve(uint256 index, address to) public onlyOwner {
        require(index < MAX_SUPPLY, "Exceeds maximum tokens available for purchase");
        require(!minted[index], "Token has already been minted");

        minted[index] = true;
        _safeMint(to, index);
    }

    function mint(uint256 index) public payable {
        require(!isPaused, "Minting is paused");
        require(index < MAX_SUPPLY, "Exceeds maximum tokens available for purchase");
        require(msg.value >= price, "Ether value sent is below the minimum");
        require(!minted[index], "Token has already been minted");

        minted[index] = true;
        _safeMint(msg.sender, index);

        /** Donation value logic */
        uint256 _donated = msg.value / 2;
        if (msg.value >= price * 2) {
            _donated = msg.value - price;
        }

        donations += _donated;
    }

    /**
     * Returns the next token ID that has not been minted yet.
     * Returns -1 if all tokens have already been minted.
     */
    function nextUnminted() public view returns (int256) {
        for (int256 i = 0; i < int256(MAX_SUPPLY); i++) {
            if (!minted[uint256(i)])
                return i;
        }

        return -1;
    }

    function contractURI() public view returns (string memory) {
        return collectionMetadataURI;
    }

    function togglePaused() public onlyOwner {
        isPaused = !isPaused;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setCollectionURI(string memory _newURI) public onlyOwner {
        collectionMetadataURI = _newURI;
    }

    function setTokenBaseURI(string memory _newURI) public onlyOwner {
        tokenMetadataBaseURI = _newURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenMetadataBaseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}

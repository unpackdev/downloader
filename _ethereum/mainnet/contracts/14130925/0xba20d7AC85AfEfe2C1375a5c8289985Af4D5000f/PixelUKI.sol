// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721B.sol";
import "./Ownable.sol";
import "./Strings.sol";
/**
 * @title PixelUKIs contract
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

contract PixelUKI is Ownable, ERC721B {
    using Strings for uint256;

    string private _tokenBaseURI;

    uint256 public mintPrice;
    uint256 public maxMintAmountPerTX;
    uint256 public MAX_PIXELUKI_SUPPLY;

    bool public isSale;

    address private wallet1 = 0xB6EF1661d0bBD987AAab23bAa1752A236d8Ab785;
    address private wallet2 = 0x65eAFb001960aD7e021c26734a1423BB49D2e3Ab;

    constructor() ERC721B("PIXELUKI", "UKI") {
        MAX_PIXELUKI_SUPPLY = 10000;
        mintPrice = 0.04 ether;
        maxMintAmountPerTX = 25;
    }

    /**
     * Check if certain token id is exists.
     */
    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * Set mint price for a PixelUKI.
     */
    function setMintPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

    /**
     * Set maximum count to mint per one tx.
     */
    function setMaxToMintPerTX(uint256 _maxMintAmountPerTX) external onlyOwner {
        maxMintAmountPerTX = _maxMintAmountPerTX;
    }

    /*
    * Set base URI
    */
    function setBaseURI(string memory baseURI) external onlyOwner {
        _tokenBaseURI = baseURI;
    }

    /*
    * Set sale status
    */
    function setSaleStatus(bool _isSale) external onlyOwner {
        isSale = _isSale;
    }

    function tokenURI(uint256 tokenId) external view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    } 

    /**
     * Reserve PixelUKI by owner
     */
    function reserve(address to, uint256 count)
        external
        onlyOwner
    {
        require(to != address(0), "Invalid address to reserve.");

        uint256 supply = _owners.length;
        require(supply + count <= MAX_PIXELUKI_SUPPLY, "Reserve would exceed max supply");
        
        for (uint256 i = 0; i < count; i++) {
            _safeMint(to, supply++ );
        }
    }

    /**
    * Mint PixelUKI
    */
    function mint(uint256 count)
        external
        payable
    {
        require(isSale, "Sale must be active to mint");
        require(count <= maxMintAmountPerTX, "Invalid amount to mint per tx");
        require(mintPrice * count <= msg.value, "Ether value sent is not correct");
        
        uint256 supply = _owners.length;
        require(supply + count <= MAX_PIXELUKI_SUPPLY, "Purchase would exceed max supply");
        for(uint256 i = 0; i < count; i++) {
           _mint( msg.sender, supply++);
        }
    }

    function withdraw() external onlyOwner {
        payable(wallet1).transfer(address(this).balance * 93 / 100);
        payable(wallet2).transfer(address(this).balance);
    }
}
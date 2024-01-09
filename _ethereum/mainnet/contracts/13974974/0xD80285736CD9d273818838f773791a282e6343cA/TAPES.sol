/* SPDX-License-Identifier: MIT */
pragma solidity ^0.8.10;

import "./ERC721.sol";
import "./Counters.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Strings.sol";

/**
 * @title TAPES
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 */

 contract TAPES is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenSupply;
	 string private baseURI;
    bool public SaleIsActive = false;
    uint256 public SalePrice = 10000000000000000000;
    
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol){}

     function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
     }

     function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
     }

     function flipSaleState() external onlyOwner {
        SaleIsActive = !SaleIsActive;
     }
 
     function setSalePrice(uint256 newPrice) external onlyOwner {
         SalePrice = newPrice;
     }

     function adminMintTape(address to, uint256 TAPE_ID) external onlyOwner {
         require((TAPE_ID <= 100 && TAPE_ID > 0), "Nonexistent token");
         _tokenSupply.increment();
         _safeMint(to, TAPE_ID);
     }
     
     function tokensMinted() public view returns (uint256) {
         return _tokenSupply.current();
     }
		 
     function mintTape(uint256 TAPE_ID) external payable nonReentrant {
        require(SaleIsActive, "Sale isn't active yet");
        require((TAPE_ID <= 100 && TAPE_ID > 0), "Tape doesnt exist"); 
        require(!_exists(TAPE_ID), "That Tape has already been claimed");
        require(SalePrice == msg.value, "Eth value incorrect");
        _tokenSupply.increment();
        _safeMint(msg.sender, TAPE_ID);
     }

     function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
     }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require((tokenId <= 100 && tokenId > 0), "Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	 }
}
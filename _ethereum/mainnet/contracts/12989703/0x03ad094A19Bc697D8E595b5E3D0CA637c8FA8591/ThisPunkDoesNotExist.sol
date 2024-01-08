//SPDX-License-Identifier: Unlicensed & Copyrighteous

/*
 * 
 *   oooooooooo.    o8o                .        ooooo              .o.       ooooooooo.   oooooo     oooo       .o.       
 *   `888'   `Y8b   `"'              .o8        `888'             .888.      `888   `Y88.  `888.     .8'       .888.      
 *    888      888 oooo   .ooooo.  .o888oo       888             .8"888.      888   .d88'   `888.   .8'       .8"888.     
 *    888      888 `888  d88' `88b   888         888            .8' `888.     888ooo88P'     `888. .8'       .8' `888.    
 *    888      888  888  888ooo888   888         888           .88ooo8888.    888`88b.        `888.8'       .88ooo8888.   
 *    888     d88'  888  888    .o   888 .       888       o  .8'     `888.   888  `88b.       `888'       .8'     `888.  
 *   o888bood8P'   o888o `Y8bod8P'   "888"      o888ooooood8 o88o     o8888o o888o  o888o       `8'       o88o     o8888o 
 *  
 */ 
 
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ThisPunkDoesNotExist is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    uint256 private _maxSupply = 404;
    uint256 internal _sellerFee = 404;

    constructor() ERC721("This Punk Does Not Exist", "TPDNE") {}

    function safeMint(uint256 numberOfNfts, address to) public onlyOwner {
        require(totalSupply() < _maxSupply, "Minting would exceed max supply");
        require(numberOfNfts > 0, "Cannot mint 0 NFTs");
        
        for (uint i = 0; i < numberOfNfts; i++) {
        uint mintIndex = totalSupply();

        require(mintIndex < _maxSupply, "Exceeds max number of NFTs");

        _safeMint(to, mintIndex);
        _tokenIdCounter.increment();
        }
    }
    
    function _baseURI() internal pure override returns (string memory) {
        return "ipfs://bafybeiau2mwaa5h3kzgwwjt4pp4kespmmmvee256phcw4wfzy756e5aj6e/";
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function maxSupply() public view returns (uint256){
        return _maxSupply;
    }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    function getSellerFee() public view returns (uint256) {
        return _sellerFee;
    }
    
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
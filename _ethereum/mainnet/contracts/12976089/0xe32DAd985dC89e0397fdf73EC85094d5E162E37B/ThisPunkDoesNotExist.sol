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
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ThisPunkDoesNotExist is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    
    uint256 private _maxSupply = 404;
    uint256 internal _commission = 404; // basis points

    constructor() ERC721("This Punk Does Not Exist", "TPDNE") {}

    function safeMint(address to, string memory _tokenURI) public onlyOwner {
        require(totalSupply() < _maxSupply, "Minting would exceed max supply");
        uint256 id = _tokenIdCounter.current();
        _safeMint(to, id);
        _setTokenURI(id, _tokenURI);
        _tokenIdCounter.increment();
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

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    
    function getCommission() public view returns (uint256) {
        return _commission;
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
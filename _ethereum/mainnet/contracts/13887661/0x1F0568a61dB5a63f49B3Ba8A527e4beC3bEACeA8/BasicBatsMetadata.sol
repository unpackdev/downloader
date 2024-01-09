// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BasicBats.sol";


contract BasicBatsMetadata is BasicBats {

    using Strings for uint;
    
    string baseTokenUri;
    bool baseUriDefined = false;
    
    constructor(string memory baseURI) ERC721P("Basic Bats", "BBTS")  {
        setBaseURI(baseURI);
    }
    
    function _baseURI() internal view virtual returns (string memory) {
        return baseTokenUri;
    }

    /*
    *   The setBaseURI function with a possibility to freeze it !
    */
    function setBaseURI(string memory baseURI) public onlyOwner() {
        require(!baseUriDefined, "Base URI has already been set");
        
        baseTokenUri = baseURI;
        
    }
    
    function lockMetadatas() public onlyOwner() {
        baseUriDefined = true;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: Nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}
}

    
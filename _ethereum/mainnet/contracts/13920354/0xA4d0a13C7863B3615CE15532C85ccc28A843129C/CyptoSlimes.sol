// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721Full.sol";
// import "./ERC721.sol";
// import "./ERC721URIStorage.sol";
// import "./Counters.sol";
// import "./Ownable.sol"; 
 
contract CyptoSlimes is ERC721, ERC721URIStorage, Ownable  {        
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    constructor() ERC721("CryptoSlimes", "CSL")  { 
    }  

    function slimeBorn(address to, string memory uri) public onlyOwner returns (uint256) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        return tokenId;
    }

    // The following functions are overrides required by Solidity.
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

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }  

    function contractURI() public pure returns (string memory) {
        return "https://creatures-api.opensea.io/contract/opensea-creatures";
    }  
    
}


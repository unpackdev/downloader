/*
   ____     ____        __      _    _____     ____   ________        __    __    _____   _____   
  / ___)   / __ \      /  \    / )  / ___/    / ___) (___  ___)       ) )  ( (   (_   _) (  __ \  
 / /      / /  \ \    / /\ \  / /  ( (__     / /         ) )         ( (    ) )    | |    ) )_) ) 
( (      ( ()  () )   ) ) ) ) ) )   ) __)   ( (         ( (           \ \  / /     | |   (  ___/  
( (      ( ()  () )  ( ( ( ( ( (   ( (      ( (          ) )           \ \/ /      | |    ) )     
 \ \___   \ \__/ /   / /  \ \/ /    \ \___   \ \___     ( (      __     \  /      _| |__ ( (      
  \____)   \____/   (_/    \__/      \____\   \____)    /__\    (__)     \/      /_____( /__\     
                                                                                                  
   ____        __      _   _____      __      __       ____   ____     ____                       
  / __ \      /  \    / ) (_   _)     ) \    / (      /   /  / __ \   / __ \                      
 / /  \ \    / /\ \  / /    | |        \ \  / /      / /) ) ( (  ) ) ( (  ) )                     
( ()  () )   ) ) ) ) ) )    | |         \ \/ /      /_/( (  ( (  ) ) ( (  ) )                     
( ()  () )  ( ( ( ( ( (     | |   __     \  /           ) ) ( (  ) ) ( (  ) )                     
 \ \__/ /   / /  \ \/ /   __| |___) )     )(           ( (  ( (__) ) ( (__) )                     
  \____/   (_/    \__/    \________/     /__\          /__\  \____/   \____/                      
                                                                                                  
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract ConectVip is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // Base URI
    string private _baseURIextended;
    
    //Max Supply of tokens: 100 Conect.Vip (CONECT)
    uint public immutable maxSupply = 100;

    constructor() ERC721("Conect.Vip", "CONECT") {
        _tokenIdCounter.increment();
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIextended;
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        require(_tokenIdCounter.current() <= maxSupply, "Max Supply");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner() {
        _baseURIextended = baseURI_;
    }
        
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner() {
        _setTokenURI(tokenId, _tokenURI);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./Counters.sol";

/// @custom:security-contact alin.vana@gmail.com
contract Unrupt is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string unrbaseuri; 

    constructor() ERC721("Unrupt", "UNR") {

        unrbaseuri = "https://www.unrupt.com/unruptnft/prop/";
    
//Contract initiation mint


    safeBatchMintToOwner(100);


    }

    function _baseURI() internal view override returns (string memory) {
        return unrbaseuri;
    }

    function ChangeUnruptbaseURI(string memory newbaseuri) public onlyOwner {
        unrbaseuri = newbaseuri;

    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

        function safeBatchMintToOwner(uint256 batchsize) public onlyOwner {

 //       string memory localbaseuri = _baseURI();

        for (uint256 i = 1; i<=batchsize; i++) { 
         _tokenIdCounter.increment(); 
          uint256 tokenId = _tokenIdCounter.current();
        
            _safeMint(msg.sender, tokenId);
            _setTokenURI(tokenId, string(abi.encodePacked(Strings.toString(tokenId))));
        
            
            }


    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}

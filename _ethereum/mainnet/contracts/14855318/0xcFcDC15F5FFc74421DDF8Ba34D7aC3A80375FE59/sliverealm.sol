// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";

contract Sliverealm is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    
    bool not_transfered = true;
    
    string IpfsUri = "ipfs://QmUr9NxUyi2Pzjd3mP4HBaUw5VwaE7fAXoawp74NN2W7gW";


    constructor() ERC721("Sliverealm", "SLV") {}

    function safeMint(address to, uint256 tokenId, string memory uri)
        public
        onlyOwner
    {
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.
    
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721) {
        if(not_transfered) { 
            _setTokenURI(tokenId, IpfsUri);
            not_transfered = false;
        }
        _transfer(from, to, tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    function changeURI (string memory newTokenURI,uint256 tokenId) public onlyOwner{ 
        _setTokenURI(tokenId, newTokenURI);
    }
    
}
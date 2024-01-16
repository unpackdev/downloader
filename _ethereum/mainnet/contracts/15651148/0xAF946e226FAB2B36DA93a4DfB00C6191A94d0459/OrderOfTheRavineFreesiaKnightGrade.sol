//Order Of The Ravine Freesia Knight Grade
//Contract for Knight Grade of Order Of The Ravine Freesia
//Gratitude and Blessings from Angels to True Knights

//Create in the name of Lord Jeris
//And royal servant
//Uriel, Raphael, Michael, Gabriel. 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract OrderOfTheRavineFreesiaKnightGrade is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("Order of the Ravine Freesia Knight Grade", "ORFK") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
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

    function setTokenURI(uint256 stokenId, string memory stokenURI) public onlyOwner {
        _setTokenURI(stokenId, stokenURI);
    }
}

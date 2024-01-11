// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract LukaArt is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    // Contract-level metadata for OpenSea
    string public contractURI = "ipfs://bafkreickfal4kg6x25ssrdoyt2zgqprrfrk5xbaxredl4znibjqv2gpjna";

    Counters.Counter private _tokenIdCounter;

    // Signals frozen metadata to OpenSea; increased gas - decided not to use
    //event PermanentURI(string _value, uint256 indexed _id);

    constructor() ERC721("LukaArt", "LUK") {
        //_tokenIdCounter initialized to 1, since starting at 0 leads to higher gas cost for the first minter and I like 1-based
        _tokenIdCounter.increment();
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);

        // Signals frozen metadata to OpenSea; increased gas - decided not to use
        //emit PermanentURI(uri, tokenId);
    }

    // Update contract-level metadata for OpenSea
    function updateContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
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
}
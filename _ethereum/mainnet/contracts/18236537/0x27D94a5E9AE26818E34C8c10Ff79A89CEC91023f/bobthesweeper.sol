// contracts/DecentralisedNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract BobTheSweeper is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _baseURIExtended;

    constructor() ERC721("BobTheSweeper", "BTS") {
        _setBaseURI("ipfs://");
    }

    function _setBaseURI(string memory baseURI) private {
        _baseURIExtended = baseURI;
    }

    function updateBaseURI(string memory baseURI) public onlyOwner() {
        _baseURIExtended = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseURIExtended;
    }

    function mintNFT(address account, string memory metadataURI) public onlyOwner() {
        _tokenIds.increment();// First NFT id is 1
        uint256 tokenId = _tokenIds.current();
        _safeMint(account, tokenId);
        _setTokenURI(tokenId, metadataURI);
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ReentrancyGuard.sol";
import "./Counters.sol";
import "./Ownable.sol";

contract TheSagesRantCollectibles is ERC721Enumerable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    string public PROVENANCE_HASH = "";
    string baseUri = "https://ownly.io/nft/the-sages-rant-collectibles/api/";

    constructor() ERC721("TheSagesRantCollectibles", "THESAGESRANTCOLLECTIBLES") {}

    function mintMultiple(address _address, uint _quantity) public onlyOwner {
        for(uint i = 0; i < _quantity; i++) {
            tokenIds.increment();
            uint tokenId = tokenIds.current();

            _mint(_address, tokenId);
        }
    }

    function _baseURI() internal view override returns (string memory) {
        return baseUri;
    }

    function setBaseUri(string memory _baseUri) public onlyOwner {
        baseUri = _baseUri;
    }

    function setProvenanceHash(string memory _provenanceHash) external onlyOwner {
        PROVENANCE_HASH = _provenanceHash;
    }
}
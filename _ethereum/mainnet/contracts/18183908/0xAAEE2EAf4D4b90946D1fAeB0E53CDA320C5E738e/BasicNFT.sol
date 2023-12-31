// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

// BasicNFT:
// OpenZeppelin Mintable (+AutoIncrementIDs) & Enumerable
// + multiMint
// + setBaseURI
// + setMaxSupply
contract BasicNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    string public BASE_URI;
    uint public MAX_SUPPLY;

    struct Mint {
        address to;
        uint count;
    }

    constructor(uint _supply) ERC721("GeometricShapes", "GSP") {
        MAX_SUPPLY = _supply;
        _tokenIdCounter.increment(); // init 1
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        BASE_URI = _uri;
    }

    function setMaxSupply(uint _supply) public onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function multiMint(Mint[] memory mints) public onlyOwner {
        for (uint i = 0; i < mints.length; i++) {
            for (uint j = 0; j < mints[i].count; j++) {
                safeMint(mints[i].to);
            }
        }
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
    internal
    override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
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

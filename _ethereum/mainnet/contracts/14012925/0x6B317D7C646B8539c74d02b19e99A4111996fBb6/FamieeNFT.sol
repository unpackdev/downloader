//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./console.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract FamieeNFT is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address private _owner;
    constructor(string memory tokenName, string memory symbol, address newOwner) ERC721(tokenName, symbol) {
        _owner = newOwner;
    }

    function mintToken(address owner, string memory metadataURI)
    public
    returns (uint256)
    {
        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _safeMint(owner, id);
        _setTokenURI(id, metadataURI);

        return id;
    }

    function owner()
    public
    view
    returns (address)
    {
        return _owner;
    }

}
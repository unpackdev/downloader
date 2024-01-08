// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./Ownable.sol";



contract Asset is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721("EMP", "EMP") {
    }

    function mint(address buyer, string memory tokenURI) public onlyOwner returns (uint256)
    {
        _tokenIds.increment();

        uint256 newItemId = _tokenIds.current();
        _mint(buyer, newItemId);
        _setTokenURI(newItemId, tokenURI);

        emit TokenMinted(newItemId);

        return newItemId;
    }

    event TokenMinted(uint256 tokenId);

}
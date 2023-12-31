// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract NuconomistLabs is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string private _baseTokenURI = "https://nuconomist.com/wp-json/token/v1/erc721/";

    constructor() ERC721("NuconomistLabs", "NLABS") {}

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function mint(address to) public onlyOwner {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(to, newTokenId);
    }

    // Optional: Function to update the base URI
    function setBaseURI(string memory newBaseTokenURI) external onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }
}
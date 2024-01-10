// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Token
 * Tokens - a contract for my non-fungible tokens.
 */
contract Token is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        ERC721Tradable( 'NoWarInUkraineFund', 'NWIUF', _proxyRegistryAddress)
    {}

    function baseTokenURI() public view returns (string memory) {
        string memory base = baseURI();
        return base;
    }

    function contractURI() public view returns (string memory) {
        string memory base = baseURI();
        return base;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

}

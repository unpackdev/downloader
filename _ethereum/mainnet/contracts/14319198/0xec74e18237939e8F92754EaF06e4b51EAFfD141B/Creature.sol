// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";

/**
 * @title Creature
 * Creature - a contract for my non-fungible creatures.
 */
contract Creature is ERC721Tradable {
    // metadata URI
    string private _baseTokenURI;
    string private _contractURI;

    constructor(
        address _proxyRegistryAddress,
        string memory _initBaseTokenURI,
        string memory _initContractURI
    ) ERC721Tradable("MyNameIsZK", "MNZK", _proxyRegistryAddress) {
        setBaseTokenURI(_initBaseTokenURI);
        setContractURI(_initContractURI);
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    function baseTokenURI() override public view returns (string memory) {
        return _baseTokenURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }
}
